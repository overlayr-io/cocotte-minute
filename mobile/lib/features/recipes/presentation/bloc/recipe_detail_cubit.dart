import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/premium/premium_limit_error.dart';
import '../../../../core/pricing/price_calculator.dart';
import '../../../ingredient_prices/data/ingredient_prices_repository.dart';
import '../../../ingredients/domain/ingredient.dart';
import '../../data/recipes_repository.dart';
import '../../domain/recipe.dart';

/// État de la fiche détail. Un seul `Loaded` porte la recette + les drapeaux
/// transitoires (action en cours, message snackbar, suppression effectuée).
sealed class RecipeDetailState extends Equatable {
  const RecipeDetailState();

  @override
  List<Object?> get props => const [];
}

class RecipeDetailLoading extends RecipeDetailState {
  const RecipeDetailLoading();
}

class RecipeDetailError extends RecipeDetailState {
  const RecipeDetailError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class RecipeDetailLoaded extends RecipeDetailState {
  const RecipeDetailLoaded({
    required this.detail,
    this.busy = false,
    this.message,
    this.deleted = false,
    this.premiumLimit,
  });

  final RecipeDetail detail;

  /// Une action (enregistrement / suppression) est en cours.
  final bool busy;

  /// Message transitoire à afficher en snackbar (erreur d'action non bloquante).
  final String? message;

  /// La recette vient d'être supprimée → la page doit se refermer.
  final bool deleted;

  /// Limite freemium atteinte (403 `PREMIUM_LIMIT_BASE_RECIPES` au passage
  /// is_base) : la vue ouvre la feuille d'upsell. Transitoire.
  final PremiumLimitError? premiumLimit;

  RecipeDetailLoaded copyWith({
    RecipeDetail? detail,
    bool? busy,
    String? message,
    bool? deleted,
    PremiumLimitError? premiumLimit,
  }) {
    return RecipeDetailLoaded(
      detail: detail ?? this.detail,
      busy: busy ?? this.busy,
      message: message,
      deleted: deleted ?? this.deleted,
      premiumLimit: premiumLimit,
    );
  }

  @override
  List<Object?> get props => [detail, busy, message, deleted, premiumLimit];
}

/// Ligne à ajouter à une recette : ingrédient + quantité (unité lue depuis
/// l'ingrédient côté serveur).
typedef RecipeIngredientDraft = ({String ingredientId, double quantity});

/// Charge et pilote une fiche recette : édition des champs de base, suppression,
/// et gestion des ingrédients (ajout multiple, modification de quantité, retrait).
class RecipeDetailCubit extends Cubit<RecipeDetailState> {
  RecipeDetailCubit({
    required RecipesRepository repository,
    required IngredientPricesRepository pricesRepository,
    required this.recipeId,
  }) : _repository = repository,
       _pricesRepository = pricesRepository,
       super(const RecipeDetailLoading());

  final RecipesRepository _repository;
  final IngredientPricesRepository _pricesRepository;
  final String recipeId;

  Future<void> load() async {
    emit(const RecipeDetailLoading());
    try {
      final detail = await _repository.fetchDetail(recipeId);
      emit(RecipeDetailLoaded(detail: detail));
      unawaited(_syncPriceBracket(detail));
    } on RecipesRepositoryException catch (e) {
      emit(RecipeDetailError(e.message));
    }
  }

