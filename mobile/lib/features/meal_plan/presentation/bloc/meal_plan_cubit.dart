import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/premium/premium_limit_error.dart';
import '../../../recipes/data/recipes_repository.dart';
import '../../../recipes/domain/recipe.dart';
import '../../data/meal_plan_repository.dart';
import '../../data/meal_plan_tray_store.dart';
import '../../domain/meal_plan_entry.dart';
import '../../domain/meal_plan_week.dart';

part 'meal_plan_state.dart';

/// Planning de repas (onglet Planning). Navigation dans la fenêtre de
/// rétention T-1 → T+2, entrées par semaine, bandeau « À planifier » local,
/// mode sélection vers la liste de courses.
class MealPlanCubit extends Cubit<MealPlanState> {
  MealPlanCubit({
    required MealPlanRepository repository,
    required RecipesRepository recipesRepository,
    required MealPlanTrayStore trayStore,
  }) : _repository = repository,
       _recipesRepository = recipesRepository,
       _trayStore = trayStore,
       super(MealPlanState(weeks: MealPlanWeek.retentionWindow()));

  final MealPlanRepository _repository;
  final RecipesRepository _recipesRepository;
  final MealPlanTrayStore _trayStore;

  /// Dernière entrée retirée, restaurable via la snackbar « Annuler ».
  MealPlanEntry? _pendingUndo;

  MealPlanWeek get _week => state.weeks[state.weekIndex];

  Future<void> load() async {
    emit(state.copyWith(status: MealPlanStatus.loading));
    try {
      final entries = await _repository.fetchWeek(_week.weekStartKey);
      emit(
        state.copyWith(
          status: MealPlanStatus.ready,
          entriesByWeek: {...state.entriesByWeek, _week.weekStartKey: entries},
        ),
      );
    } on MealPlanRepositoryException catch (e) {
      emit(state.copyWith(status: MealPlanStatus.error, loadError: e.message));
      return;
    }
    await _loadTray();
  }

  Future<void> refreshVisibleWeek() => _fetchWeek(force: true);

  Future<void> selectWeek(int index) async {
    if (index < 0 || index >= state.weeks.length || index == state.weekIndex) {
      return;
    }
    emit(state.copyWith(weekIndex: index));
    if (!state.entriesByWeek.containsKey(state.weeks[index].weekStartKey)) {
      await _fetchWeek();
    }
  }

  void setLayout(PlanningLayout layout) => emit(state.copyWith(layout: layout));

  // --- Entrées -------------------------------------------------------------

  Future<void> addRecipe({
    required String day,
    required MealSlot slot,
    required String recipeId,
  }) => _add(day: day, slot: slot, type: MealEntryType.recipe, recipeId: recipeId);

  Future<void> addEatingOut({required String day, required MealSlot slot}) =>
      _add(day: day, slot: slot, type: MealEntryType.eatingOut);

  Future<void> addNote({
    required String day,
    required MealSlot slot,
    required String text,
  }) => _add(day: day, slot: slot, type: MealEntryType.note, noteText: text);

  Future<void> _add({
    required String day,
    required MealSlot slot,
    required MealEntryType type,
    String? recipeId,
    String? noteText,
  }) async {
    try {
      final entry = await _repository.addEntry(
        day: day,
        slot: slot,
        type: type,
        recipeId: recipeId,
        noteText: noteText,
      );
      final key = _weekKeyOf(day);
      final entries = [...?state.entriesByWeek[key], entry];
      emit(
        state.copyWith(entriesByWeek: {...state.entriesByWeek, key: entries}),
      );
    } on MealPlanRepositoryException catch (e) {
      _emitFailure(e);
    }
  }

