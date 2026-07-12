import 'package:dio/dio.dart';
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

  /// E-mail du compte courant (null en invité ou session absente).
  String? get currentEmail => _auth.currentUser?.email;

  /// Met à jour l'adresse e-mail du compte connecté.
  ///
  /// Supabase envoie un e-mail de confirmation : le changement n'est effectif
  /// qu'après validation du lien (selon la config du projet). On enveloppe
  /// l'`AuthException` en message exploitable pour l'UI.
  Future<void> updateEmail(String email) async {
    try {
      await _auth.updateUser(UserAttributes(email: email));
    } on AuthException catch (e) {
      throw AuthRepositoryException(e.message);
    } catch (_) {
      throw const AuthRepositoryException("Impossible de modifier l'e-mail.");
    }
  }

  /// Met à jour le mot de passe du compte connecté.
  Future<void> updatePassword(String password) async {
    try {
      await _auth.updateUser(UserAttributes(password: password));
    } on AuthException catch (e) {
      throw AuthRepositoryException(e.message);
    } catch (_) {
      throw const AuthRepositoryException(
        'Impossible de modifier le mot de passe.',
      );
    }
  }

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

  /// Déconnecte l'utilisateur courant.
  ///
  /// Le changement de session est capté par l'`AuthBloc` global (via
  /// `onAuthStateChange`), qui bascule alors sur l'écran d'auth.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on AuthException catch (e) {
      throw AuthRepositoryException(e.message);
    } catch (_) {
      throw const AuthRepositoryException('Déconnexion impossible.');
    }
  }

  /// Recrée une session anonyme vierge (comme une première installation).
  ///
  /// Utilisé après la suppression immédiate d'un compte invité : l'ancien
  /// compte anonyme a été supprimé côté serveur, on repart sur un compte neuf.
  Future<void> recreateAnonymousSession() async {
    try {
      await _auth.signInAnonymously();
    } on AuthException catch (e) {
      throw AuthRepositoryException(e.message);
    } catch (_) {
      throw const AuthRepositoryException(
        'Impossible de recréer une session anonyme.',
      );
    }
  }

  /// "Repartir de zéro" : supprime toutes les données invité liées au compte
  /// courant (cascade côté serveur), pour démarrer sur un compte vierge.
  Future<void> resetGuestData() async {
    try {
      await _apiClient.raw.post<void>(
        '/account/reset-guest-data',
        // Purge de plusieurs domaines + démarrage à froid possible (hébergement
        // gratuit) : le timeout par défaut de l'ApiClient (15s) peut expirer
        // avant que le serveur n'ait fini de répondre, sans qu'aucune requête
        // n'ait pourtant échoué côté serveur (d'où l'absence totale de logs
        // rapportée en TestFlight). On laisse plus de marge sur cet appel précis.
        options: Options(
          sendTimeout: const Duration(seconds: 45),
          receiveTimeout: const Duration(seconds: 45),
        ),
      );
    } on DioException catch (e) {
      const connectivityErrors = {
        DioExceptionType.connectionError,
        DioExceptionType.connectionTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.sendTimeout,
      };
      if (connectivityErrors.contains(e.type)) {
        throw const AuthRepositoryException(
          'Serveur injoignable ou trop lent à répondre. Réessaie dans quelques instants.',
        );
      }
      throw const AuthRepositoryException(
        'Impossible de réinitialiser les données.',
      );
    } catch (_) {
      throw const AuthRepositoryException(
        'Impossible de réinitialiser les données.',
      );
    }
  }
}
