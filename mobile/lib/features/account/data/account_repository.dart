import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../domain/account_deletion.dart';

/// Erreur portant un message exploitable pour l'UI (snackbar/page d'erreur).
class AccountRepositoryException implements Exception {
  const AccountRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'AccountRepositoryException($message)';
}

/// Accès aux opérations de gestion du compte côté serveur NestJS
/// (suppression RGPD). L'auth Supabase (signOut / signInAnonymously) reste
/// gérée par `AuthRepository` — ici on ne parle qu'à l'API métier.
class AccountRepository {
  AccountRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Dio get _dio => _apiClient.raw;

  /// Demande la suppression du compte courant (RGPD).
  ///
  /// - Compte anonyme → suppression immédiate côté serveur (`deleted`).
  /// - Compte complet → anonymisation + délai de 30 jours (`pending_deletion`).
  ///
  /// 409 si une suppression est déjà en cours.
  Future<AccountDeletionResult> requestDeletion() async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/account/request-deletion',
      );
      return AccountDeletionResult.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw _mapError(
        e,
        conflictMessage: 'Une suppression est déjà en cours.',
        fallback: 'Impossible de demander la suppression du compte.',
      );
    }
  }

  /// Lit le statut RGPD du compte courant (pour la bannière d'annulation).
  ///
  /// `status: active` par défaut ; `pending_deletion` avec `deletionScheduledAt`
  /// (échéance ISO J+30) si une suppression est en attente. Le payload ne porte
  /// pas de champ `anonymous` (non pertinent en lecture) — [AccountDeletionResult]
  /// le laisse à `false` par défaut.
  Future<AccountDeletionResult> getStatus() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/account/status');
      return AccountDeletionResult.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw _mapError(
        e,
        conflictMessage: 'Impossible de lire le statut du compte.',
        fallback: 'Impossible de lire le statut du compte.',
      );
    }
  }

  /// Annule une suppression en attente (tant que le délai de 30 jours court).
  ///
  /// 409 si aucune suppression n'est en attente ou si le délai est dépassé.
  Future<void> cancelDeletion() async {
    try {
      await _dio.post<void>('/account/cancel-deletion');
    } on DioException catch (e) {
      throw _mapError(
        e,
        conflictMessage:
            'Aucune suppression à annuler, ou le délai de 30 jours est dépassé.',
        fallback: 'Impossible d\'annuler la suppression.',
      );
    }
  }

  AccountRepositoryException _mapError(
    DioException e, {
    required String conflictMessage,
    required String fallback,
  }) {
    const connectivityErrors = {
      DioExceptionType.connectionError,
      DioExceptionType.connectionTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.sendTimeout,
    };
    if (connectivityErrors.contains(e.type)) {
      return const AccountRepositoryException(
        'Serveur injoignable. Vérifie que l\'API tourne et que l\'URL est correcte.',
      );
    }
    if (e.response?.statusCode == 409) {
      return AccountRepositoryException(conflictMessage);
    }
    return AccountRepositoryException(fallback);
  }
}
