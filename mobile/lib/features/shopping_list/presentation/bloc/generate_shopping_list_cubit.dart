import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/premium/premium_limit_error.dart';
import '../../../../core/pricing/price_calculator.dart';
import '../../../ingredient_prices/data/ingredient_prices_repository.dart';
import '../../../ingredient_prices/domain/ingredient_price.dart';
import '../../../ingredients/domain/ingredient.dart';
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
    this.priceEstimate = PriceEstimate.empty,
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

  /// Total en direct des recettes sélectionnées (feature prix-estime) — somme
  /// par recette scalée aux portions choisies, jamais une agrégation par
  /// ingrédient dédupliqué. Se complète progressivement : une recette dont la
  /// fiche n'est pas encore chargée ne contribue pas encore au total.
  final PriceEstimate priceEstimate;

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
    PriceEstimate? priceEstimate,
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
      priceEstimate: priceEstimate ?? this.priceEstimate,
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
    priceEstimate,
  ];
}

/// Assistant de génération d'une liste de courses (5b → 5d) : choix des recettes,
/// nombre de parts par recette, exclusion du placard, puis génération serveur.
class GenerateShoppingListCubit extends Cubit<GenerateState> {
  GenerateShoppingListCubit({
    required RecipesRepository recipesRepository,
    required ShoppingListRepository shoppingRepository,
    required IngredientPricesRepository pricesRepository,
    this.initialRecipeId,
  }) : _recipes = recipesRepository,
       _shopping = shoppingRepository,
       _prices = pricesRepository,
       super(const GenerateState()) {
    _loadRecipes();
  }

  final RecipesRepository _recipes;
  final ShoppingListRepository _shopping;
  final IngredientPricesRepository _prices;

  /// Fiches déjà chargées (prix + agrégation placard) : évite de refetcher une
  /// recette déjà consultée pendant ce parcours.
  final Map<String, RecipeDetail> _detailCache = {};

  /// Recette à pré-sélectionner au chargement (entrée « Ajouter aux courses »
  /// depuis une fiche recette). Null pour le flux normal depuis l'onglet Courses.
  final String? initialRecipeId;

  /// La liste de sélection est une recherche par nom, plafonnée (pas de
  /// pagination) : requête vide = les N recettes les plus récentes.
  static const int _kSearchLimit = 10;
  Timer? _searchDebounce;

  Future<void> _loadRecipes() async {
    emit(state.copyWith(phase: GeneratePhase.loadingRecipes));
    try {
      final recipes = await _recipes.fetchMine(limit: _kSearchLimit);
      final initial = initialRecipeId;
      RecipeSummary? preselect;
      if (initial != null) {
        preselect = _firstWhereIdOrNull(recipes, initial);
        // Présélection possiblement hors des N récents (« Ajouter aux courses »
        // depuis une vieille fiche) : on récupère sa fiche pour la garantir.
        if (preselect == null) {
          try {
            preselect = (await _recipes.fetchDetail(initial)).summary;
          } on RecipesRepositoryException {
            preselect = null;
          }
        }
      }
      // Présélection absente de la liste des récents → on la préfixe pour
      // qu'elle reste visible et décochable.
      final list = (preselect != null &&
              _firstWhereIdOrNull(recipes, preselect.id) == null)
          ? [preselect, ...recipes]
          : recipes;
      emit(state.copyWith(
        phase: GeneratePhase.ready,
        recipes: list,
        selectedIds: preselect == null ? null : {preselect.id},
        servings: preselect == null
            ? null
            : {preselect.id: preselect.servings < 1 ? 1 : preselect.servings},
      ));
      if (preselect != null) unawaited(_ensurePriced(preselect.id));
    } on RecipesRepositoryException catch (e) {
      emit(state.copyWith(phase: GeneratePhase.error, errorMessage: e.message));
    }
  }

  static RecipeSummary? _firstWhereIdOrNull(
      List<RecipeSummary> list, String id) {
    for (final r in list) {
      if (r.id == id) return r;
    }
    return null;
  }