  Future<void> updateFields({
    String? name,
    String? description,
    bool? isBase,
    int? prepTime,
    int? cookTime,
    int? restTime,
    int? servings,
    RecipePriceMode? priceMode,
    double? fixedPrice,
  }) async {
    final current = state;
    if (current is! RecipeDetailLoaded) return;
    emit(current.copyWith(busy: true));
    try {
      await _repository.update(
        recipeId,
        name: name,
        description: description,
        isBase: isBase,
        prepTime: prepTime,
        cookTime: cookTime,
        restTime: restTime,
        servings: servings,
        priceMode: priceMode,
        fixedPrice: fixedPrice,
      );
      // Recharge la fiche pour refléter les relations dérivées (verrou, etc.).
      final detail = await _repository.fetchDetail(recipeId);
      emit(RecipeDetailLoaded(detail: detail));
      unawaited(_syncPriceBracket(detail));
    } on RecipesRepositoryException catch (e) {
      // Limite freemium (5 recettes de base max) : signalée à part pour que
      // la vue ouvre la feuille d'upsell au lieu d'un snackbar.
      emit(current.copyWith(
        busy: false,
        message: e.premiumLimit == null ? e.message : null,
        premiumLimit: e.premiumLimit,
      ));
    }
  }

  /// Recalcule la tranche de prix côté client (jamais le serveur) et la pousse
  /// si elle a changé depuis le dernier chargement — best-effort et silencieux,
  /// une tranche pas à jour n'est jamais bloquante ni signalée à l'utilisateur.
  /// Basée sur le mode de prix actif, jamais sur un total partiel (`≈`).
  Future<void> _syncPriceBracket(RecipeDetail detail) async {
    try {
      RecipePriceBracket? bracket;
      if (detail.priceMode == RecipePriceMode.fixed) {
        final fixed = detail.fixedPrice;
        bracket = fixed == null ? null : priceBracketForValue(fixed);
      } else if (detail.ingredients.isEmpty) {
        bracket = null;
      } else {
        final prices = await _pricesRepository.fetchMine();
        final byId = {for (final p in prices) p.ingredientId: p};
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
        bracket = estimate.isPartial ? null : priceBracketForValue(estimate.value);
      }
      if (bracket == detail.priceBracket) return;
      await _repository.update(recipeId, priceBracket: bracket);
      if (isClosed) return;
      final current = state;
      if (current is RecipeDetailLoaded) {
        emit(current.copyWith(detail: current.detail.copyWithPriceBracket(bracket)));
      }
    } on Object {
      // Best-effort : cf. docstring.
    }
  }

  Future<void> delete() async {
    final current = state;
    if (current is! RecipeDetailLoaded) return;
    emit(current.copyWith(busy: true));
    try {
      await _repository.delete(recipeId);
      emit(current.copyWith(busy: false, deleted: true));
    } on RecipesRepositoryException catch (e) {
      emit(current.copyWith(busy: false, message: e.message));
    }
  }

  /// Ajoute plusieurs ingrédients (avec leur quantité) puis recharge la fiche.
  /// Ré-ajouter un ingrédient déjà présent met à jour sa quantité (upsert serveur).
  Future<void> addIngredients(List<RecipeIngredientDraft> drafts) async {
    final current = state;
    if (current is! RecipeDetailLoaded || drafts.isEmpty) return;
    emit(current.copyWith(busy: true));
    try {
      for (final d in drafts) {
        await _repository.addIngredient(recipeId, d.ingredientId, d.quantity);
      }
      await _reload();
    } on RecipesRepositoryException catch (e) {
      emit(current.copyWith(busy: false, message: e.message));
    }
  }

  Future<void> updateIngredientQuantity(
    String ingredientId,
    double quantity,
  ) async {
    final current = state;
    if (current is! RecipeDetailLoaded) return;
    emit(current.copyWith(busy: true));
    try {
      await _repository.updateIngredientQuantity(recipeId, ingredientId, quantity);
      await _reload();
    } on RecipesRepositoryException catch (e) {
      emit(current.copyWith(busy: false, message: e.message));
    }
  }

  Future<void> removeIngredient(String ingredientId) async {
    final current = state;
    if (current is! RecipeDetailLoaded) return;
    emit(current.copyWith(busy: true));
    try {
      await _repository.removeIngredient(recipeId, ingredientId);
      await _reload();
    } on RecipesRepositoryException catch (e) {
      emit(current.copyWith(busy: false, message: e.message));
    }
  }

