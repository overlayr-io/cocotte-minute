import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/people_repository.dart';
import '../../domain/person.dart';

part 'people_list_event.dart';
part 'people_list_state.dart';

/// Bloc de l'écran "Famille" : liste des personnes + création. L'édition et la
/// suppression se font sur la page d'édition ; la liste est rechargée au retour.
class PeopleListBloc extends Bloc<PeopleListEvent, PeopleListState> {
  PeopleListBloc({required PeopleRepository repository})
    : _repository = repository,
      super(const PeopleListInitial()) {
    on<PeopleRequested>(_onRequested);
    on<PersonCreated>(_onCreated);
  }

  final PeopleRepository _repository;

  Future<void> _onRequested(
    PeopleRequested event,
    Emitter<PeopleListState> emit,
  ) async {
    emit(const PeopleListLoading());
    try {
      final people = await _repository.fetchMine();
      emit(PeopleListLoaded(people: people));
    } on PeopleRepositoryException catch (e) {
      emit(PeopleListError(e.message));
    }
  }

  Future<void> _onCreated(
    PersonCreated event,
    Emitter<PeopleListState> emit,
  ) async {
    final current = state;
    if (current is! PeopleListLoaded) return;
    try {
      await _repository.create(
        firstName: event.firstName,
        lastName: event.lastName,
      );
      emit(PeopleListLoaded(people: await _repository.fetchMine()));
    } on PeopleRepositoryException catch (e) {
      emit(PeopleListActionFailure(people: current.people, message: e.message));
    }
  }
}
