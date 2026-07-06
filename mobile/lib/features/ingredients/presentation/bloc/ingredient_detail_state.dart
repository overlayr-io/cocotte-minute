part of 'ingredient_detail_bloc.dart';

sealed class IngredientDetailState extends Equatable {
  const IngredientDetailState();

  @override
  List<Object?> get props => const [];
}

class IngredientDetailLoading extends IngredientDetailState {
  const IngredientDetailLoading();
}

/// Détail chargé. `mutating` = une action (save/alternatives) est en cours.
class IngredientDetailLoaded extends IngredientDetailState {
  const IngredientDetailLoaded({required this.detail, this.mutating = false});

  final IngredientDetail detail;
  final bool mutating;

  IngredientDetailLoaded copyWith({IngredientDetail? detail, bool? mutating}) {
    return IngredientDetailLoaded(
      detail: detail ?? this.detail,
      mutating: mutating ?? this.mutating,
    );
  }

  @override
  List<Object?> get props => [detail, mutating];
}

/// Échec transitoire d'une action : données conservées + message pour snackbar.
class IngredientDetailActionFailure extends IngredientDetailLoaded {
  const IngredientDetailActionFailure({
    required super.detail,
    required this.message,
  });

  final String message;

  @override
  List<Object?> get props => [detail, message];
}

/// Échec bloquant du chargement → page d'erreur + retry.
class IngredientDetailError extends IngredientDetailState {
  const IngredientDetailError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Enregistrement réussi → la page se referme.
class IngredientDetailSaved extends IngredientDetailState {
  const IngredientDetailSaved();
}

/// Suppression réussie → la page se referme et la liste se rafraîchit.
class IngredientDetailDeleted extends IngredientDetailState {
  const IngredientDetailDeleted();
}
