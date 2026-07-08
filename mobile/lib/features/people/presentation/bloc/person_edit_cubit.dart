import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../recipes/domain/recipe.dart';
import '../../../tags/data/tags_repository.dart';
import '../../../tags/domain/tag.dart';
import '../../data/people_repository.dart';
import '../../domain/person.dart';

/// Issue de la page d'édition, pour piloter la fermeture côté UI.
enum PersonEditOutcome { none, saved, deleted }

class PersonEditState extends Equatable {
  const PersonEditState({
    required this.person,
    this.allTags = const [],
    this.tagsLoading = true,
    this.busyTagIds = const {},
    this.recipes = const [],
    this.recipesLoading = true,
    this.recipesBusy = false,
    this.saving = false,
    this.message,
    this.outcome = PersonEditOutcome.none,
  });

  final Person person;
  final List<Tag> allTags;
  final bool tagsLoading;
  final Set<String> busyTagIds;

  /// « Ses recettes » : recettes associées directement à la personne.
  final List<RecipeSummary> recipes;
  final bool recipesLoading;

  /// Mutation d'association de recettes en cours (ajout multiple ou retrait).
  final bool recipesBusy;

  final bool saving;

  /// Message d'échec transitoire (snackbar), consommé puis remis à null.
  final String? message;
  final PersonEditOutcome outcome;

  PersonEditState copyWith({
    Person? person,
    List<Tag>? allTags,
    bool? tagsLoading,
    Set<String>? busyTagIds,
    List<RecipeSummary>? recipes,
    bool? recipesLoading,
    bool? recipesBusy,
    bool? saving,
    String? message,
    PersonEditOutcome? outcome,
  }) {
    return PersonEditState(
      person: person ?? this.person,
      allTags: allTags ?? this.allTags,
      tagsLoading: tagsLoading ?? this.tagsLoading,
      busyTagIds: busyTagIds ?? this.busyTagIds,
      recipes: recipes ?? this.recipes,
      recipesLoading: recipesLoading ?? this.recipesLoading,
      recipesBusy: recipesBusy ?? this.recipesBusy,
      saving: saving ?? this.saving,
      message: message,
      outcome: outcome ?? this.outcome,
    );
  }

  @override
  List<Object?> get props => [
    person,
    allTags,
    tagsLoading,
    busyTagIds,
    recipes,
    recipesLoading,
    recipesBusy,
    saving,
    message,
    outcome,
  ];
}

/// Cubit de la page d'édition d'une personne : chargement des tags du compte,
/// association / dissociation (toggle immédiat), enregistrement du prénom/nom et
/// suppression.
class PersonEditCubit extends Cubit<PersonEditState> {
  PersonEditCubit({
    required PeopleRepository peopleRepository,
    required TagsRepository tagsRepository,
    required Person person,
  }) : _people = peopleRepository,
       _tags = tagsRepository,
       super(PersonEditState(person: person));

  final PeopleRepository _people;
  final TagsRepository _tags;

  /// Charge le catalogue de tags du compte pour proposer les toggles.
  Future<void> loadTags() async {
    emit(state.copyWith(tagsLoading: true));
    try {
      final tags = await _tags.fetchMine();
      emit(state.copyWith(allTags: tags, tagsLoading: false));
    } on TagsRepositoryException catch (e) {
      emit(state.copyWith(tagsLoading: false, message: e.message));
    }
  }

  /// Associe ou retire un tag selon son état courant sur la personne.
  Future<void> toggleTag(Tag tag) async {
    if (state.busyTagIds.contains(tag.id)) return;
    emit(state.copyWith(busyTagIds: {...state.busyTagIds, tag.id}));
    try {
      final updated = state.person.hasTag(tag.id)
          ? await _people.removeTag(state.person.id, tag.id)
          : await _people.addTag(state.person.id, tag.id);
      emit(state.copyWith(
        person: updated,
        busyTagIds: {...state.busyTagIds}..remove(tag.id),
      ));
    } on PeopleRepositoryException catch (e) {
      emit(state.copyWith(
        busyTagIds: {...state.busyTagIds}..remove(tag.id),
        message: e.message,
      ));
    }
  }

  /// Charge « ses recettes » (associations directes personne↔recette).
  Future<void> loadRecipes() async {
    emit(state.copyWith(recipesLoading: true));
    try {
      final recipes = await _people.fetchRecipes(state.person.id);
      emit(state.copyWith(recipes: recipes, recipesLoading: false));
    } on PeopleRepositoryException catch (e) {
      emit(state.copyWith(recipesLoading: false, message: e.message));
    }
  }

  /// Associe un lot de recettes (sélection multiple), puis recharge la section.
  Future<void> addRecipes(List<String> recipeIds) async {
    if (recipeIds.isEmpty || state.recipesBusy) return;
    emit(state.copyWith(recipesBusy: true));
    try {
      Person person = state.person;
      for (final id in recipeIds) {
        person = await _people.addRecipe(person.id, id);
      }
      final recipes = await _people.fetchRecipes(person.id);
      emit(state.copyWith(
        person: person,
        recipes: recipes,
        recipesBusy: false,
      ));
    } on PeopleRepositoryException catch (e) {
      emit(state.copyWith(recipesBusy: false, message: e.message));
      await loadRecipes();
    }
  }

  /// Retire une recette de « ses recettes ».
  Future<void> removeRecipe(String recipeId) async {
    if (state.recipesBusy) return;
    emit(state.copyWith(recipesBusy: true));
    try {
      final person = await _people.removeRecipe(state.person.id, recipeId);
      emit(state.copyWith(
        person: person,
        recipes: state.recipes.where((r) => r.id != recipeId).toList(),
        recipesBusy: false,
      ));
    } on PeopleRepositoryException catch (e) {
      emit(state.copyWith(recipesBusy: false, message: e.message));
    }
  }

  Future<void> save({
    required String firstName,
    String? lastName,
    String? avatarUrl,
  }) async {
    emit(state.copyWith(saving: true));
    try {
      final updated = await _people.update(
        state.person.id,
        firstName: firstName,
        lastName: lastName,
        avatarUrl: avatarUrl,
      );
      emit(state.copyWith(
        person: updated,
        saving: false,
        outcome: PersonEditOutcome.saved,
      ));
    } on PeopleRepositoryException catch (e) {
      emit(state.copyWith(saving: false, message: e.message));
    }
  }

  Future<void> deletePerson() async {
    emit(state.copyWith(saving: true));
    try {
      await _people.delete(state.person.id);
      emit(state.copyWith(saving: false, outcome: PersonEditOutcome.deleted));
    } on PeopleRepositoryException catch (e) {
      emit(state.copyWith(saving: false, message: e.message));
    }
  }
}
