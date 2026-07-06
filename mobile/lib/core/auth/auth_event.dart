part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => const [];
}

/// Émis au démarrage : vérifie la session, crée un compte anonyme si besoin.
class AuthStarted extends AuthEvent {
  const AuthStarted();
}

/// Émis en interne quand Supabase notifie un changement de session.
class AuthSessionChanged extends AuthEvent {
  const AuthSessionChanged(this.session);

  final Session? session;

  @override
  List<Object?> get props => [session?.accessToken];
}

/// Déconnexion explicite.
class AuthSignedOut extends AuthEvent {
  const AuthSignedOut();
}
