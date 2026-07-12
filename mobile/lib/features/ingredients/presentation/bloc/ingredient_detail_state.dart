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
/// `price` : prix de l'utilisateur pour cet ingrédient, `null` si non renseigné.
class IngredientDetailLoaded extends IngredientDetailState {
  const IngredientDetailLoaded({
    required this.detail,
    required this.price,
    this.mutating = false,
  });

  final IngredientDetail detail;
  final IngredientPrice? price;
  final bool mutating;

  IngredientDetailLoaded copyWith({
    IngredientDetail? detail,
    IngredientPrice? price,
    bool? mutating,
  }) {
    return IngredientDetailLoaded(
      detail: detail ?? this.detail,
      price: price ?? this.price,
      mutating: mutating ?? this.mutating,
    );
  }

  @override
  List<Object?> get props => [detail, price, mutating];
}

/// Échec transitoire d'une action : données conservées + message pour snackbar.
class IngredientDetailActionFailure extends IngredientDetailLoaded {
  const IngredientDetailActionFailure({
    required super.detail,
    required super.price,
    required this.message,
  });

  final String message;

  @override
  List<Object?> get props => [detail, price, message];
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
