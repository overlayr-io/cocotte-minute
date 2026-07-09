import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/premium/premium_limit_error.dart';
import '../../../recipes/data/recipes_repository.dart';
import '../../../recipes/domain/recipe.dart';
import '../../data/shopping_list_api.dart';
import '../../data/shopping_list_repository.dart';

/// Ligne d'ingrédient agrégée présentée à l'étape « placard » (5d) : quantité
/// totale (mise à l'échelle des parts choisies) — calcul d'affichage local, le
/// serveur recalcule l'agrégation autoritative à la génération.
class PantryIngredient extends Equatable {
  const PantryIngredient({
    required this.id,
    required this.name,
    required this.unit,
    required this.quantity,
  });

  final String id;
  final String name;
  final String unit;
  final double quantity;

  @override
  List<Object?> get props => [id, name, unit, quantity];
}

enum GeneratePhase { loadingRecipes, error, ready }

class GenerateState extends Equatable {
  const GenerateState({
    this.phase = GeneratePhase.loadingRecipes,
    this.errorMessage,
    this.recipes = const [],
    this.step = 1,
    this.selectedIds = const {},
    this.servings = const {},
    this.loadingIngredients = false,
    this.ingredients = const [],
    this.pantryIds = const {},
    this.generating = false,
    this.generatedListId,
    this.actionError,
    this.premiumLimit,
  });

  final GeneratePhase phase;
  final String? errorMessage;
  final List<RecipeSummary> recipes;
  final int step; // 1..3
  final Set<String> selectedIds;
  final Map<String, int> servings;
  final bool loadingIngredients;
  final List<PantryIngredient> ingredients;

  /// Ingrédients cochés « je les ai déjà » → exclus de la liste générée.
  final Set<String> pantryIds;
  final bool generating;
  final String? generatedListId;

  /// Message transitoire (échec de génération) à montrer en snackbar.
  final String? actionError;

  /// Limite freemium atteinte (403 `PREMIUM_LIMIT_SHOPPING_LISTS`) : la page
  /// ouvre la feuille d'upsell au lieu d'un snackbar. Transitoire.
  final PremiumLimitError? premiumLimit;

  int get selectedCount => selectedIds.length;
  int get totalServings =>
      selectedIds.fold(0, (sum, id) => sum + (servings[id] ?? 0));

  /// Nombre d'articles qui finiront dans la liste (union hors placard).
  int get itemsToBuy =>
      ingredients.where((i) => !pantryIds.contains(i.id)).length;

  GenerateState copyWith({
    GeneratePhase? phase,
    String? errorMessage,
    List<RecipeSummary>? recipes,
    int? step,
    Set<String>? selectedIds,
    Map<String, int>? servings,
    bool? loadingIngredients,
    List<PantryIngredient>? ingredients,
    Set<String>? pantryIds,
    bool? generating,
    String? generatedListId,
    String? actionError,
    PremiumLimitError? premiumLimit,
  }) {
    return GenerateState(
      phase: phase ?? this.phase,
      errorMessage: errorMessage ?? this.errorMessage,
      recipes: recipes ?? this.recipes,
      step: step ?? this.step,
      selectedIds: selectedIds ?? this.selectedIds,
      servings: servings ?? this.servings,
      loadingIngredients: loadingIngredients ?? this.loadingIngredients,
      ingredients: ingredients ?? this.ingredients,
      pantryIds: pantryIds ?? this.pantryIds,
      generating: generating ?? this.generating,
      generatedListId: generatedListId ?? this.generatedListId,
      actionError: actionError,
      premiumLimit: premiumLimit,
    );
  }

  @override
  List<Object?> get props => [
    phase,
    errorMessage,
    recipes,
    step,
    selectedIds,
    servings,
    loadingIngredients,
    ingredients,
    pantryIds,
    generating,
    generatedListId,
    actionError,
    premiumLimit,
  ];
}

/// Assistant de génération d'une liste de courses (5b → 5d) : choix des recettes,
/// nombre de parts par recette, exclusion du placard, puis génération serveur.
class GenerateShoppingListCubit extends Cubit<GenerateState> {
  GenerateShoppingListCubit({
    required RecipesRepository recipesRepository,
    required ShoppingListRepository shoppingRepository,
    this.initialRecipeId,
  }) : _recipes = recipesRepository,
       _shopping = shoppingRepository,
       super(const GenerateState()) {
    _loadRecipes();
  }

  final RecipesRepository _recipes;
  final ShoppingListRepository _shopping;