  // --- étapes ------------------------------------------------------------

  Future<void> addTextStep({
    required String description,
    StepBanner? banner,
    List<String> ingredientIds = const [],
  }) =>
      _runStepAction(() => _repository.addTextStep(
            recipeId,
            description: description,
            banner: banner,
            ingredientIds: ingredientIds,
          ));

  Future<void> addBaseRefStep(String baseRecipeId) =>
      _runStepAction(() => _repository.addBaseRefStep(recipeId, baseRecipeId));

  Future<void> importSteps(List<String> descriptions) =>
      _runStepAction(() => _repository.importSteps(recipeId, descriptions));

  Future<void> updateStep(
    String stepId, {
    required String description,
    StepBanner? banner,
    List<String>? ingredientIds,
  }) =>
      _runStepAction(() async {
        await _repository.updateStep(
          recipeId,
          stepId,
          description: description,
          banner: banner,
        );
        if (ingredientIds != null) {
          await _repository.setStepIngredients(recipeId, stepId, ingredientIds);
        }
      });

  Future<void> removeStep(String stepId) =>
      _runStepAction(() => _repository.removeStep(recipeId, stepId));

  Future<void> setStepIngredients(String stepId, List<String> ingredientIds) =>
      _runStepAction(
          () => _repository.setStepIngredients(recipeId, stepId, ingredientIds));

  /// Réordonne sans overlay bloquant (drag & drop) : le serveur renumérote,
  /// puis on recharge. En cas d'erreur, message + rechargement (revert visuel).
  Future<void> reorderSteps(List<String> stepIds) async {
    final current = state;
    if (current is! RecipeDetailLoaded) return;
    try {
      await _repository.reorderSteps(recipeId, stepIds);
      await _reload();
    } on RecipesRepositoryException catch (e) {
      emit(current.copyWith(message: e.message));
      await _reload();
    }
  }

  // --- composants (sous-recettes) ---------------------------------------

  Future<void> addComponent(String baseRecipeId) =>
      _runStepAction(() => _repository.addComponent(recipeId, baseRecipeId));

  Future<void> removeComponent(String baseRecipeId) =>
      _runStepAction(() => _repository.removeComponent(recipeId, baseRecipeId));

  // --- rangement & étiquetage -------------------------------------------
  // Toggles depuis une feuille restée ouverte : pas d'overlay bloquant (sinon
  // il clignoterait derrière la feuille à chaque appui), juste un rechargement.

  Future<void> assignCategory(String categoryId) =>
      _runRelationAction(() => _repository.assignCategory(recipeId, categoryId));

  Future<void> unassignCategory(String categoryId) => _runRelationAction(
      () => _repository.unassignCategory(recipeId, categoryId));

  Future<void> assignTag(String tagId) =>
      _runRelationAction(() => _repository.assignTag(recipeId, tagId));

  Future<void> unassignTag(String tagId) =>
      _runRelationAction(() => _repository.unassignTag(recipeId, tagId));

  Future<void> _runRelationAction(Future<void> Function() action) async {
    final current = state;
    if (current is! RecipeDetailLoaded) return;
    try {
      await action();
      await _reload();
    } on RecipesRepositoryException catch (e) {
      emit(current.copyWith(message: e.message));
    }
  }

  Future<void> _runStepAction(Future<void> Function() action) async {
    final current = state;
    if (current is! RecipeDetailLoaded) return;
    emit(current.copyWith(busy: true));
    try {
      await action();
      await _reload();
    } on RecipesRepositoryException catch (e) {
      emit(current.copyWith(busy: false, message: e.message));
    }
  }

  Future<void> _reload() async {
    final detail = await _repository.fetchDetail(recipeId);
    emit(RecipeDetailLoaded(detail: detail));
    unawaited(_syncPriceBracket(detail));
  }
}
