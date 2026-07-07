part of 'recipes_list_bloc.dart';

sealed class RecipesListEvent extends Equatable {
  const RecipesListEvent();

  @override
  List<Object?> get props => const [];
}

/// Charge (ou recharge) la liste des recettes du compte.
class RecipesRequested extends RecipesListEvent {
  const RecipesRequested();
}
