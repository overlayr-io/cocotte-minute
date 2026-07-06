part of 'auth_form_bloc.dart';

sealed class AuthFormEvent extends Equatable {
  const AuthFormEvent();

  @override
  List<Object?> get props => const [];
}

/// "Créer mon compte" (conversion du compte anonyme ou inscription).
class AuthFormAccountCreationRequested extends AuthFormEvent {
  const AuthFormAccountCreationRequested({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

/// "Se connecter" à un compte existant.
class AuthFormSignInRequested extends AuthFormEvent {
  const AuthFormSignInRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

/// "Continuer avec Google / Apple".
class AuthFormOAuthRequested extends AuthFormEvent {
  const AuthFormOAuthRequested(this.provider);

  final OAuthProvider provider;

  @override
  List<Object?> get props => [provider];
}

/// "Repartir de zéro" : efface les données invité après création du compte.
class AuthFormGuestDataResetRequested extends AuthFormEvent {
  const AuthFormGuestDataResetRequested();
}
