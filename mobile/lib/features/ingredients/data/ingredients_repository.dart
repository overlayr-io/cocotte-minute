import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../domain/ingredient.dart';

/// Erreur portant un message exploitable pour l'UI (snackbar/page d'erreur).
class IngredientsRepositoryException implements Exception {
  const IngredientsRepositoryException(this.message, {this.alreadyImported = false});

  final String message;

  /// Vrai si l'échec vient d'un ingrédient système déjà importé (409).
  final bool alreadyImported;

  @override
  String toString() => 'IngredientsRepositoryException($message)';
}

/// Accès aux ingrédients via l'API NestJS (donnée métier → jamais Supabase direct).
class IngredientsRepository {
  IngredientsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Dio get _dio => _apiClient.raw;

  Future<List<Ingredient>> fetchMine() async {
    try {
      final res = await _dio.get<List<dynamic>>('/ingredients');
      return (res.data ?? const [])
          .cast<Map<String, dynamic>>()
          .map(Ingredient.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de charger tes ingrédients.');
    }
  }

  Future<List<Ingredient>> fetchSystem() async {
    try {
      final res = await _dio.get<List<dynamic>>('/ingredients/system');
      return (res.data ?? const [])
          .cast<Map<String, dynamic>>()
          .map(Ingredient.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de charger le catalogue.');
    }
  }

  Future<IngredientDetail> fetchDetail(String id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/ingredients/$id');
      return IngredientDetail.fromJson(res.data!);
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de charger l\'ingrédient.');
    }
  }

  Future<Ingredient> create({
    required String name,
    required IngredientUnit unit,
    String? imageUrl,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/ingredients',
        data: {'name': name, 'unit': unit.wire, 'imageUrl': ?imageUrl},
      );
      return Ingredient.fromJson(res.data!);
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de créer l\'ingrédient.');
    }
  }

  Future<Ingredient> importSystem(String systemId) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/ingredients/$systemId/import');
      return Ingredient.fromJson(res.data!);
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible d\'importer l\'ingrédient.');
    }
  }

  Future<Ingredient> update(
    String id, {
    String? name,
    IngredientUnit? unit,
    String? imageUrl,
  }) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        '/ingredients/$id',
        data: {
          'name': ?name,
          if (unit != null) 'unit': unit.wire,
          'imageUrl': ?imageUrl,
        },
      );
      return Ingredient.fromJson(res.data!);
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible d\'enregistrer les modifications.');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete<void>('/ingredients/$id');
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de supprimer l\'ingrédient.');
    }
  }

  Future<void> addAlternative(String id, String alternativeId) async {
    try {
      await _dio.post<void>(
        '/ingredients/$id/alternatives',
        data: {'alternativeId': alternativeId},
      );
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible d\'ajouter l\'alternative.');
    }
  }

  Future<void> removeAlternative(String id, String alternativeId) async {
    try {
      await _dio.delete<void>('/ingredients/$id/alternatives/$alternativeId');
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de retirer l\'alternative.');
    }
  }

  IngredientsRepositoryException _mapError(DioException e, String fallback) {
    if (e.response?.statusCode == 409) {
      return const IngredientsRepositoryException(
        'Cet ingrédient est déjà importé.',
        alreadyImported: true,
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
      return const IngredientsRepositoryException(
        'Serveur injoignable. Vérifie que l\'API tourne et que l\'URL est correcte.',
      );
    }
    return IngredientsRepositoryException(fallback);
  }
}
