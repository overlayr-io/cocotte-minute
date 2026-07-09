import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../categories/data/categories_repository.dart';
import '../../../categories/domain/category.dart';
import '../../../people/data/people_repository.dart';
import '../../../people/domain/person.dart';
import '../../../recipes/domain/recipe.dart';
import '../../../tags/data/tags_repository.dart';
import '../../../tags/domain/tag.dart';
import '../../data/search_repository.dart';
import '../../domain/search_token.dart';

part 'search_state.dart';

/// Pilote la recherche avancée « à la Notion » : une barre unique où l'on tape
/// `/` (dossier), `#` (tag) ou `@` (personne) pour ouvrir un menu, chaque choix
/// devenant une pastille cumulée en ET. Le texte libre (sans préfixe) filtre le
/// nom. Les données d'autocomplétion (dossiers/tags/personnes du compte) sont
/// chargées une fois ; la recherche est débouncée sur le texte, immédiate sur
/// un changement de pastille.
class SearchCubit extends Cubit<SearchState> {
  SearchCubit({
    required SearchRepository searchRepository,
    required CategoriesRepository categoriesRepository,
    required TagsRepository tagsRepository,
    required PeopleRepository peopleRepository,
    required bool Function() isPremium,
  }) : _search = searchRepository,
       _categories = categoriesRepository,
       _tags = tagsRepository,
       _people = peopleRepository,
       _isPremium = isPremium,
       super(const SearchState());

  final SearchRepository _search;
  final CategoriesRepository _categories;
  final TagsRepository _tags;
  final PeopleRepository _people;

  /// Statut premium au moment de l'action (gating d'affichage uniquement :
  /// le serveur applique de toute façon le plafond côté API).
  final bool Function() _isPremium;

  /// Vrai si le plafond gratuit de critères s'applique (indicateur « X/6 »).
  bool get isLimited => !_isPremium();

  Timer? _debounce;

  static const Duration _debounceDelay = Duration(milliseconds: 500);

  /// Charge l'autocomplétion (dossiers + tags + personnes du compte) en une
  /// passe. Échec = blocage de l'écran (les menus en dépendent) → statut error
  /// avec retry.
  Future<void> init() async {
    emit(state.copyWith(referenceStatus: SearchStatus.loading));
    try {
      final results = await Future.wait([
        _categories.fetchMine(),
        _tags.fetchMine(),
        _people.fetchMine(),
      ]);
      emit(
        state.copyWith(
          referenceStatus: SearchStatus.success,
          allCategories: results[0] as List<Category>,
          allTags: results[1] as List<Tag>,
          allPeople: results[2] as List<Person>,
        ),
      );
    } on CategoriesRepositoryException catch (e) {
      emit(state.copyWith(
        referenceStatus: SearchStatus.failure,
        errorMessage: e.message,
      ));
    } on TagsRepositoryException catch (e) {
      emit(state.copyWith(
        referenceStatus: SearchStatus.failure,
        errorMessage: e.message,
      ));
    } on PeopleRepositoryException catch (e) {
      emit(state.copyWith(
        referenceStatus: SearchStatus.failure,
        errorMessage: e.message,
      ));
    }
  }

  /// Réagit à chaque frappe dans la barre. Un texte préfixé par `/`, `#` ou `@`
  /// ouvre le menu correspondant (le reste sert de filtre d'autocomplétion) ;
  /// sinon c'est le texte libre de recherche par nom (débouncé).
  void queryChanged(String text) {
    final dimension = text.isNotEmpty
        ? SearchDimension.fromTrigger(text[0])
        : null;
    if (dimension != null) {
      // Mode menu : on ne relance pas la recherche pendant la saisie du critère.
      emit(state.copyWith(
        rawInput: text,
        openMenu: dimension,
        menuQuery: text.substring(1),
      ));
      return;
    }
    // Texte libre → filtre nom, menu fermé.
    emit(state.copyWith(rawInput: text, clearMenu: true));
    _scheduleSearch();
  }

  /// Ouvre un menu depuis les trois boutons déclencheurs (sans frappe). Pré-remplit
  /// la barre avec le caractère déclencheur.
  void openMenu(SearchDimension dimension) {
    emit(state.copyWith(
      rawInput: dimension.trigger,
      openMenu: dimension,
      menuQuery: '',
    ));
  }

  void addFolder(Category category) => _addToken(FolderToken(category));

