part of 'tags_list_bloc.dart';

sealed class TagsListEvent extends Equatable {
  const TagsListEvent();

  @override
  List<Object?> get props => const [];
}

/// Charge (ou recharge) la liste des tags.
class TagsRequested extends TagsListEvent {
  const TagsRequested();
}

/// Création d'un tag.
class TagCreated extends TagsListEvent {
  const TagCreated({required this.name, required this.color});

  final String name;
  final String color;

  @override
  List<Object?> get props => [name, color];
}

/// Édition d'un tag (renommer / recolorer).
class TagUpdated extends TagsListEvent {
  const TagUpdated({required this.id, required this.name, required this.color});

  final String id;
  final String name;
  final String color;

  @override
  List<Object?> get props => [id, name, color];
}

/// Soft-delete d'un tag.
class TagDeleted extends TagsListEvent {
  const TagDeleted(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
