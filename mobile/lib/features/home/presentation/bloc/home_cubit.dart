import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../categories/data/categories_repository.dart';
import '../../../categories/domain/category.dart';
import '../../../recipes/data/recipes_repository.dart';
import '../../../recipes/domain/recipe.dart';

/// État de la page d'accueil.
sealed class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => const [];
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeError extends HomeState {
  const HomeError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Données de l'accueil : suggestion du jour, carrousel « Mises en avant » et
/// chips de catégories racines.
class HomeLoaded extends HomeState {
  const HomeLoaded({
    required this.suggestion,
    required this.featured,
    required this.categories,
  });

  /// Recette mise en avant (la plus récente), ou null si le compte n'en a aucune.
  final RecipeSummary? suggestion;

  /// Recettes du carrousel (les plus récentes d'abord).
  final List<RecipeSummary> featured;

  /// Catégories racines pour les chips (« Tout » ajouté côté UI).
  final List<Category> categories;

  bool get isEmpty => suggestion == null && featured.isEmpty;

  @override
  List<Object?> get props => [suggestion, featured, categories];
}

/// Charge la page d'accueil : recettes (pour la suggestion + le carrousel) et
/// catégories (pour les chips), en parallèle. Aucun endpoint dédié — on compose
/// à partir des données existantes du compte.
class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    required RecipesRepository recipesRepository,
    required CategoriesRepository categoriesRepository,
  }) : _recipes = recipesRepository,
       _categories = categoriesRepository,
       super(const HomeLoading());

  final RecipesRepository _recipes;
  final CategoriesRepository _categories;

  Future<void> load() async {
    emit(const HomeLoading());
    try {
      final results = await Future.wait([
        _recipes.fetchMine(),
        _categories.fetchMine(),
      ]);
      final recipes = results[0] as List<RecipeSummary>;
      final categories = results[1] as List<Category>;
      emit(
        HomeLoaded(
          suggestion: recipes.isNotEmpty ? recipes.first : null,
          featured: recipes,
          categories: categories.where((c) => c.isRoot).toList(growable: false),
        ),
      );
    } on RecipesRepositoryException catch (e) {
      emit(HomeError(e.message));
    } on CategoriesRepositoryException catch (e) {
      emit(HomeError(e.message));
    }
  }
}
