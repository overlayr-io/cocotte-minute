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

/// Charge et pilote une fiche recette (édition des champs de base, suppression).
/// L'ajout d'ingrédients / de composants se fera dans une itération ultérieure
/// (pickers) ; le serveur les expose déjà.
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
}
