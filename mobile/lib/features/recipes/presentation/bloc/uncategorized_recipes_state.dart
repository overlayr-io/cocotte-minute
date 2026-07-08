part of 'uncategorized_recipes_cubit.dart';

sealed class UncategorizedRecipesState extends Equatable {
  const UncategorizedRecipesState();

  @override
  List<Object?> get props => const [];
}

class UncategorizedRecipesLoading extends UncategorizedRecipesState {
  const UncategorizedRecipesLoading();
}

class UncategorizedRecipesLoaded extends UncategorizedRecipesState {
  const UncategorizedRecipesLoaded(this.recipes);

  final List<RecipeSummary> recipes;

  @override
  List<Object?> get props => [recipes];
}

class UncategorizedRecipesError extends UncategorizedRecipesState {
  const UncategorizedRecipesError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
