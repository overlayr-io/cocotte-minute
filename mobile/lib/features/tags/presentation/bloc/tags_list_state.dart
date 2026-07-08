part of 'tags_list_bloc.dart';

sealed class TagsListState extends Equatable {
  const TagsListState();

  @override
  List<Object?> get props => const [];
}

class TagsListInitial extends TagsListState {
  const TagsListInitial();
}

class TagsListLoading extends TagsListState {
  const TagsListLoading();
}

/// Liste chargée. `busyId` = tag en cours d'action (édition/suppression), pour
/// afficher un état de chargement sur la ligne concernée.
class TagsListLoaded extends TagsListState {
  const TagsListLoaded({required this.tags, this.busyId});

  final List<Tag> tags;
  final String? busyId;

  TagsListLoaded copyWith({List<Tag>? tags, String? busyId}) {
    return TagsListLoaded(tags: tags ?? this.tags, busyId: busyId);
  }

  @override
  List<Object?> get props => [tags, busyId];
}

/// Échec transitoire d'une action : les données restent affichées, un message
/// est remonté pour une snackbar.
class TagsListActionFailure extends TagsListLoaded {
  const TagsListActionFailure({required super.tags, required this.message});

  final String message;

  @override
  List<Object?> get props => [tags, message];
}

/// Échec bloquant du chargement initial → page d'erreur + retry.
class TagsListError extends TagsListState {
  const TagsListError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
