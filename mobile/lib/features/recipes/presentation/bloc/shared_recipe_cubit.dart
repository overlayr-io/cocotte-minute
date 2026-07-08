import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/recipes_repository.dart';
import '../../domain/recipe.dart';

/// État de l'écran d'une recette ouverte via un lien de partage (lecture seule).
sealed class SharedRecipeState extends Equatable {
  const SharedRecipeState();

  @override
  List<Object?> get props => const [];
}

class SharedRecipeLoading extends SharedRecipeState {
  const SharedRecipeLoading();
}

class SharedRecipeError extends SharedRecipeState {
  const SharedRecipeError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class SharedRecipeLoaded extends SharedRecipeState {
  const SharedRecipeLoaded(this.detail);

  final RecipeDetail detail;

  @override
  List<Object?> get props => [detail];
}

/// Charge une recette à partir de son token de partage public (route serveur non
/// authentifiée). Aucune action d'édition : cet écran est en lecture seule.
class SharedRecipeCubit extends Cubit<SharedRecipeState> {
  SharedRecipeCubit({
    required RecipesRepository repository,
    required this.token,
  }) : _repository = repository,
       super(const SharedRecipeLoading());

  final RecipesRepository _repository;
  final String token;

  Future<void> load() async {
    emit(const SharedRecipeLoading());
    try {
      final detail = await _repository.fetchByShareToken(token);
      emit(SharedRecipeLoaded(detail));
    } on RecipesRepositoryException catch (e) {
      emit(SharedRecipeError(e.message));
    }
  }
}
