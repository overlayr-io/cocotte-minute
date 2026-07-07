import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:cocotte_minute/core/notifications/local_notifications_service.dart';
import 'package:cocotte_minute/features/recipe_player/data/recipe_player_storage.dart';
import 'package:cocotte_minute/features/recipe_player/domain/playable_step.dart';
import 'package:cocotte_minute/features/recipe_player/domain/recipe_timer.dart';
import 'package:cocotte_minute/features/recipe_player/domain/resume_state.dart';
import 'package:cocotte_minute/features/recipe_player/presentation/bloc/recipe_player_state.dart';
import 'package:cocotte_minute/features/recipes/data/recipes_repository.dart';

export 'package:cocotte_minute/features/recipe_player/presentation/bloc/recipe_player_state.dart';

/// Pilote le mode pas-à-pas (mode cuisine) : chargement unique de la recette,
/// navigation entre étapes, minuteurs, reprise après interruption.
///
/// 100% local après [load] — aucun autre appel réseau pendant l'exécution,
/// cf. `docs/features/step-by-step.md`.
class RecipePlayerCubit extends Cubit<RecipePlayerState> {
  RecipePlayerCubit({
    required RecipesRepository repository,
    required RecipePlayerStorage storage,
    required LocalNotificationsService notifications,
    required this.recipeId,
  })  : _repository = repository,
        _storage = storage,
        _notifications = notifications,
        super(const RecipePlayerLoading());

  final RecipesRepository _repository;
  final RecipePlayerStorage _storage;
  final LocalNotificationsService _notifications;
  final String recipeId;

  Timer? _ticker;

  Future<void> load() async {
    emit(const RecipePlayerLoading());
    try {
      final detail = await _repository.fetchDetail(recipeId);
      final steps = flattenRecipeSteps(detail.steps);
      final resume = await _storage.read();

      if (resume != null && resume.recipeId != recipeId) {
        emit(
          RecipePlayerLoaded(
            detail: detail,
            steps: steps,
            selectedServings: detail.summary.servings,
            phase: PlayerPhase.launch,
            pendingSwitchWarning: SwitchRecipeWarning(
              recipeName: resume.recipeName,
              stepIndex: resume.currentIndex,
            ),
          ),
        );
        return;
      }

      emit(
        RecipePlayerLoaded(
          detail: detail,
          steps: steps,
          selectedServings: detail.summary.servings,
          phase: PlayerPhase.launch,
          pendingResume: resume,
        ),
      );
    } on RecipesRepositoryException catch (e) {
      emit(RecipePlayerError(e.message));
    }
  }

  // --- lancement (10a) ------------------------------------------------

  void setServings(int value) {
    final current = state;
    if (current is! RecipePlayerLoaded || value < 1) return;
    emit(current.copyWith(selectedServings: value));
  }

  /// Une autre recette a une session en cours : l'utilisateur confirme vouloir
  /// l'abandonner pour démarrer celle-ci.
  Future<void> confirmSwitchRecipe() async {
    final current = state;
    if (current is! RecipePlayerLoaded) return;
    await _storage.clear();
    emit(current.copyWith(clearPendingSwitchWarning: true));
  }

  /// « Recommencer » sur le dialog de reprise (10h) : reste sur l'écran de
  /// lancement, l'ancien état sera écrasé dès le premier changement d'étape.
  void dismissResume() {
    final current = state;
    if (current is! RecipePlayerLoaded) return;
    emit(current.copyWith(clearPendingResume: true));
  }

  /// « Reprendre à l'étape N » sur le dialog de reprise (10h) : saute
  /// directement en cuisson active à l'étape et aux minuteurs sauvegardés.
  Future<void> resumeSession() async {
    final current = state;
    final resume = current is RecipePlayerLoaded ? current.pendingResume : null;
    if (current is! RecipePlayerLoaded || resume == null) return;

    final now = DateTime.now();
    final timers = resume.timers.map((p) => _fromPersisted(p, now)).toList();

    emit(
      current.copyWith(
        phase: PlayerPhase.playing,
        currentIndex: resume.currentIndex.clamp(0, current.steps.length - 1),
        selectedServings: resume.selectedServings,
        sessionStartedAt: DateTime.fromMillisecondsSinceEpoch(
          resume.sessionStartedAtMillis,
        ),
        timers: timers,
        clearPendingResume: true,
      ),
    );
    if (timers.any((t) => t.status == TimerStatus.running)) {
      _startTickerIfNeeded();
    }
    await _persist();
  }

