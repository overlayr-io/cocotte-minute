part of 'recipes_list_bloc.dart';

sealed class RecipesListState extends Equatable {
  const RecipesListState();

  @override
  List<Object?> get props => const [];
}

class RecipesListInitial extends RecipesListState {
  const RecipesListInitial();
}

class RecipesListLoading extends RecipesListState {
  const RecipesListLoading();
}

/// Liste chargée (les plus récentes d'abord).
class RecipesListLoaded extends RecipesListState {
  const RecipesListLoaded({required this.recipes});

  final List<RecipeSummary> recipes;

  @override
  List<Object?> get props => [recipes];
}

/// Échec bloquant du chargement → page d'erreur + retry.
class RecipesListError extends RecipesListState {
  const RecipesListError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
