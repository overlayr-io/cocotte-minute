part of 'ingredients_list_bloc.dart';

sealed class IngredientsListState extends Equatable {
  const IngredientsListState();

  @override
  List<Object?> get props => const [];
}

class IngredientsListInitial extends IngredientsListState {
  const IngredientsListInitial();
}

class IngredientsListLoading extends IngredientsListState {
  const IngredientsListLoading();
}

/// Listes chargées. `busyId` = ingrédient en cours d'action (import/suppression),
/// pour afficher un état de chargement sur la ligne concernée.
class IngredientsListLoaded extends IngredientsListState {
  const IngredientsListLoaded({
    required this.mine,
    required this.system,
    this.busyId,
  });

  final List<Ingredient> mine;
  final List<Ingredient> system;
  final String? busyId;

  IngredientsListLoaded copyWith({
    List<Ingredient>? mine,
    List<Ingredient>? system,
    String? busyId,
  }) {
    return IngredientsListLoaded(
      mine: mine ?? this.mine,
      system: system ?? this.system,
      busyId: busyId,
    );
  }

  @override
  List<Object?> get props => [mine, system, busyId];
}

/// Échec transitoire d'une action (import/suppression) : les données restent
/// affichées, un message est remonté pour une snackbar.
class IngredientsListActionFailure extends IngredientsListLoaded {
  const IngredientsListActionFailure({
    required super.mine,
    required super.system,
    required this.message,
  });

  final String message;

  @override
  List<Object?> get props => [mine, system, message];
}

/// Échec bloquant du chargement initial → page d'erreur + retry.
class IngredientsListError extends IngredientsListState {
  const IngredientsListError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