  Future<void> startCooking() async {
    final current = state;
    if (current is! RecipePlayerLoaded || current.phase != PlayerPhase.launch) {
      return;
    }
    emit(
      current.copyWith(
        phase: PlayerPhase.playing,
        currentIndex: 0,
        sessionStartedAt: DateTime.now(),
        clearPendingResume: true,
      ),
    );
    await _persist();
  }

  // --- navigation -------------------------------------------------------

  void nextStep() {
    final current = state;
    if (current is! RecipePlayerLoaded || current.phase != PlayerPhase.playing) {
      return;
    }
    if (current.isLastStep) {
      unawaited(finishSession());
      return;
    }
    emit(current.copyWith(currentIndex: current.currentIndex + 1));
    unawaited(_persist());
  }

  void previousStep() {
    final current = state;
    if (current is! RecipePlayerLoaded ||
        current.phase != PlayerPhase.playing ||
        current.isFirstStep) {
      return;
    }
    emit(current.copyWith(currentIndex: current.currentIndex - 1));
    unawaited(_persist());
  }

  void jumpToStep(int index) {
    final current = state;
    if (current is! RecipePlayerLoaded || current.phase != PlayerPhase.playing) {
      return;
    }
    if (index < 0 || index >= current.steps.length) return;
    emit(current.copyWith(currentIndex: index));
    unawaited(_persist());
  }

  // --- minuteurs ----------------------------------------------------------

  /// Démarre un minuteur pour [stepId]. Un seul minuteur peut être `running`
  /// à la fois : tout minuteur déjà actif est automatiquement mis en pause
  /// (jamais supprimé — la structure reste une liste, cf. cahier des charges).
  Future<void> startTimer(
    String stepId,
    Duration duration, {
    String? label,
  }) async {
    final current = state;
    if (current is! RecipePlayerLoaded) return;

    await _notifications.requestPermissionIfNeeded();

    final now = DateTime.now();
    final endTime = now.add(duration);
    final newTimer = RecipeTimer(
      id: '$stepId-${now.microsecondsSinceEpoch}',
      stepId: stepId,
      totalDuration: duration,
      status: TimerStatus.running,
      label: label,
      remaining: duration,
      endTime: endTime,
    );

    final others = <RecipeTimer>[];
    for (final t in current.timers) {
      if (t.status == TimerStatus.running) {
        await _notifications.cancel(_notificationId(t.id));
        final remaining = t.endTime != null
            ? t.endTime!.difference(now)
            : t.remaining;
        others.add(
          t.copyWith(
            status: TimerStatus.paused,
            remaining: remaining,
            clearEndTime: true,
          ),
        );
      } else {
        others.add(t);
      }
    }

    emit(current.copyWith(timers: [...others, newTimer]));
    _startTickerIfNeeded();
    await _notifications.schedule(
      id: _notificationId(newTimer.id),
      title: 'Minuteur terminé',
      body: label == null || label.isEmpty
          ? 'Ton minuteur est terminé.'
          : '$label — minuteur terminé.',
      fireAt: endTime,
    );
    await _persist();
  }

  Future<void> pauseTimer(String timerId) async {
    final current = state;
    if (current is! RecipePlayerLoaded) return;
    final now = DateTime.now();
    final updated = current.timers.map((t) {
      if (t.id != timerId || t.status != TimerStatus.running) return t;
      final remaining = t.endTime != null ? t.endTime!.difference(now) : t.remaining;
      return t.copyWith(
        status: TimerStatus.paused,
        remaining: remaining,
        clearEndTime: true,
      );
    }).toList();
    emit(current.copyWith(timers: updated));
    await _notifications.cancel(_notificationId(timerId));
    await _persist();
  }

