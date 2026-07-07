part of 'people_list_bloc.dart';

sealed class PeopleListEvent extends Equatable {
  const PeopleListEvent();

  @override
  List<Object?> get props => const [];
}

/// Charge (ou recharge) la liste des personnes.
class PeopleRequested extends PeopleListEvent {
  const PeopleRequested();
}

/// Création d'une personne (sans tags — associés ensuite en édition).
class PersonCreated extends PeopleListEvent {
  const PersonCreated({required this.firstName, this.lastName});

  final String firstName;
  final String? lastName;

  @override
  List<Object?> get props => [firstName, lastName];
}
