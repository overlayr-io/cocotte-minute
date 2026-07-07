import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/recipes_repository.dart';
import '../../domain/recipe.dart';

part 'recipes_list_event.dart';
part 'recipes_list_state.dart';

/// Bloc de la liste des recettes (onglet Recettes). La création et l'édition
/// détaillée se font sur leurs pages dédiées ; ce bloc ne fait que charger et
/// rafraîchir la liste (les pages redéclenchent [RecipesRequested] au retour).
class RecipesListBloc extends Bloc<RecipesListEvent, RecipesListState> {
  RecipesListBloc({required RecipesRepository repository})
    : _repository = repository,
      super(const RecipesListInitial()) {
    on<RecipesRequested>(_onRequested);
  }

  final RecipesRepository _repository;

  Future<void> _onRequested(
    RecipesRequested event,
    Emitter<RecipesListState> emit,
  ) async {
    if (state is! RecipesListLoaded) emit(const RecipesListLoading());
    try {
      final recipes = await _repository.fetchMine();
      emit(RecipesListLoaded(recipes: recipes));
    } on RecipesRepositoryException catch (e) {
      emit(RecipesListError(e.message));
    }
  }
}
