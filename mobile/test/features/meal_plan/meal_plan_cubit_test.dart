import 'package:cocotte_minute/core/premium/premium_limit_error.dart';
import 'package:cocotte_minute/features/meal_plan/data/meal_plan_repository.dart';
import 'package:cocotte_minute/features/meal_plan/data/meal_plan_tray_store.dart';
import 'package:cocotte_minute/features/meal_plan/domain/meal_plan_entry.dart';
import 'package:cocotte_minute/features/meal_plan/domain/meal_plan_week.dart';
import 'package:cocotte_minute/features/meal_plan/presentation/bloc/meal_plan_cubit.dart';
import 'package:cocotte_minute/features/recipes/data/recipes_repository.dart';
import 'package:cocotte_minute/features/recipes/domain/recipe.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockMealPlanRepository extends Mock implements MealPlanRepository {}

class _MockRecipesRepository extends Mock implements RecipesRepository {}

class _MockTrayStore extends Mock implements MealPlanTrayStore {}

void main() {
  setUpAll(() {
    registerFallbackValue(MealSlot.midi);
    registerFallbackValue(MealEntryType.recipe);
  });

  late _MockMealPlanRepository repository;
  late _MockRecipesRepository recipes;
  late _MockTrayStore trayStore;

  // Jours de la semaine courante T et de la suivante (le cubit travaille sur
  // la fenêtre autour d'aujourd'hui).
  final tMonday = mondayOfWeek(DateTime.now());
  final tDay = dayKey(tMonday);
  final t1Day = dayKey(tMonday.add(const Duration(days: 7)));

  MealPlanEntry entry({
    String id = 'e1',
    String? day,
    MealSlot slot = MealSlot.midi,
    MealEntryType type = MealEntryType.recipe,
    int position = 0,
  }) => MealPlanEntry(
    id: id,
    day: day ?? tDay,
    slot: slot,
    type: type,
    recipe: type == MealEntryType.recipe
        ? const RecipeSummary(id: 'r1', name: 'Bolo', servings: 2)
        : null,
    noteText: type == MealEntryType.note ? 'Pizza' : null,
    position: position,
  );

  MealPlanCubit build() => MealPlanCubit(
    repository: repository,
    recipesRepository: recipes,
    trayStore: trayStore,
  );

  setUp(() {
    repository = _MockMealPlanRepository();
    recipes = _MockRecipesRepository();
    trayStore = _MockTrayStore();
    when(() => trayStore.read()).thenAnswer((_) async => const []);
    when(
      () => repository.fetchWeek(any(), forceRefresh: any(named: 'forceRefresh')),
    ).thenAnswer((_) async => const []);
  });

  test('load charge la semaine courante (index 1 = T) et le bandeau', () async {
    when(
      () => repository.fetchWeek(tDay, forceRefresh: any(named: 'forceRefresh')),
    ).thenAnswer((_) async => [entry()]);
    final cubit = build();
    await cubit.load();

    expect(cubit.state.status, MealPlanStatus.ready);
    expect(cubit.state.weekIndex, 1);
    expect(cubit.state.visibleWeek.offset, 0);
    expect(cubit.state.visibleEntries, hasLength(1));
    expect(cubit.state.tray, isEmpty);
  });

  test('load en échec réseau → statut error avec message', () async {
    when(
      () => repository.fetchWeek(any(), forceRefresh: any(named: 'forceRefresh')),
    ).thenThrow(const MealPlanRepositoryException('Pas de connexion.'));
    final cubit = build();
    await cubit.load();

    expect(cubit.state.status, MealPlanStatus.error);
    expect(cubit.state.loadError, 'Pas de connexion.');
  });

  test('selectWeek charge une semaine pas encore en cache', () async {
    final cubit = build();
    await cubit.load();
    await cubit.selectWeek(2);

    expect(cubit.state.weekIndex, 2);
    verify(
      () => repository.fetchWeek(t1Day, forceRefresh: any(named: 'forceRefresh')),
    ).called(1);
  });

  test('addRecipe ajoute l\'entrée renvoyée à la bonne semaine', () async {
    when(
      () => repository.addEntry(
        day: tDay,
        slot: MealSlot.soir,
        type: MealEntryType.recipe,
        recipeId: 'r1',
        noteText: null,
      ),
    ).thenAnswer((_) async => entry(id: 'e2', slot: MealSlot.soir));
    final cubit = build();
    await cubit.load();
    await cubit.addRecipe(day: tDay, slot: MealSlot.soir, recipeId: 'r1');

    expect(cubit.state.slotEntries(tDay, MealSlot.soir), hasLength(1));
  });

  test('limite premium à l\'ajout → premiumLimit transitoire puis acquitté',
      () async {
    when(
      () => repository.addEntry(
        day: any(named: 'day'),
        slot: any(named: 'slot'),
        type: any(named: 'type'),
        recipeId: any(named: 'recipeId'),
        noteText: any(named: 'noteText'),
      ),
    ).thenThrow(
      const MealPlanRepositoryException(
        'limite',
        premiumLimit: PremiumLimitError(
          code: PremiumLimitError.mealSlotEntries,
          limit: 1,
          current: 1,
        ),
      ),
    );
    final cubit = build();
    await cubit.load();
    await cubit.addRecipe(day: tDay, slot: MealSlot.midi, recipeId: 'r1');

    expect(cubit.state.premiumLimit?.code, PremiumLimitError.mealSlotEntries);
    cubit.acknowledge();
    expect(cubit.state.premiumLimit, isNull);
  });

  test('removeEntry retire l\'entrée et arme l\'annulation', () async {
    final e = entry();
    when(
      () => repository.fetchWeek(tDay, forceRefresh: any(named: 'forceRefresh')),
    ).thenAnswer((_) async => [e]);
    when(
      () => repository.removeEntry(id: 'e1', day: tDay),
    ).thenAnswer((_) async {});
    when(
      () => repository.addEntry(
        day: tDay,
        slot: MealSlot.midi,
        type: MealEntryType.recipe,
        recipeId: 'r1',
        noteText: null,
      ),
    ).thenAnswer((_) async => e);
    final cubit = build();
    await cubit.load();

    await cubit.removeEntry(e);
    expect(cubit.state.visibleEntries, isEmpty);
    expect(cubit.state.removedEntry, e);

    cubit.acknowledge();
    await cubit.undoRemove();
    expect(cubit.state.visibleEntries, hasLength(1));
  });

  test('les signaux one-shot ne persistent pas au changement d\'état suivant',
      () async {
    when(
      () => repository.addEntry(
        day: any(named: 'day'),
        slot: any(named: 'slot'),
        type: any(named: 'type'),
        recipeId: any(named: 'recipeId'),
        noteText: any(named: 'noteText'),
      ),
    ).thenThrow(
      const MealPlanRepositoryException(
        'limite',
        premiumLimit: PremiumLimitError(
          code: PremiumLimitError.mealSlotEntries,
        ),
      ),
    );
    final cubit = build();
    await cubit.load();
    await cubit.addRecipe(day: tDay, slot: MealSlot.midi, recipeId: 'r1');
    expect(cubit.state.premiumLimit, isNotNull);

    // Un changement d'état sans rapport (bascule de layout) ne doit PAS
    // reporter le signal premium — sinon le paywall se ré-afficherait.
    cubit.setLayout(PlanningLayout.blocks);
    expect(cubit.state.premiumLimit, isNull);
  });

  test('mode sélection : compte les recettes des créneaux cochés', () async {
    final recipeEntry = entry();
    final noteEntry = entry(id: 'e2', slot: MealSlot.soir, type: MealEntryType.note);
    when(
      () => repository.fetchWeek(tDay, forceRefresh: any(named: 'forceRefresh')),
    ).thenAnswer((_) async => [recipeEntry, noteEntry]);
    final cubit = build();
    await cubit.load();

    cubit.enterSelectMode();
    cubit.toggleSlotSelected('$tDay|midi');
    cubit.toggleSlotSelected('$tDay|soir');

    // La note cochée ne compte pas comme recette pour la liste de courses.
    expect(cubit.state.selectedRecipeCount, 1);
    expect(cubit.selectedRecipes().keys, ['r1']);

    cubit.exitSelectMode();
    expect(cubit.state.selectMode, isFalse);
    expect(cubit.state.selectedSlots, isEmpty);
  });

  test('setTray persiste puis hydrate le bandeau via les recettes', () async {
    when(() => trayStore.write(['r1'])).thenAnswer((_) async {});
    when(() => trayStore.read()).thenAnswer((_) async => ['r1']);
    when(() => recipes.fetchMine()).thenAnswer(
      (_) async => const [RecipeSummary(id: 'r1', name: 'Bolo', servings: 2)],
    );
    final cubit = build();
    await cubit.setTray(['r1']);

    expect(cubit.state.tray.map((r) => r.id), ['r1']);
    verify(() => trayStore.write(['r1'])).called(1);
  });
}
