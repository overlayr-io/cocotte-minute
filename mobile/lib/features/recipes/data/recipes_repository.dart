import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../domain/recipe.dart';

/// Erreur portant un message exploitable pour l'UI (snackbar/page d'erreur).
class RecipesRepositoryException implements Exception {
  const RecipesRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'RecipesRepositoryException($message)';
}

/// Accès aux recettes via l'API NestJS.
class RecipesRepository {
  RecipesRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Dio get _dio => _apiClient.raw;

  Future<List<RecipeSummary>> fetchMine() async {
    try {
      final res = await _dio.get<List<dynamic>>('/recipes');
      return (res.data ?? const [])
          .cast<Map<String, dynamic>>()
          .map(RecipeSummary.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de charger tes recettes.');
    }
  }

  Future<RecipeDetail> fetchDetail(String id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/recipes/$id');
      return RecipeDetail.fromJson(res.data!);
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de charger la recette.');
    }
  }

  Future<RecipeSummary> create({
    required String name,
    String? photoUrl,
    bool isBase = false,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/recipes',
        data: {'name': name, 'photoUrl': ?photoUrl, 'isBase': isBase},
      );
      return RecipeSummary.fromJson(res.data!);
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de créer la recette.');
    }
  }

  Future<RecipeSummary> update(
    String id, {
    String? name,
    String? description,
    bool? isBase,
    int? prepTime,
    int? cookTime,
    int? restTime,
    int? servings,
  }) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        '/recipes/$id',
        data: {
          'name': ?name,
          'description': ?description,
          'isBase': ?isBase,
          'prepTime': ?prepTime,
          'cookTime': ?cookTime,
          'restTime': ?restTime,
          'servings': ?servings,
        },
      );
      return RecipeSummary.fromJson(res.data!);
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible d\'enregistrer les modifications.');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete<void>('/recipes/$id');
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de supprimer la recette.');
    }
  }

  RecipesRepositoryException _mapError(DioException e, String fallback) {
    // 400/403/404/409 : le serveur renvoie un message FR actionnable (verrou
    // is_base, composant invalide, recette introuvable...), on le remonte tel quel.
    final status = e.response?.statusCode;
    if (status == 400 || status == 403 || status == 404 || status == 409) {
      final data = e.response?.data;
      if (data is Map && data['message'] is String) {
        return RecipesRepositoryException(data['message'] as String);
      }
    }
    const connectivityErrors = {
      DioExceptionType.connectionError,
      DioExceptionType.connectionTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.sendTimeout,
    };
    if (connectivityErrors.contains(e.type)) {
      return const RecipesRepositoryException(
        'Serveur injoignable. Vérifie que l\'API tourne et que l\'URL est correcte.',
      );
    }
    return RecipesRepositoryException(fallback);
  }
}
