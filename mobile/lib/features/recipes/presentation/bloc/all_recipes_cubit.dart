import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/recipes_repository.dart';
import '../../domain/recipe.dart';
import '../../domain/recipe_sort.dart';

/// Vue Liste de la page Recettes : toutes les recettes, paginées (infinite
/// scroll) et filtrables par un texte simple (filtre serveur sur le nom —
/// distinct de la recherche avancée de l'Accueil).
class AllRecipesCubit extends Cubit<AllRecipesState> {
  AllRecipesCubit({required RecipesRepository repository})
    : _repository = repository,
      super(const AllRecipesState());

  static const _pageSize = 30;

  final RecipesRepository _repository;

  /// Jeton anti-course : seule la dernière requête lancée a le droit d'émettre.
  int _requestId = 0;

  /// Change le tri et recharge depuis la première page (le tri est serveur, la
  /// pagination doit repartir de zéro).
  Future<void> setSort(RecipeSort sort) async {
    if (sort == state.sort) return;
    emit(state.copyWith(sort: sort));
    await load();
  }

  /// (Re)charge la première page pour [query] ('' = toutes les recettes).
  Future<void> load({String? query}) async {
    final q = query ?? state.query;
    final id = ++_requestId;
    emit(state.copyWith(query: q, loading: true, error: null));
    try {
      final page = await _repository.fetchMine(
        q: q,
        limit: _pageSize,
        offset: 0,
        sort: state.sort,
      );
      if (id != _requestId) return;
      emit(state.copyWith(
        recipes: page,
        loading: false,
        hasMore: page.length == _pageSize,
      ));
    } on RecipesRepositoryException catch (e) {
      if (id != _requestId) return;
      emit(state.copyWith(loading: false, error: e.message));
    }
  }

  /// Page suivante (déclenchée en fin de scroll).
  Future<void> loadMore() async {
    if (state.loading || state.loadingMore || !state.hasMore) return;
    final id = ++_requestId;
    emit(state.copyWith(loadingMore: true));
    try {
      final page = await _repository.fetchMine(
        q: state.query,
        limit: _pageSize,
        offset: state.recipes.length,
        sort: state.sort,
      );
      if (id != _requestId) return;
      emit(state.copyWith(
        recipes: [...state.recipes, ...page],
        loadingMore: false,
        hasMore: page.length == _pageSize,
      ));
    } on RecipesRepositoryException {
      // Échec silencieux du « charger plus » : réessayé au prochain scroll.
      if (id != _requestId) return;
      emit(state.copyWith(loadingMore: false));
    }
  }
}

class AllRecipesState extends Equatable {
  const AllRecipesState({
    this.recipes = const [],
    this.query = '',
    this.loading = false,
    this.loadingMore = false,
    this.hasMore = true,
    this.error,
    this.loadedOnce = false,
    this.sort = RecipeSort.recent,
  });

  final List<RecipeSummary> recipes;
  final String query;
  final bool loading;
  final bool loadingMore;
  final bool hasMore;
  final String? error;
  final RecipeSort sort;

  /// Au moins une page chargée avec succès (évite le spinner plein écran lors
  /// des filtrages suivants).
  final bool loadedOnce;

  AllRecipesState copyWith({
    List<RecipeSummary>? recipes,
    String? query,
    bool? loading,
    bool? loadingMore,
    bool? hasMore,
    String? error,
    RecipeSort? sort,
  }) {
    return AllRecipesState(
      recipes: recipes ?? this.recipes,
      query: query ?? this.query,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      loadedOnce: loadedOnce || recipes != null,
      sort: sort ?? this.sort,
    );
  }

  @override
  List<Object?> get props =>
      [recipes, query, loading, loadingMore, hasMore, error, loadedOnce, sort];
}
