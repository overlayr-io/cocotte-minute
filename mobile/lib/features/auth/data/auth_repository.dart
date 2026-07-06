import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/api_client.dart';
import '../../../core/supabase/supabase_client.dart';

/// Erreur d'authentification portant un message exploitable pour l'UI
/// (snackbar). Le bloc n'a pas à connaître les exceptions Supabase brutes.
class AuthRepositoryException implements Exception {
  const AuthRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'AuthRepositoryException($message)';
}

/// Accès aux opérations d'authentification.
///
/// Règle projet : l'auth passe TOUJOURS par `supabase_flutter` directement.
/// Seule exception, la suppression des données invité ("repartir de zéro"),
/// qui est une opération métier côté serveur → passe par [ApiClient].
class AuthRepository {
  AuthRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  GoTrueClient get _auth => SupabaseService.auth;

  /// L'utilisateur courant est-il un compte anonyme (invité) ?
  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? false;

  /// Crée un compte email/mot de passe.
  ///
  /// Si l'utilisateur est déjà anonyme (cas nominal), on **convertit** le
  /// compte via `updateUser` : le `userId` est conservé, donc toutes les
  /// données invité restent liées (cf. auth.md). Sinon, inscription classique.
  Future<void> createAccountWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      if (isAnonymous) {
        await _auth.updateUser(
          UserAttributes(email: email, password: password),
        );
      } else {
        await _auth.signUp(email: email, password: password);
      }
    } on AuthException catch (e) {
      throw AuthRepositoryException(e.message);
    } catch (_) {
      throw const AuthRepositoryException('Impossible de créer le compte.');
    }
  }

  /// Connexion à un compte email/mot de passe existant.
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      throw AuthRepositoryException(e.message);
    } catch (_) {
      throw const AuthRepositoryException('Connexion impossible.');
    }
  }

  /// Continue avec un fournisseur OAuth (Google/Apple).
  ///
  /// Si l'utilisateur est anonyme, on **lie** l'identité (`linkIdentity`) pour
  /// conserver le `userId` et les données ; sinon connexion OAuth classique.
  Future<void> continueWithOAuth(OAuthProvider provider) async {
    try {
      if (isAnonymous) {
        await _auth.linkIdentity(provider);
      } else {
        await _auth.signInWithOAuth(provider);
      }
    } on AuthException catch (e) {
      throw AuthRepositoryException(e.message);
    } catch (_) {
      throw const AuthRepositoryException('Connexion OAuth impossible.');
    }
  }

  /// "Repartir de zéro" : supprime toutes les données invité liées au compte
  /// courant (cascade côté serveur), pour démarrer sur un compte vierge.
  Future<void> resetGuestData() async {
    try {
      await _apiClient.raw.post<void>('/account/reset-guest-data');
    } catch (_) {
      throw const AuthRepositoryException(
        'Impossible de réinitialiser les données.',
      );
    }
  }
}
