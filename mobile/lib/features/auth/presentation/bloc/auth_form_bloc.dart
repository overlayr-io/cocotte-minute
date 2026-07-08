import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show OAuthProvider;

import '../../data/auth_repository.dart';

part 'auth_form_event.dart';
part 'auth_form_state.dart';

/// Bloc de la feature auth : pilote les actions du formulaire de
/// connexion/inscription et la réinitialisation des données invité.
///
/// Distinct de l'`AuthBloc` global (core/), qui ne gère que la **session**.
/// Ici on gère l'**action** en cours (Submitting / Success / Failure).
class AuthFormBloc extends Bloc<AuthFormEvent, AuthFormState> {
  AuthFormBloc({required AuthRepository repository})
    : _repository = repository,
      super(const AuthFormInitial()) {
    on<AuthFormAccountCreationRequested>(_onCreateAccount);
    on<AuthFormSignInRequested>(_onSignIn);
    on<AuthFormOAuthRequested>(_onOAuth);
    on<AuthFormGuestDataResetRequested>(_onGuestDataReset);
  }

  final AuthRepository _repository;

  Future<void> _onCreateAccount(
    AuthFormAccountCreationRequested event,
    Emitter<AuthFormState> emit,
  ) async {
    emit(const AuthFormSubmitting());
    // Capturé AVANT conversion : si l'utilisateur était invité, ses données
    // existantes viennent d'être rattachées → on proposera la modal 1c.
    final wasGuest = _repository.isAnonymous;
    try {
      await _repository.createAccountWithEmail(
        email: event.email,
        password: event.password,
      );
      emit(AuthFormAccountReady(wasGuest: wasGuest));
    } on AuthRepositoryException catch (e) {
      emit(AuthFormFailure(e.message));
    }
  }

  Future<void> _onSignIn(
    AuthFormSignInRequested event,
    Emitter<AuthFormState> emit,
  ) async {
    emit(const AuthFormSubmitting());
    try {
      await _repository.signInWithEmail(
        email: event.email,
        password: event.password,
      );
      // Connexion à un compte existant : pas de données invité à proposer.
      emit(const AuthFormAccountReady(wasGuest: false));
    } on AuthRepositoryException catch (e) {
      emit(AuthFormFailure(e.message));
    }
  }

  Future<void> _onOAuth(
    AuthFormOAuthRequested event,
    Emitter<AuthFormState> emit,
  ) async {
    emit(const AuthFormSubmitting());
    try {
      await _repository.continueWithOAuth(event.provider);
      // Le flux OAuth se poursuit via redirection ; la session résultante est
      // prise en charge par l'AuthBloc global. On relâche l'état de soumission.
      emit(const AuthFormInitial());
    } on AuthRepositoryException catch (e) {
      emit(AuthFormFailure(e.message));
    }
  }

  Future<void> _onGuestDataReset(
    AuthFormGuestDataResetRequested event,
    Emitter<AuthFormState> emit,
  ) async {
    emit(const AuthFormSubmitting());
    try {
      await _repository.resetGuestData();
      emit(const AuthFormGuestDataReset());
    } on AuthRepositoryException catch (e) {
      emit(AuthFormFailure(e.message));
    }
  }
}
