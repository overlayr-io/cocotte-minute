import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
// On masque `AuthState` de Supabase pour éviter la collision avec notre état.
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../config/env.dart';
import '../supabase/supabase_client.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Bloc d'authentification partagé (seul Bloc global autorisé, cf. CLAUDE.md).
///
/// Passe exclusivement par `supabase_flutter` : jamais de token refresh ni de
/// storage manuel, Supabase s'en charge.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(const AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<AuthSessionChanged>(_onSessionChanged);
    on<AuthSignedOut>(_onSignedOut);

    // Écoute les changements de session émis par Supabase (refresh, link, ...).
    if (Env.isConfigured) {
      _authSub = SupabaseService.auth.onAuthStateChange.listen((data) {
        add(AuthSessionChanged(data.session));
      });
    }
  }

  StreamSubscription<dynamic>? _authSub;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    if (!Env.isConfigured) {
      emit(const AuthFailure(
        'Supabase non configuré : lancez avec --dart-define '
        '(SUPABASE_URL, SUPABASE_ANON_KEY).',
      ));
      return;
    }
    try {
      final existing = SupabaseService.auth.currentUser;
      if (existing != null) {
        emit(AuthAuthenticated(user: existing));
        return;
      }
      // Premier lancement : compte anonyme automatique, sans écran d'inscription.
      final res = await SupabaseService.auth.signInAnonymously();
      final user = res.user;
      if (user == null) {
        emit(const AuthFailure('Impossible de créer une session anonyme.'));
        return;
      }
      emit(AuthAuthenticated(user: user));
    } on AuthException catch (e) {
      emit(AuthFailure(e.message));
    } catch (_) {
      emit(const AuthFailure('Erreur inattendue lors de la connexion.'));
    }
  }

  void _onSessionChanged(AuthSessionChanged event, Emitter<AuthState> emit) {
    final user = event.session?.user;
    if (user != null) {
      emit(AuthAuthenticated(user: user));
    } else if (state is! AuthLoading && state is! AuthInitial) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onSignedOut(
    AuthSignedOut event,
    Emitter<AuthState> emit,
  ) async {
    await SupabaseService.auth.signOut();
    emit(const AuthUnauthenticated());
  }

  @override
  Future<void> close() {
    _authSub?.cancel();
    return super.close();
  }
}
