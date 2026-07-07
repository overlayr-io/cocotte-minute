import 'package:cocotte_minute/features/recipe_player/domain/playable_step.dart';
import 'package:cocotte_minute/features/recipe_player/domain/recipe_timer.dart';
import 'package:cocotte_minute/features/recipe_player/domain/resume_state.dart';
import 'package:cocotte_minute/features/recipes/domain/recipe.dart';
import 'package:equatable/equatable.dart';

/// Phase du mode pas-à-pas : lancement (10a), cuisson active (10b/10d-10j/étape
/// active + sommaire), ou fin (10g). Un seul champ plutôt que des booléens
/// flottants, cf. `mobile/CLAUDE.md`.
enum PlayerPhase { launch, playing, finished }

/// Avertissement de conflit inter-recettes : une autre session est en cours
/// pour une recette différente. Affiché avant de laisser l'utilisateur
/// écraser cet état de reprise (décision produit validée : avertir avant
/// d'écraser plutôt qu'écraser silencieusement).
class SwitchRecipeWarning extends Equatable {
  const SwitchRecipeWarning({required this.recipeName, required this.stepIndex});

  final String recipeName;

  /// Index 0-based de l'étape où l'autre session s'était arrêtée.
  final int stepIndex;

  @override
  List<Object?> get props => [recipeName, stepIndex];
}

sealed class RecipePlayerState extends Equatable {
  const RecipePlayerState();

  @override
  List<Object?> get props => const [];
}

class RecipePlayerLoading extends RecipePlayerState {
  const RecipePlayerLoading();
}

class RecipePlayerError extends RecipePlayerState {
  const RecipePlayerError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class RecipePlayerLoaded extends RecipePlayerState {
  const RecipePlayerLoaded({
    required this.detail,
    required this.steps,
    required this.selectedServings,
    required this.phase,
    this.currentIndex = 0,
    this.timers = const [],
    this.sessionStartedAt,
    this.pendingResume,
    this.pendingSwitchWarning,
  });

  final RecipeDetail detail;

  /// Étapes aplaties une seule fois au chargement (cf. [flattenRecipeSteps]).
  final List<PlayableStep> steps;

  final int selectedServings;
  final PlayerPhase phase;
  final int currentIndex;

  /// Jamais un singleton, même si un seul est `running` à la fois en v1.
  final List<RecipeTimer> timers;

  final DateTime? sessionStartedAt;

  /// Non-null si un état de reprise existe pour CETTE recette (même
  /// `recipeId`) — déclenche le dialog 10h.
  final ResumeState? pendingResume;

  /// Non-null si un état de reprise existe pour une AUTRE recette — déclenche
  /// le dialog d'avertissement avant de l'écraser.
  final SwitchRecipeWarning? pendingSwitchWarning;

  int get totalSteps => steps.length;
  PlayableStep get currentStep => steps[currentIndex];
  bool get isFirstStep => currentIndex == 0;
  bool get isLastStep => currentIndex == steps.length - 1;

  RecipeTimer? get runningTimer {
    for (final t in timers) {
      if (t.status == TimerStatus.running) return t;
    }
    return null;
  }

  RecipePlayerLoaded copyWith({
    RecipeDetail? detail,
    List<PlayableStep>? steps,
    int? selectedServings,
    PlayerPhase? phase,
    int? currentIndex,
    List<RecipeTimer>? timers,
    DateTime? sessionStartedAt,
    ResumeState? pendingResume,
    bool clearPendingResume = false,
    SwitchRecipeWarning? pendingSwitchWarning,
    bool clearPendingSwitchWarning = false,
  }) {
    return RecipePlayerLoaded(
      detail: detail ?? this.detail,
      steps: steps ?? this.steps,
      selectedServings: selectedServings ?? this.selectedServings,
      phase: phase ?? this.phase,
      currentIndex: currentIndex ?? this.currentIndex,
      timers: timers ?? this.timers,
      sessionStartedAt: sessionStartedAt ?? this.sessionStartedAt,
      pendingResume:
          clearPendingResume ? null : (pendingResume ?? this.pendingResume),
      pendingSwitchWarning: clearPendingSwitchWarning
          ? null
          : (pendingSwitchWarning ?? this.pendingSwitchWarning),
    );
  }

  @override
  List<Object?> get props => [
        detail,
        steps,
        selectedServings,
        phase,
        currentIndex,
        timers,
        sessionStartedAt,
        pendingResume,
        pendingSwitchWarning,
      ];
}
