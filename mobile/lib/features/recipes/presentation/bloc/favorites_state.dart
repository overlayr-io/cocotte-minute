part of 'favorites_cubit.dart';

sealed class FavoritesState extends Equatable {
  const FavoritesState();

  @override
  List<Object?> get props => const [];
}

class FavoritesLoading extends FavoritesState {
  const FavoritesLoading();
}

class FavoritesLoaded extends FavoritesState {
  const FavoritesLoaded(this.recipes);

  final List<RecipeSummary> recipes;

  @override
  List<Object?> get props => [recipes];
}

class FavoritesError extends FavoritesState {
  const FavoritesError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
