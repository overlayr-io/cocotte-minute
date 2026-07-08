import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../domain/faq_entry.dart';

/// Erreur portant un message exploitable pour l'UI (snackbar/page d'erreur).
class HelpRepositoryException implements Exception {
  const HelpRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'HelpRepositoryException($message)';
}

/// Accès au centre d'aide via l'API NestJS : FAQ (lecture) et envoi d'un
/// message « Nous contacter ».
class HelpRepository {
  HelpRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Dio get _dio => _apiClient.raw;

  Future<List<FaqEntry>> fetchFaq() async {
    try {
      final res = await _dio.get<List<dynamic>>('/help/faq');
      return (res.data ?? const [])
          .cast<Map<String, dynamic>>()
          .map(FaqEntry.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de charger le centre d\'aide.');
    }
  }

  /// Envoie un message de contact. `appVersion` aide le support (jointe au log
  /// serveur).
  Future<void> sendContact({
    required String subject,
    required String message,
    String? appVersion,
  }) async {
    try {
      await _dio.post<void>(
        '/help/contact',
        data: {
          'subject': subject,
          'message': message,
          'appVersion': ?appVersion,
        },
      );
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible d\'envoyer ton message.');
    }
  }

  HelpRepositoryException _mapError(DioException e, String fallback) {
    const connectivityErrors = {
      DioExceptionType.connectionError,
      DioExceptionType.connectionTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.sendTimeout,
    };
    if (connectivityErrors.contains(e.type)) {
      return const HelpRepositoryException(
        'Serveur injoignable. Vérifie ta connexion et réessaie.',
      );
    }
    return HelpRepositoryException(fallback);
  }
}
