part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => const [];
}

/// État initial, avant toute résolution de session.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Résolution de session en cours (création du compte anonyme, etc.).
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Session valide (utilisateur anonyme OU complet).
class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({required this.user});

  final User user;

  bool get isAnonymous => user.isAnonymous;

  @override
  List<Object?> get props => [user.id, user.isAnonymous];
}

/// Aucune session (ex: après déconnexion explicite).
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Échec bloquant de résolution de session → page d'erreur + retry.
class AuthFailure extends AuthState {
  const AuthFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