  Future<void> resetTimer(String timerId) async {
    final current = state;
    if (current is! RecipePlayerLoaded) return;
    final updated = current.timers.map((t) {
      if (t.id != timerId) return t;
      return t.copyWith(
        status: TimerStatus.idle,
        remaining: t.totalDuration,
        clearEndTime: true,
      );
    }).toList();
    emit(current.copyWith(timers: updated));
    await _notifications.cancel(_notificationId(timerId));
    await _persist();
  }

  Future<void> cancelTimer(String timerId) async {
    final current = state;
    if (current is! RecipePlayerLoaded) return;
    final updated = current.timers.where((t) => t.id != timerId).toList();
    emit(current.copyWith(timers: updated));
    await _notifications.cancel(_notificationId(timerId));
    await _persist();
  }

  void _startTickerIfNeeded() {
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final current = state;
    if (current is! RecipePlayerLoaded) return;
    final now = DateTime.now();
    var statusChanged = false;
    final updated = current.timers.map((t) {
      if (t.status != TimerStatus.running || t.endTime == null) return t;
      final remaining = t.endTime!.difference(now);
      if (remaining <= Duration.zero) {
        statusChanged = true;
        return t.copyWith(
          status: TimerStatus.done,
          remaining: Duration.zero,
          clearEndTime: true,
        );
      }
      return t.copyWith(remaining: remaining);
    }).toList();

    emit(current.copyWith(timers: updated));
    if (statusChanged) {
      unawaited(_persist());
    }
  }

  // --- fin / sortie ---------------------------------------------------

  Future<void> finishSession() async {
    final current = state;
    if (current is! RecipePlayerLoaded) return;
    emit(current.copyWith(phase: PlayerPhase.finished));
    await _storage.clear();
  }

  /// Confirmation de quitter (10i) : annule les minuteurs programmés et
  /// efface l'état de reprise (la page se referme juste après, côté widget).
  Future<void> quitSession() async {
    final current = state;
    if (current is! RecipePlayerLoaded) return;
    for (final t in current.timers) {
      await _notifications.cancel(_notificationId(t.id));
    }
    await _storage.clear();
  }

  // --- persistance ------------------------------------------------------

  Future<void> _persist() async {
    final current = state;
    if (current is! RecipePlayerLoaded || current.phase != PlayerPhase.playing) {
      return;
    }
    final startedAt = current.sessionStartedAt ?? DateTime.now();
    await _storage.write(
      ResumeState(
        recipeId: recipeId,
        recipeName: current.detail.name,
        selectedServings: current.selectedServings,
        currentIndex: current.currentIndex,
        sessionStartedAtMillis: startedAt.millisecondsSinceEpoch,
        timers: current.timers.map(_toPersisted).toList(),
      ),
    );
  }

  static PersistedTimer _toPersisted(RecipeTimer t) => PersistedTimer(
        id: t.id,
        stepId: t.stepId,
        totalDurationSeconds: t.totalDuration.inSeconds,
        status: t.status,
        label: t.label,
        endTimeMillis: t.endTime?.millisecondsSinceEpoch,
      );

  static RecipeTimer _fromPersisted(PersistedTimer p, DateTime now) {
    final total = Duration(seconds: p.totalDurationSeconds);
    if (p.status == TimerStatus.running && p.endTimeMillis != null) {
      final endTime = DateTime.fromMillisecondsSinceEpoch(p.endTimeMillis!);
      final remaining = endTime.difference(now);
      if (remaining <= Duration.zero) {
        return RecipeTimer(
          id: p.id,
          stepId: p.stepId,
          totalDuration: total,
          status: TimerStatus.done,
          label: p.label,
          remaining: Duration.zero,
        );
      }
      return RecipeTimer(
        id: p.id,
        stepId: p.stepId,
        totalDuration: total,
        status: TimerStatus.running,
        label: p.label,
        remaining: remaining,
        endTime: endTime,
      );
    }
    return RecipeTimer(
      id: p.id,
      stepId: p.stepId,
      totalDuration: total,
      status: p.status,
      label: p.label,
    );
  }

  static int _notificationId(String timerId) => timerId.hashCode & 0x7fffffff;

  @override
  Future<void> close() {
    _ticker?.cancel();
    return super.close();
  }
}