  /// Retire une entrée et arme la snackbar « Annuler ».
  Future<void> removeEntry(MealPlanEntry entry) async {
    try {
      await _repository.removeEntry(id: entry.id, day: entry.day);
      _pendingUndo = entry;
      final key = _weekKeyOf(entry.day);
      final entries = [...?state.entriesByWeek[key]]
        ..removeWhere((e) => e.id == entry.id);
      emit(
        state.copyWith(
          entriesByWeek: {...state.entriesByWeek, key: entries},
          removedEntry: entry,
        ),
      );
    } on MealPlanRepositoryException catch (e) {
      _emitFailure(e);
    }
  }

  /// Restaure la dernière entrée retirée (action « Annuler » de la snackbar).
  Future<void> undoRemove() async {
    final entry = _pendingUndo;
    if (entry == null) return;
    _pendingUndo = null;
    await _add(
      day: entry.day,
      slot: entry.slot,
      type: entry.type,
      recipeId: entry.recipe?.id,
      noteText: entry.noteText,
    );
  }

  // --- Bandeau « À planifier » ----------------------------------------------

  Future<void> setTray(List<String> recipeIds) async {
    await _trayStore.write(recipeIds);
    await _loadTray();
  }

  Future<void> _loadTray() async {
    try {
      final ids = await _trayStore.read();
      if (ids.isEmpty) {
        emit(state.copyWith(tray: const []));
        return;
      }
      final recipes = await _recipesRepository.fetchMine();
      final byId = {for (final r in recipes) r.id: r};
      final tray = [for (final id in ids) if (byId[id] != null) byId[id]!];
      // Purge silencieuse des recettes supprimées depuis.
      if (tray.length != ids.length) {
        await _trayStore.write([for (final r in tray) r.id]);
      }
      emit(state.copyWith(tray: tray));
    } on Object {
      // Bandeau non bloquant : en cas d'échec réseau on le laisse vide.
      emit(state.copyWith(tray: const []));
    }
  }

  // --- Mode sélection (vers la liste de courses) ----------------------------

  void enterSelectMode() =>
      emit(state.copyWith(selectMode: true, selectedSlots: const {}));

  void exitSelectMode() =>
      emit(state.copyWith(selectMode: false, selectedSlots: const {}));

  void toggleSlotSelected(String slotKey) {
    final selected = {...state.selectedSlots};
    if (!selected.add(slotKey)) selected.remove(slotKey);
    emit(state.copyWith(selectedSlots: selected));
  }

  /// Recettes des créneaux cochés (id → parts), dédupliquées pour la
  /// génération de liste de courses.
  Map<String, RecipeSummary> selectedRecipes() {
    final result = <String, RecipeSummary>{};
    for (final entry in state.visibleEntries) {
      final recipe = entry.recipe;
      if (recipe == null) continue;
      if (!state.selectedSlots.contains('${entry.day}|${entry.slot.wire}')) {
        continue;
      }
      result[recipe.id] = recipe;
    }
    return result;
  }

  // --- Transients -----------------------------------------------------------

  /// Consomme les signaux one-shot (paywall, erreur, snackbar retrait).
  void acknowledge() => emit(state.clearTransients());

  Future<void> _fetchWeek({bool force = false}) async {
    final key = _week.weekStartKey;
    emit(state.copyWith(weekLoading: true));
    try {
      final entries = await _repository.fetchWeek(key, forceRefresh: force);
      emit(
        state.copyWith(
          weekLoading: false,
          entriesByWeek: {...state.entriesByWeek, key: entries},
        ),
      );
    } on MealPlanRepositoryException catch (e) {
      emit(state.copyWith(weekLoading: false));
      _emitFailure(e);
    }
  }

  void _emitFailure(MealPlanRepositoryException e) {
    if (e.premiumLimit != null) {
      emit(state.copyWith(premiumLimit: e.premiumLimit));
    } else {
      emit(state.copyWith(actionError: e.message));
    }
  }

  String _weekKeyOf(String day) {
    final date = DateTime.parse(day);
    return dayKey(mondayOfWeek(date));
  }
}
