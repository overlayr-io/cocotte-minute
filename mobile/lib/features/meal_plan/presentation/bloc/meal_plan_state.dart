part of 'meal_plan_cubit.dart';

enum MealPlanStatus { initial, loading, ready, error }

/// Mise en page du calendrier : grille 7×3 (1a) ou blocs par jour (1b).
enum PlanningLayout { grid, blocks }

class MealPlanState extends Equatable {
  const MealPlanState({
    required this.weeks,
    this.status = MealPlanStatus.initial,
    this.weekIndex = 1, // T (les semaines vont de T-1 à T+2).
    this.layout = PlanningLayout.grid,
    this.weekLoading = false,
    this.entriesByWeek = const {},
    this.tray = const [],
    this.selectMode = false,
    this.selectedSlots = const {},
    this.loadError,
    this.actionError,
    this.premiumLimit,
    this.removedEntry,
  });

  final List<MealPlanWeek> weeks;
  final MealPlanStatus status;
  final int weekIndex;
  final PlanningLayout layout;
  final bool weekLoading;

  /// Entrées chargées, par `weekStart` (`YYYY-MM-DD`).
  final Map<String, List<MealPlanEntry>> entriesByWeek;

  /// Bandeau « À planifier » hydraté (ordre = ordre du store local).
  final List<RecipeSummary> tray;

  final bool selectMode;

  /// Créneaux cochés en mode sélection (clés `day|slot`).
  final Set<String> selectedSlots;

  /// Erreur bloquante du premier chargement (page d'erreur + retry).
  final String? loadError;

  // Signaux one-shot consommés par le listener de la page ([MealPlanCubit.acknowledge]).
  final String? actionError;
  final PremiumLimitError? premiumLimit;
  final MealPlanEntry? removedEntry;

  MealPlanWeek get visibleWeek => weeks[weekIndex];

  List<MealPlanEntry> get visibleEntries =>
      entriesByWeek[visibleWeek.weekStartKey] ?? const [];

  /// Entrées d'un créneau (`day` en `YYYY-MM-DD`), triées par position.
  List<MealPlanEntry> slotEntries(String day, MealSlot slot) {
    final entries = visibleEntries
        .where((e) => e.day == day && e.slot == slot)
        .toList();
    entries.sort((a, b) => a.position.compareTo(b.position));
    return entries;
  }

  /// Nombre de recettes des créneaux cochés (libellé du bouton flottant 4a).
  int get selectedRecipeCount => visibleEntries
      .where(
        (e) =>
            e.recipe != null &&
            selectedSlots.contains('${e.day}|${e.slot.wire}'),
      )
      .length;

  MealPlanState copyWith({
    MealPlanStatus? status,
    int? weekIndex,
    PlanningLayout? layout,
    bool? weekLoading,
    Map<String, List<MealPlanEntry>>? entriesByWeek,
    List<RecipeSummary>? tray,
    bool? selectMode,
    Set<String>? selectedSlots,
    String? loadError,
    String? actionError,
    PremiumLimitError? premiumLimit,
    MealPlanEntry? removedEntry,
  }) {
    return MealPlanState(
      weeks: weeks,
      status: status ?? this.status,
      weekIndex: weekIndex ?? this.weekIndex,
      layout: layout ?? this.layout,
      weekLoading: weekLoading ?? this.weekLoading,
      entriesByWeek: entriesByWeek ?? this.entriesByWeek,
      tray: tray ?? this.tray,
      selectMode: selectMode ?? this.selectMode,
      selectedSlots: selectedSlots ?? this.selectedSlots,
      loadError: loadError ?? this.loadError,
      actionError: actionError ?? this.actionError,
      premiumLimit: premiumLimit ?? this.premiumLimit,
      removedEntry: removedEntry ?? this.removedEntry,
    );
  }

  MealPlanState clearTransients() {
    return MealPlanState(
      weeks: weeks,
      status: status,
      weekIndex: weekIndex,
      layout: layout,
      weekLoading: weekLoading,
      entriesByWeek: entriesByWeek,
      tray: tray,
      selectMode: selectMode,
      selectedSlots: selectedSlots,
      loadError: loadError,
    );
  }

  @override
  List<Object?> get props => [
    weeks,
    status,
    weekIndex,
    layout,
    weekLoading,
    entriesByWeek,
    tray,
    selectMode,
    selectedSlots,
    loadError,
    actionError,
    premiumLimit,
    removedEntry,
  ];
}
