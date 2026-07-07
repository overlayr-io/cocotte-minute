import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../recipes/domain/recipe.dart';

/// Erreur portant un message exploitable pour l'UI (snackbar/page d'erreur).
class SearchRepositoryException implements Exception {
  const SearchRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'SearchRepositoryException($message)';
}

/// Accès à la recherche avancée de recettes via l'API NestJS
/// (`GET /search/recipes`). Les critères se combinent en ET côté serveur ;
/// le dépliage des sous-dossiers et la traduction personnes → tags sont faits
/// serveur (cf. SearchService).
class SearchRepository {
  SearchRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Dio get _dio => _apiClient.raw;

  Future<List<RecipeSummary>> search({
    String? query,
    List<String> categoryIds = const [],
    List<String> tagIds = const [],
    List<String> personIds = const [],
  }) async {
    try {
      final params = <String, dynamic>{
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        if (categoryIds.isNotEmpty) 'categoryIds': categoryIds,
        if (tagIds.isNotEmpty) 'tagIds': tagIds,
        if (personIds.isNotEmpty) 'personIds': personIds,
      };
      final res = await _dio.get<List<dynamic>>(
        '/search/recipes',
        queryParameters: params,
      );
      return (res.data ?? const [])
          .cast<Map<String, dynamic>>()
          .map(RecipeSummary.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible d\'effectuer la recherche.');
    }
  }

  SearchRepositoryException _mapError(DioException e, String fallback) {
    final status = e.response?.statusCode;
    if (status == 400 || status == 403 || status == 404 || status == 409) {
      final data = e.response?.data;
      if (data is Map && data['message'] is String) {
        return SearchRepositoryException(data['message'] as String);
      }
    }
    const connectivityErrors = {
      DioExceptionType.connectionError,
      DioExceptionType.connectionTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.sendTimeout,
    };
    if (connectivityErrors.contains(e.type)) {
      return const SearchRepositoryException(
        'Serveur injoignable. Vérifie que l\'API tourne et que l\'URL est correcte.',
      );
    }
    return SearchRepositoryException(fallback);
  }
}
