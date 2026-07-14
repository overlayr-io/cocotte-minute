import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/recipes_repository.dart';
import '../../domain/recipe.dart';

part 'favorites_state.dart';

/// Charge les recettes aimées « J'aime » (#15), pour le dossier virtuel dédié
/// de la page Recettes. L'échec est non bloquant : la carte « J'aime » est
/// simplement masquée tant que le chargement n'a pas abouti.
class FavoritesCubit extends Cubit<FavoritesState> {
  FavoritesCubit({required RecipesRepository repository})
    : _repository = repository,
      super(const FavoritesLoading());

  final RecipesRepository _repository;

  Future<void> load() async {
    if (state is! FavoritesLoaded) {
      emit(const FavoritesLoading());
    }
    try {
      final recipes = await _repository.fetchFavorites();
      emit(FavoritesLoaded(recipes));
    } on RecipesRepositoryException catch (e) {
      emit(FavoritesError(e.message));
    }
  }
}
