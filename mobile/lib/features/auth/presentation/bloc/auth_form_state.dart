part of 'auth_form_bloc.dart';

sealed class AuthFormState extends Equatable {
  const AuthFormState();

  @override
  List<Object?> get props => const [];
}

/// Aucun traitement en cours.
class AuthFormInitial extends AuthFormState {
  const AuthFormInitial();
}

/// Action en cours (création, connexion, OAuth, reset) → bouton en chargement.
class AuthFormSubmitting extends AuthFormState {
  const AuthFormSubmitting();
}

/// Compte prêt (créé/converti ou connecté).
///
/// [wasGuest] indique que l'utilisateur était invité et que ses données ont
/// été rattachées → l'écran doit proposer la modal "conserver / repartir".
class AuthFormAccountReady extends AuthFormState {
  const AuthFormAccountReady({required this.wasGuest});

  final bool wasGuest;

  @override
  List<Object?> get props => [wasGuest];
}

/// Données invité effacées ("repartir de zéro") → on peut fermer la modal.
class AuthFormGuestDataReset extends AuthFormState {
  const AuthFormGuestDataReset();
}

/// Échec non bloquant → message à afficher en snackbar (cf. contraintes).
class AuthFormFailure extends AuthFormState {
  const AuthFormFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