  void addTag(Tag tag) => _addToken(TagToken(tag));

  void addPerson(Person person) => _addToken(PersonToken(person));

  /// Crée un tag à la volée (menu `#`, ligne « Créer le tag ») puis l'ajoute
  /// comme pastille. En cas d'échec, remonte un message non bloquant (snackbar).
  /// Le plafond gratuit est vérifié AVANT la création serveur du tag.
  Future<void> createAndAddTag(String name) async {
    if (_blockIfLimitReached()) return;
    try {
      final tag = await _tags.create(name: name, color: _defaultTagColor);
      emit(state.copyWith(allTags: [...state.allTags, tag]));
      _addToken(TagToken(tag));
    } on TagsRepositoryException catch (e) {
      emit(state.copyWith(actionMessage: e.message));
    }
  }

  void removeToken(SearchToken token) {
    emit(state.copyWith(
      tokens: state.tokens.where((t) => t != token).toList(),
    ));
    _runSearchOrReset();
  }

  /// « Tout effacer » : retire toutes les pastilles et le texte, revient à l'état
  /// initial (aucun résultat affiché).
  void clearAll() {
    _debounce?.cancel();
    emit(state.copyWith(
      tokens: const [],
      rawInput: '',
      clearMenu: true,
      resultsStatus: SearchStatus.initial,
      results: const [],
    ));
  }

  void _addToken(SearchToken token) {
    if (state.tokens.any((t) => t == token)) {
      // Déjà présent : on referme juste le menu et on vide la saisie.
      emit(state.copyWith(rawInput: '', clearMenu: true));
      return;
    }
    if (_blockIfLimitReached()) return;
    emit(state.copyWith(
      tokens: [...state.tokens, token],
      rawInput: '',
      clearMenu: true,
    ));
    _runSearch();
  }

  /// Plafond gratuit : au-delà de [SearchState.freeCriteriaLimit] critères
  /// cumulés (pastilles + texte libre), on refuse l'ajout et on signale à la
  /// page d'ouvrir la feuille d'upsell (tick incrémenté à chaque tentative).
  /// Aucun plafond pour un utilisateur premium.
  bool _blockIfLimitReached() {
    if (_isPremium()) return false;
    if (state.criteriaCount < SearchState.freeCriteriaLimit) return false;
    emit(state.copyWith(limitBlockTick: state.limitBlockTick + 1));
    return true;
  }

  void _scheduleSearch() {
    _debounce?.cancel();
    _debounce = Timer(_debounceDelay, _runSearchOrReset);
  }

  void _runSearchOrReset() {
    if (state.tokens.isEmpty && state.nameQuery.isEmpty) {
      emit(state.copyWith(
        resultsStatus: SearchStatus.initial,
        results: const [],
      ));
      return;
    }
    _runSearch();
  }

  Future<void> _runSearch() async {
    _debounce?.cancel();
    final tokens = state.tokens;
    final nameQuery = state.nameQuery;
    if (tokens.isEmpty && nameQuery.isEmpty) return;

    emit(state.copyWith(resultsStatus: SearchStatus.loading));
    try {
      final results = await _search.search(
        query: nameQuery.isEmpty ? null : nameQuery,
        categoryIds: tokens.whereType<FolderToken>().map((t) => t.id).toList(),
        tagIds: tokens.whereType<TagToken>().map((t) => t.id).toList(),
        personIds: tokens.whereType<PersonToken>().map((t) => t.id).toList(),
      );
      emit(state.copyWith(
        resultsStatus: SearchStatus.success,
        results: results,
      ));
    } on SearchRepositoryException catch (e) {
      // Défense en profondeur : si le serveur refuse pour cause de plafond
      // (403 PREMIUM_LIMIT_SEARCH_CRITERIA), on ouvre l'upsell même si l'état
      // local croyait être premium.
      if (e.premiumLimit != null) {
        emit(state.copyWith(
          resultsStatus: SearchStatus.failure,
          limitBlockTick: state.limitBlockTick + 1,
        ));
        return;
      }
      emit(state.copyWith(
        resultsStatus: SearchStatus.failure,
        actionMessage: e.message,
      ));
    }
  }

  /// Couleur par défaut d'un tag créé à la volée (première de la palette fermée,
  /// miroir de `TagColors.options.first`).
  static const String _defaultTagColor = '#3F7D3A';

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
