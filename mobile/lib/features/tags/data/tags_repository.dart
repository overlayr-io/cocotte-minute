import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../domain/tag.dart';

/// Erreur portant un message exploitable pour l'UI (snackbar/page d'erreur).
class TagsRepositoryException implements Exception {
  const TagsRepositoryException(this.message, {this.duplicateName = false});

  final String message;

  /// Vrai si l'échec vient d'un nom de tag déjà pris (409).
  final bool duplicateName;

  @override
  String toString() => 'TagsRepositoryException($message)';
}

/// Accès aux tags via l'API NestJS (donnée métier → jamais Supabase direct).
class TagsRepository {
  TagsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Dio get _dio => _apiClient.raw;

  Future<List<Tag>> fetchMine() async {
    try {
      final res = await _dio.get<List<dynamic>>('/tags');
      return (res.data ?? const [])
          .cast<Map<String, dynamic>>()
          .map(Tag.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de charger tes tags.');
    }
  }

  Future<Tag> create({required String name, required String color}) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/tags',
        data: {'name': name, 'color': color},
      );
      return Tag.fromJson(res.data!);
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de créer le tag.');
    }
  }

  Future<Tag> update(String id, {String? name, String? color}) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        '/tags/$id',
        data: {'name': ?name, 'color': ?color},
      );
      return Tag.fromJson(res.data!);
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible d\'enregistrer les modifications.');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete<void>('/tags/$id');
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de supprimer le tag.');
    }
  }

  TagsRepositoryException _mapError(DioException e, String fallback) {
    if (e.response?.statusCode == 409) {
      return const TagsRepositoryException(
        'Un tag portant ce nom existe déjà.',
        duplicateName: true,
      );
    }
    // API injoignable (serveur éteint, mauvaise URL, ou HTTP bloqué) : message
    // explicite plutôt qu'un « impossible de charger » générique.
    const connectivityErrors = {
      DioExceptionType.connectionError,
      DioExceptionType.connectionTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.sendTimeout,
    };
    if (connectivityErrors.contains(e.type)) {
      return const TagsRepositoryException(
        'Serveur injoignable. Vérifie que l\'API tourne et que l\'URL est correcte.',
      );
    }
    return TagsRepositoryException(fallback);
  }
}
