part of 'account_status_cubit.dart';

sealed class AccountStatusState extends Equatable {
  const AccountStatusState();

  @override
  List<Object?> get props => const [];
}

/// Aucune bannière à afficher (compte actif, statut inconnu, ou après annulation).
class AccountStatusHidden extends AccountStatusState {
  const AccountStatusHidden();
}

/// Suppression en attente : la bannière d'annulation est affichée.
/// [cancelling] passe à `true` pendant l'appel `cancel-deletion`.
class AccountStatusPending extends AccountStatusState {
  const AccountStatusPending({
    this.deletionScheduledAt,
    this.cancelling = false,
  });

  final DateTime? deletionScheduledAt;
  final bool cancelling;

  AccountStatusPending copyWith({bool? cancelling}) => AccountStatusPending(
    deletionScheduledAt: deletionScheduledAt,
    cancelling: cancelling ?? this.cancelling,
  );

  @override
  List<Object?> get props => [deletionScheduledAt, cancelling];
}

/// Annulation réussie → snackbar de confirmation, puis la bannière disparaît.
class AccountStatusCancelSuccess extends AccountStatusState {
  const AccountStatusCancelSuccess();
}

/// Échec d'annulation non bloquant → message à afficher en snackbar.
class AccountStatusCancelFailure extends AccountStatusState {
  const AccountStatusCancelFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