  /// Recherche par nom (debounce 300 ms). Requête vide → recettes récentes.
  /// La sélection en cours est préservée (elle vit dans `selectedIds`).
  void searchRecipes(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      unawaited(_runSearch(query.trim()));
    });
  }

  Future<void> _runSearch(String query) async {
    try {
      final recipes = await _recipes.fetchMine(
        q: query.isEmpty ? null : query,
        limit: _kSearchLimit,
      );
      emit(state.copyWith(recipes: recipes));
    } on RecipesRepositoryException catch (e) {
      emit(state.copyWith(actionError: e.message));
    }
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }

  Future<void> retry() => _loadRecipes();

  void toggleRecipe(RecipeSummary recipe) {
    final selected = Set<String>.from(state.selectedIds);
    final servings = Map<String, int>.from(state.servings);
    final adding = !selected.contains(recipe.id);
    if (adding) {
      selected.add(recipe.id);
      servings[recipe.id] = recipe.servings < 1 ? 1 : recipe.servings;
    } else {
      selected.remove(recipe.id);
      servings.remove(recipe.id);
    }
    emit(state.copyWith(selectedIds: selected, servings: servings));
    if (adding) {
      unawaited(_ensurePriced(recipe.id));
    } else {
      unawaited(_recomputeTotal());
    }
  }

  void setServings(String recipeId, int value) {
    if (value < 1) return;
    final servings = Map<String, int>.from(state.servings)..[recipeId] = value;
    emit(state.copyWith(servings: servings));
    unawaited(_recomputeTotal());
  }

  /// Charge la fiche d'une recette sélectionnée (mise en cache) si besoin, puis
  /// recalcule le total — best-effort : un échec laisse simplement la recette
  /// hors du total tant qu'elle n'a pas pu être chargée.
  Future<void> _ensurePriced(String recipeId) async {
    if (!_detailCache.containsKey(recipeId)) {
      try {
        _detailCache[recipeId] = await _recipes.fetchDetail(recipeId);
      } on RecipesRepositoryException {
        return;
      }
    }
    await _recomputeTotal();
  }

  /// Somme par recette (jamais une agrégation par ingrédient dédupliqué, cf.
  /// doc prix-estime), scalée aux portions choisies pour chacune. Une recette
  /// pas encore chargée ne contribue pas encore au total (se complète au fil
  /// des réponses réseau).
  Future<void> _recomputeTotal() async {
    List<IngredientPrice> prices;
    try {
      prices = await _prices.fetchMine();
    } on IngredientPricesRepositoryException {
      prices = const [];
    }
    final byId = {for (final p in prices) p.ingredientId: p};
    var total = PriceEstimate.empty;
    for (final id in state.selectedIds) {
      final detail = _detailCache[id];
      if (detail == null) continue;
      final base = detail.summary.servings < 1 ? 1 : detail.summary.servings;
      final chosen = state.servings[id] ?? base;
      final scale = chosen / base;
      if (detail.priceMode == RecipePriceMode.fixed) {
        final fixed = detail.fixedPrice;
        total += fixed == null
            ? const PriceEstimate(value: 0, knownCount: 0, totalCount: 1)
            : PriceEstimate(value: fixed * scale, knownCount: 1, totalCount: 1);
      } else {
        final estimate = estimateFromLines(
          detail.ingredients.map(
            (line) => (
              quantity: line.quantity,
              unit: IngredientUnit.fromWire(line.unit),
              ingredientId: line.id,
            ),
          ),
          byId,
        );
        total += PriceEstimate(
          value: estimate.value * scale,
          knownCount: estimate.knownCount,
          totalCount: estimate.totalCount,
        );
      }
    }
    if (isClosed) return;
    emit(state.copyWith(priceEstimate: total));
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
        final detail = _detailCache[recipeId] ?? await _recipes.fetchDetail(recipeId);
        _detailCache[recipeId] = detail;
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
