import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../recipes/data/recipes_repository.dart';
import '../../../recipes/domain/recipe.dart';

part 'folder_recipes_state.dart';

/// Charge les recettes rangées dans un dossier (`GET /categories/:id/recipes`).
/// L'échec est **non bloquant** : la vue dossier affiche un encart de réessai
/// sans casser la navigation dans l'arborescence (les sous-dossiers, eux,
/// viennent du bloc Catégories partagé).
class FolderRecipesCubit extends Cubit<FolderRecipesState> {
  FolderRecipesCubit({required RecipesRepository repository})
    : _repository = repository,
      super(const FolderRecipesLoading());

  final RecipesRepository _repository;

  Future<void> load(String categoryId) async {
    if (state is! FolderRecipesLoaded) emit(const FolderRecipesLoading());
    try {
      final recipes = await _repository.fetchByCategory(categoryId);
      emit(FolderRecipesLoaded(recipes));
    } on RecipesRepositoryException catch (e) {
      emit(FolderRecipesError(e.message));
    }
  }
}
