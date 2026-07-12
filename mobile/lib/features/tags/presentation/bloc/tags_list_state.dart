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

/// Listes chargées. `busyId` = tag en cours d'action (édition/suppression/import),
/// pour afficher un état de chargement sur la ligne concernée.
class TagsListLoaded extends TagsListState {
  const TagsListLoaded({required this.mine, required this.system, this.busyId});

  final List<Tag> mine;
  final List<Tag> system;
  final String? busyId;

  TagsListLoaded copyWith({List<Tag>? mine, List<Tag>? system, String? busyId}) {
    return TagsListLoaded(
      mine: mine ?? this.mine,
      system: system ?? this.system,
      busyId: busyId,
    );
  }

  @override
  List<Object?> get props => [mine, system, busyId];
}

/// Échec transitoire d'une action : les données restent affichées, un message
/// est remonté pour une snackbar.
class TagsListActionFailure extends TagsListLoaded {
  const TagsListActionFailure({
    required super.mine,
    required super.system,
    required this.message,
  });

  final String message;

  @override
  List<Object?> get props => [mine, system, message];
}

/// Échec bloquant du chargement initial → page d'erreur + retry.
class TagsListError extends TagsListState {
  const TagsListError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
