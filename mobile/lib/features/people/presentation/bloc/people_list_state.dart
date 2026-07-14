part of 'people_list_bloc.dart';

sealed class PeopleListState extends Equatable {
  const PeopleListState();

  @override
  List<Object?> get props => const [];
}

class PeopleListInitial extends PeopleListState {
  const PeopleListInitial();
}

class PeopleListLoading extends PeopleListState {
  const PeopleListLoading();
}

class PeopleListLoaded extends PeopleListState {
  const PeopleListLoaded({required this.people, this.creating = false});

  final List<Person> people;

  /// Une création de personne est en cours (spinner sur le bouton d'ajout).
  final bool creating;

  @override
  List<Object?> get props => [people, creating];
}

/// Échec transitoire d'une action (création) : les données restent affichées,
/// un message est remonté pour une snackbar.
class PeopleListActionFailure extends PeopleListLoaded {
  const PeopleListActionFailure({required super.people, required this.message});

  final String message;

  @override
  List<Object?> get props => [people, message];
}

/// Échec bloquant du chargement initial → page d'erreur + retry.
class PeopleListError extends PeopleListState {
  const PeopleListError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
