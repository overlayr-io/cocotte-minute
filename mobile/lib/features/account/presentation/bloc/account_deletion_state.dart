part of 'account_deletion_cubit.dart';

sealed class AccountDeletionState extends Equatable {
  const AccountDeletionState();

  @override
  List<Object?> get props => const [];
}

/// Aucun traitement en cours (écran de confirmation affiché).
class AccountDeletionInitial extends AccountDeletionState {
  const AccountDeletionInitial();
}

/// Suppression en cours (appel serveur + action d'auth) → bouton en chargement.
class AccountDeletionInProgress extends AccountDeletionState {
  const AccountDeletionInProgress();
}

/// Compte invité supprimé : une session anonyme vierge a été recréée.
/// → retour à l'accueil vide (comme une première installation).
class AccountDeletionGuestRecreated extends AccountDeletionState {
  const AccountDeletionGuestRecreated();
}

/// Compte complet passé en `pending_deletion` : l'utilisateur a été déconnecté.
/// → retour à l'écran d'auth, annulation possible pendant 30 jours.
class AccountDeletionPending extends AccountDeletionState {
  const AccountDeletionPending({this.deletionScheduledAt});

  final DateTime? deletionScheduledAt;

  @override
  List<Object?> get props => [deletionScheduledAt];
}

/// Échec non bloquant → message à afficher en snackbar.
class AccountDeletionFailure extends AccountDeletionState {
  const AccountDeletionFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
