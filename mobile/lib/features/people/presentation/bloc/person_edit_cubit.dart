import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

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
    this.saving = false,
    this.message,
    this.outcome = PersonEditOutcome.none,
  });

  final Person person;
  final List<Tag> allTags;
  final bool tagsLoading;
  final Set<String> busyTagIds;
  final bool saving;

  /// Message d'échec transitoire (snackbar), consommé puis remis à null.
  final String? message;
  final PersonEditOutcome outcome;

  PersonEditState copyWith({
    Person? person,
    List<Tag>? allTags,
    bool? tagsLoading,
    Set<String>? busyTagIds,
    bool? saving,
    String? message,
    PersonEditOutcome? outcome,
  }) {
    return PersonEditState(
      person: person ?? this.person,
      allTags: allTags ?? this.allTags,
      tagsLoading: tagsLoading ?? this.tagsLoading,
      busyTagIds: busyTagIds ?? this.busyTagIds,
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

  Future<void> save({required String firstName, String? lastName}) async {
    emit(state.copyWith(saving: true));
    try {
      final updated = await _people.update(
        state.person.id,
        firstName: firstName,
        lastName: lastName,
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
