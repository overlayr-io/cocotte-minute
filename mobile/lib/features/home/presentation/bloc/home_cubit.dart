import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../categories/data/categories_repository.dart';
import '../../../categories/domain/category.dart';
import '../../../recipes/domain/recipe.dart';
import '../../data/discovery_repository.dart';
import '../../domain/discovery.dart';

/// Nature d'une rangée Découverte (le titre localisé est résolu côté UI).
enum DiscoverySectionKind { seasonal, quick, recent, person, base, large, solo }

/// Une rangée horizontale de la vue Découverte.
class DiscoverySection extends Equatable {
  const DiscoverySection({
    required this.kind,
    required this.recipes,
    this.personName,
    this.avatarUrl,
  });

  final DiscoverySectionKind kind;
  final List<RecipeSummary> recipes;

  /// Pour les rangées `person` : prénom + avatar affichés dans le titre.
  final String? personName;
  final String? avatarUrl;

  @override
  List<Object?> get props => [kind, recipes, personName, avatarUrl];
}

/// État de la page d'accueil (flux Découverte).
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

/// Accueil Découverte : hero « à la une » + rangées éditoriales + chips dossiers.
class HomeLoaded extends HomeState {
  const HomeLoaded({
    required this.hero,
    required this.heroSeasonal,
    required this.month,
    required this.sections,
    required this.categories,
  });

  /// Recette mise en avant, ou null si le compte n'a aucune recette.
  final RecipeSummary? hero;
  final bool heroSeasonal;

  /// Mois courant (1..12), pour le titre « De saison en {mois} ».
  final int month;

  final List<DiscoverySection> sections;

  /// Catégories racines pour les chips (« Tout » ajouté côté UI).
  final List<Category> categories;

  bool get isEmpty => hero == null;

  @override
  List<Object?> get props => [hero, heroSeasonal, month, sections, categories];
}

/// Charge l'Accueil Découverte : données enrichies (`/discovery/home`) + dossiers
/// (pour les chips avec icônes), puis compose un maximum de rangées. Une rangée
/// n'est construite que si elle a assez de recettes ([_minRow]).
class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    required DiscoveryRepository discoveryRepository,
    required CategoriesRepository categoriesRepository,
  }) : _discovery = discoveryRepository,
       _categories = categoriesRepository,
       super(const HomeLoading());

  final DiscoveryRepository _discovery;
  final CategoriesRepository _categories;

  /// Nombre minimum de recettes pour afficher une rangée (évite les rangées
  /// faméliques à une seule carte).
  static const _minRow = 2;

  /// Plafond de cartes par rangée.
  static const _rowCap = 12;

  /// Plafond spécifique à la rangée « Recettes de base » (point 2 du backlog).
  static const _baseRowCap = 5;

  Future<void> load() async {
    // Ne montre le spinner plein écran qu'au premier chargement : un refresh
    // (ex. retour d'une fiche recette) ne doit pas effacer le flux déjà affiché.
    if (state is! HomeLoaded) {
      emit(const HomeLoading());
    }
    try {
      final results = await Future.wait([
        _discovery.fetchHome(),
        _categories.fetchMine(),
      ]);
      final data = results[0] as DiscoveryData;
      final categories = results[1] as List<Category>;

      emit(_compose(data, categories));
    } on DiscoveryRepositoryException catch (e) {
      emit(HomeError(e.message));
    } on CategoriesRepositoryException catch (e) {
      emit(HomeError(e.message));
    }
  }

  HomeLoaded _compose(DiscoveryData data, List<Category> categories) {
    final all = data.recipes;
    final roots = categories.where((c) => c.isRoot).toList(growable: false);

    if (all.isEmpty) {
      return HomeLoaded(
        hero: null,
        heroSeasonal: false,
        month: data.month,
        sections: const [],
        categories: roots,
      );
    }

    // Recettes « éditoriales » = hors recettes de base (briques réutilisables).
    final editorial = all.where((r) => !r.summary.isBase).toList();
    final pool = editorial.isNotEmpty ? editorial : all;

    // Hero : la première recette de saison si possible, sinon la plus récente.
    final DiscoveryRecipe heroRecipe = pool.firstWhere(
      (r) => r.seasonal,
      orElse: () => pool.first,
    );

    final sections = <DiscoverySection>[];

    void addRow(
      DiscoverySectionKind kind,
      Iterable<DiscoveryRecipe> matches, {
      String? personName,
      String? avatarUrl,
      int cap = _rowCap,
    }) {
      final recipes = matches
          .map((r) => r.summary)
          .take(cap)
          .toList(growable: false);
      if (recipes.length >= _minRow) {
        sections.add(DiscoverySection(
          kind: kind,
          recipes: recipes,
          personName: personName,
          avatarUrl: avatarUrl,
        ));
      }
    }

    addRow(DiscoverySectionKind.seasonal, editorial.where((r) => r.seasonal));
    addRow(
      DiscoverySectionKind.quick,
      editorial.where((r) {
        final total = r.summary.prepTime + r.summary.cookTime;
        return total > 0 && total <= 30;
      }),
    );
    addRow(DiscoverySectionKind.recent, editorial);
    for (final person in data.people) {
      // « Pour {prénom} » : recettes associées directement OU portant un des
      // tags de la personne.
      if (person.tagIds.isEmpty && person.recipeIds.isEmpty) continue;
      final tagSet = person.tagIds.toSet();
      final directSet = person.recipeIds.toSet();
      addRow(
        DiscoverySectionKind.person,
        editorial.where(
          (r) =>
              directSet.contains(r.summary.id) || r.tagIds.any(tagSet.contains),
        ),
        personName: person.firstName,
        avatarUrl: person.avatarUrl,
      );
    }
    addRow(
      DiscoverySectionKind.base,
      all.where((r) => r.summary.isBase),
      cap: _baseRowCap,
    );
    addRow(
      DiscoverySectionKind.large,
      editorial.where((r) => r.summary.servings >= 6),
    );
    addRow(
      DiscoverySectionKind.solo,
      editorial.where((r) => r.summary.servings <= 2),
    );

    return HomeLoaded(
      hero: heroRecipe.summary,
      heroSeasonal: heroRecipe.seasonal,
      month: data.month,
      sections: sections,
      categories: roots,
    );
  }
}
