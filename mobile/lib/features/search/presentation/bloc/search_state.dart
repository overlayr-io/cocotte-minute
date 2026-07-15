part of 'search_cubit.dart';

/// Statut d'une zone asynchrone (chargement autocomplétion / résultats).
enum SearchStatus { initial, loading, success, failure }

/// État composite de l'écran de recherche : saisie courante, pastilles posées,
/// menu ouvert, données d'autocomplétion et résultats. Un seul état riche (plutôt
/// que des sous-classes) car l'écran combine plusieurs aspects simultanés — les
/// statuts explicites `referenceStatus`/`resultsStatus` distinguent
/// chargement/succès/échec de chaque zone.
class SearchState extends Equatable {
  const SearchState({
    this.rawInput = '',
    this.tokens = const [],
    this.openMenu,
    this.menuQuery = '',
    this.allCategories = const [],
    this.allTags = const [],
    this.allPeople = const [],
    this.referenceStatus = SearchStatus.initial,
    this.resultsStatus = SearchStatus.initial,
    this.results = const [],
    this.errorMessage,
    this.actionMessage,
    this.limitBlockTick = 0,
    this.sort = RecipeSort.recent,
  });

  /// Plafond de critères cumulés du plan gratuit (aligné sur le serveur,
  /// 403 `PREMIUM_LIMIT_SEARCH_CRITERIA` au-delà).
  static const int freeCriteriaLimit = 6;

  /// Contenu brut du champ (peut être un critère en cours `/#@…` ou du texte libre).
  final String rawInput;

  /// Pastilles posées (dossiers/tags/personnes), cumulées en ET.
  final List<SearchToken> tokens;

  /// Menu d'autocomplétion ouvert (null = aucun).
  final SearchDimension? openMenu;

  /// Filtre d'autocomplétion = texte après le caractère déclencheur.
  final String menuQuery;

  final List<Category> allCategories;
  final List<Tag> allTags;
  final List<Person> allPeople;

  /// Chargement de l'autocomplétion (bloquant : les menus en dépendent).
  final SearchStatus referenceStatus;

  /// Exécution de la recherche.
  final SearchStatus resultsStatus;
  final List<RecipeSummary> results;

  /// Tri appliqué aux résultats (client : la recherche n'est pas paginée).
  final RecipeSort sort;

  /// Résultats triés selon `sort` (`recent` conserve l'ordre serveur).
  List<RecipeSummary> get sortedResults => sortRecipeSummaries(results, sort);

  /// Message d'erreur bloquant (échec de chargement initial) → page d'erreur.
  final String? errorMessage;

  /// Message non bloquant transitoire (échec de recherche / création tag) → snackbar.
  final String? actionMessage;

  /// Incrémenté à chaque tentative d'ajout au-delà du plafond gratuit : la
  /// page écoute son changement pour ouvrir la feuille d'upsell (un simple
  /// booléen ne re-déclencherait pas sur deux tentatives successives).
  final int limitBlockTick;

  /// Texte libre de recherche par nom (vide tant qu'un critère `/#@` est en cours).
  String get nameQuery => openMenu != null ? '' : rawInput.trim();

  /// Nombre de critères cumulés au sens du plafond serveur : pastilles + le
  /// texte libre s'il est non vide.
  int get criteriaCount => tokens.length + (nameQuery.isEmpty ? 0 : 1);

  /// Champ « actif » (bordure verte) : saisie en cours ou menu ouvert.
  bool get isTyping => openMenu != null || rawInput.isNotEmpty;

  /// Aucun critère ni texte : écran d'accueil de la recherche (rien à afficher).
  bool get isIdle => tokens.isEmpty && nameQuery.isEmpty;

  bool _isSelected(SearchDimension dim, String id) =>
      tokens.any((t) => t.dimension == dim && t.id == id);

  /// Chemin lisible d'un dossier (« Parent / Enfant ») construit via l'arborescence.
  String categoryPath(Category category) {
    final byId = {for (final c in allCategories) c.id: c};
    final parts = <String>[category.name];
    var current = category;
    while (current.parentCategoryId != null) {
      final parent = byId[current.parentCategoryId];
      if (parent == null) break;
      parts.insert(0, parent.name);
      current = parent;
    }
    return parts.join(' / ');
  }

  /// Nombre de sous-dossiers directs (non filtrés) d'un dossier.
  int subfolderCount(String categoryId) =>
      allCategories.where((c) => c.parentCategoryId == categoryId).length;

  /// Dossiers candidats pour le menu `/` (filtrés, non déjà sélectionnés).
  /// Comparaison insensible aux accents (ex: "entree" retrouve "Entrée").
  List<Category> get folderCandidates {
    final q = foldForMatch(menuQuery.trim());
    return allCategories
        .where((c) => !_isSelected(SearchDimension.folder, c.id))
        .where((c) => q.trim().isEmpty || foldForMatch(categoryPath(c)).contains(q.trim()))
        .toList();
  }

  /// Tags candidats pour le menu `#`.
  List<Tag> get tagCandidates {
    final q = menuQuery.trim().toLowerCase();
    return allTags
        .where((t) => !_isSelected(SearchDimension.tag, t.id))
        .where((t) => q.isEmpty || t.name.toLowerCase().contains(q))
        .toList();
  }

  /// Personnes candidates pour le menu `@`.
  List<Person> get personCandidates {
    final q = menuQuery.trim().toLowerCase();
    return allPeople
        .where((p) => !_isSelected(SearchDimension.person, p.id))
        .where((p) => q.isEmpty || p.displayName.toLowerCase().contains(q))
        .toList();
  }

  /// Vrai s'il existe déjà un tag portant exactement le texte tapé (masque la
  /// ligne « Créer le tag »).
  bool get hasExactTagMatch {
    final q = menuQuery.trim().toLowerCase();
    return q.isEmpty || allTags.any((t) => t.name.toLowerCase() == q);
  }

  SearchState copyWith({
    String? rawInput,
    List<SearchToken>? tokens,
    SearchDimension? openMenu,
    bool clearMenu = false,
    String? menuQuery,
    List<Category>? allCategories,
    List<Tag>? allTags,
    List<Person>? allPeople,
    SearchStatus? referenceStatus,
    SearchStatus? resultsStatus,
    List<RecipeSummary>? results,
    String? errorMessage,
    String? actionMessage,
    int? limitBlockTick,
    RecipeSort? sort,
  }) {
    return SearchState(
      rawInput: rawInput ?? this.rawInput,
      tokens: tokens ?? this.tokens,
      openMenu: clearMenu ? null : (openMenu ?? this.openMenu),
      menuQuery: clearMenu ? '' : (menuQuery ?? this.menuQuery),
      allCategories: allCategories ?? this.allCategories,
      allTags: allTags ?? this.allTags,
      allPeople: allPeople ?? this.allPeople,
      referenceStatus: referenceStatus ?? this.referenceStatus,
      resultsStatus: resultsStatus ?? this.resultsStatus,
      results: results ?? this.results,
      errorMessage: errorMessage ?? this.errorMessage,
      actionMessage: actionMessage,
      limitBlockTick: limitBlockTick ?? this.limitBlockTick,
      sort: sort ?? this.sort,
    );
  }

  @override
  List<Object?> get props => [
        rawInput,
        tokens,
        openMenu,
        menuQuery,
        allCategories,
        allTags,
        allPeople,
        referenceStatus,
        resultsStatus,
        results,
        errorMessage,
        actionMessage,
        limitBlockTick,
        sort,
      ];
}
