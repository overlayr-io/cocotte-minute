part of 'folder_recipes_cubit.dart';

sealed class FolderRecipesState extends Equatable {
  const FolderRecipesState();

  @override
  List<Object?> get props => const [];
}

class FolderRecipesLoading extends FolderRecipesState {
  const FolderRecipesLoading();
}

/// Recettes du dossier chargées (les plus récentes d'abord).
class FolderRecipesLoaded extends FolderRecipesState {
  const FolderRecipesLoaded(this.recipes);

  final List<RecipeSummary> recipes;

  @override
  List<Object?> get props => [recipes];
}

/// Échec non bloquant du chargement → encart de réessai dans la section.
class FolderRecipesError extends FolderRecipesState {
  const FolderRecipesError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
