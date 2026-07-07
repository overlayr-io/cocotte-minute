import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

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
  });

  final RecipeDetail detail;

  /// Une action (enregistrement / suppression) est en cours.
  final bool busy;

  /// Message transitoire à afficher en snackbar (erreur d'action non bloquante).
  final String? message;

  /// La recette vient d'être supprimée → la page doit se refermer.
  final bool deleted;

  RecipeDetailLoaded copyWith({
    RecipeDetail? detail,
    bool? busy,
    String? message,
    bool? deleted,
  }) {
    return RecipeDetailLoaded(
      detail: detail ?? this.detail,
      busy: busy ?? this.busy,
      message: message,
      deleted: deleted ?? this.deleted,
    );
  }

  @override
  List<Object?> get props => [detail, busy, message, deleted];
}

/// Ligne à ajouter à une recette : ingrédient + quantité (unité lue depuis
/// l'ingrédient côté serveur).
typedef RecipeIngredientDraft = ({String ingredientId, double quantity});

/// Charge et pilote une fiche recette : édition des champs de base, suppression,
/// et gestion des ingrédients (ajout multiple, modification de quantité, retrait).
class RecipeDetailCubit extends Cubit<RecipeDetailState> {
  RecipeDetailCubit({
    required RecipesRepository repository,
    required this.recipeId,
  }) : _repository = repository,
       super(const RecipeDetailLoading());

  final RecipesRepository _repository;
  final String recipeId;

  Future<void> load() async {
    emit(const RecipeDetailLoading());
    try {
      final detail = await _repository.fetchDetail(recipeId);
      emit(RecipeDetailLoaded(detail: detail));
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
      );
      // Recharge la fiche pour refléter les relations dérivées (verrou, etc.).
      final detail = await _repository.fetchDetail(recipeId);
      emit(RecipeDetailLoaded(detail: detail));
    } on RecipesRepositoryException catch (e) {
      emit(current.copyWith(busy: false, message: e.message));
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
  }
}