  /// Recette à pré-sélectionner au chargement (entrée « Ajouter aux courses »
  /// depuis une fiche recette). Null pour le flux normal depuis l'onglet Courses.
  final String? initialRecipeId;

  Future<void> _loadRecipes() async {
    emit(state.copyWith(phase: GeneratePhase.loadingRecipes));
    try {
      final recipes = await _recipes.fetchMine();
      final initial = initialRecipeId;
      RecipeSummary? preselect;
      if (initial != null) {
        for (final r in recipes) {
          if (r.id == initial) {
            preselect = r;
            break;
          }
        }
      }
      emit(state.copyWith(
        phase: GeneratePhase.ready,
        recipes: recipes,
        selectedIds: preselect == null ? null : {preselect.id},
        servings: preselect == null
            ? null
            : {preselect.id: preselect.servings < 1 ? 1 : preselect.servings},
      ));
    } on RecipesRepositoryException catch (e) {
      emit(state.copyWith(phase: GeneratePhase.error, errorMessage: e.message));
    }
  }

  Future<void> retry() => _loadRecipes();

  void toggleRecipe(RecipeSummary recipe) {
    final selected = Set<String>.from(state.selectedIds);
    final servings = Map<String, int>.from(state.servings);
    if (selected.contains(recipe.id)) {
      selected.remove(recipe.id);
      servings.remove(recipe.id);
    } else {
      selected.add(recipe.id);
      servings[recipe.id] = recipe.servings < 1 ? 1 : recipe.servings;
    }
    emit(state.copyWith(selectedIds: selected, servings: servings));
  }

  void setServings(String recipeId, int value) {
    if (value < 1) return;
    final servings = Map<String, int>.from(state.servings)..[recipeId] = value;
    emit(state.copyWith(servings: servings));
  }

  Future<void> next() async {
    if (state.step == 1) {
      if (state.selectedIds.isEmpty) return;
      emit(state.copyWith(step: 2));
    } else if (state.step == 2) {
      emit(state.copyWith(step: 3, loadingIngredients: true));
      await _loadIngredients();
    }
  }

  void back() {
    if (state.step > 1) emit(state.copyWith(step: state.step - 1));
  }

  void togglePantry(String ingredientId) {
    final pantry = Set<String>.from(state.pantryIds);
    if (!pantry.remove(ingredientId)) pantry.add(ingredientId);
    emit(state.copyWith(pantryIds: pantry));
  }

  /// Charge et agrège (affichage) les ingrédients des recettes sélectionnées.
  Future<void> _loadIngredients() async {
    final byId = <String, PantryIngredient>{};
    try {
      for (final recipeId in state.selectedIds) {
        final detail = await _recipes.fetchDetail(recipeId);
        final base = detail.summary.servings < 1 ? 1 : detail.summary.servings;
        final chosen = state.servings[recipeId] ?? base;
        final factor = chosen / base;
        for (final line in detail.ingredients) {
          final scaled = line.quantity * factor;
          final existing = byId[line.id];
          byId[line.id] = PantryIngredient(
            id: line.id,
            name: line.name,
            unit: line.unit,
            quantity: (existing?.quantity ?? 0) + scaled,
          );
        }
      }
      final list = byId.values.toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      emit(state.copyWith(loadingIngredients: false, ingredients: list));
    } on RecipesRepositoryException catch (e) {
      emit(state.copyWith(loadingIngredients: false, actionError: e.message));
    }
  }

  /// Génère la liste côté serveur (agrégation autoritative) puis la stocke en
  /// local. Nécessite le réseau ; remonte le message serveur en cas d'échec
  /// (ex: garde freemium « une seule liste active »).
  Future<void> generate(String name) async {
    if (state.generating) return;
    emit(state.copyWith(generating: true));
    try {
      final detail = await _shopping.generate(
        name: name,
        recipes: [
          for (final id in state.selectedIds)
            (recipeId: id, servings: state.servings[id] ?? 1),
        ],
        pantryIngredientIds: state.pantryIds.toList(),
      );
      emit(state.copyWith(generating: false, generatedListId: detail.list.id));
    } on ShoppingListApiException catch (e) {
      // Limite freemium (1 liste active) : distincte du message brut pour que
      // la page ouvre la feuille d'upsell au lieu d'un snackbar.
      emit(state.copyWith(
        generating: false,
        actionError: e.premiumLimit == null ? e.message : null,
        premiumLimit: e.premiumLimit,
      ));
    }
  }
}
