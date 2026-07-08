import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/recipes_repository.dart';
import '../../domain/recipe.dart';

part 'uncategorized_recipes_state.dart';

/// Charge les recettes rangées dans aucun dossier (dossier virtuel « Autres »
/// de la page Recettes). L'échec est non bloquant : la carte « Autres » est
/// simplement masquée tant que le chargement n'a pas abouti.
class UncategorizedRecipesCubit extends Cubit<UncategorizedRecipesState> {
  UncategorizedRecipesCubit({required RecipesRepository repository})
    : _repository = repository,
      super(const UncategorizedRecipesLoading());

  final RecipesRepository _repository;

  Future<void> load() async {
    if (state is! UncategorizedRecipesLoaded) {
      emit(const UncategorizedRecipesLoading());
    }
    try {
      final recipes = await _repository.fetchUncategorized();
      emit(UncategorizedRecipesLoaded(recipes));
    } on RecipesRepositoryException catch (e) {
      emit(UncategorizedRecipesError(e.message));
    }
  }
}
