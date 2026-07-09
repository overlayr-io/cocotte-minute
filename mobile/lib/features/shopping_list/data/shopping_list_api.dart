import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/premium/premium_limit_error.dart';
import '../domain/shopping_list.dart';

/// Erreur réseau/serveur portant un message FR exploitable pour l'UI.
class ShoppingListApiException implements Exception {
  const ShoppingListApiException(
    this.message, {
    this.isConnectivity = false,
    this.premiumLimit,
  });

  final String message;
  /// Vrai si l'échec vient d'une absence de réseau (à traiter en offline).
  final bool isConnectivity;

  /// Limite freemium (403 `PREMIUM_LIMIT_*`) : l'UI ouvre la feuille d'upsell
  /// au lieu d'afficher le message brut.
  final PremiumLimitError? premiumLimit;

  @override
  String toString() => 'ShoppingListApiException($message)';
}

/// Accès distant aux listes de courses (API NestJS). N'a aucune logique offline :
/// le [ShoppingListRepository] l'appelle et gère le cache local + la file de sync.
class ShoppingListApi {
  ShoppingListApi({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Dio get _dio => _apiClient.raw;

  Future<List<ShoppingList>> fetchLists() async {
    try {
      final res = await _dio.get<List<dynamic>>('/shopping-lists');
      return (res.data ?? const [])
          .cast<Map<String, dynamic>>()
          .map(ShoppingList.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de charger tes listes de courses.');
    }
  }

  Future<ShoppingListDetail> fetchDetail(String id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/shopping-lists/$id');
      return ShoppingListDetail.fromJson(res.data!);
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de charger cette liste.');
    }
  }

  /// Génère une liste côté serveur (agrégation) et la persiste. Nécessite le réseau.
  Future<ShoppingListDetail> generate({
    String? id,
    required String name,
    required List<({String recipeId, int servings})> recipes,
    required List<String> pantryIngredientIds,
    DateTime? clientUpdatedAt,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/shopping-lists',
        data: {
          'id': ?id,
          'name': name,
          'recipes': [
            for (final r in recipes)
              {'recipeId': r.recipeId, 'servings': r.servings},
          ],
          'pantryIngredientIds': pantryIngredientIds,
          'clientUpdatedAt': ?clientUpdatedAt?.toUtc().toIso8601String(),
        },
      );
      return ShoppingListDetail.fromJson(res.data!);
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de générer la liste.');
    }
  }

  Future<void> rename(
    String id, {
    required String name,
    required DateTime clientUpdatedAt,
  }) async {
    try {
      await _dio.patch<Map<String, dynamic>>(
        '/shopping-lists/$id',
        data: {'name': name, 'clientUpdatedAt': clientUpdatedAt.toUtc().toIso8601String()},
      );
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de renommer la liste.');
    }
  }

  Future<void> clear(String id) async {
    try {
      await _dio.delete<void>('/shopping-lists/$id');
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de vider la liste.');
    }
  }

  /// Crée un article libre côté serveur (avec l'id client, pour un id stable).
  Future<void> createItem(
    String listId, {
    required String itemId,
    required String customLabel,
    double? quantity,
    String? unit,
    required DateTime clientUpdatedAt,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/shopping-lists/$listId/items',
        data: {
          'id': itemId,
          'customLabel': customLabel,
          'quantity': ?quantity,
          'unit': ?unit,
          'clientUpdatedAt': clientUpdatedAt.toUtc().toIso8601String(),
        },
      );
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible d\'ajouter l\'article.');
    }
  }

  /// Pousse l'état complet d'un article (coché + alternative) — idempotent, LWW.
  /// `replacedByAlternativeId` null réinitialise l'article vers son ingrédient.
  Future<void> updateItem(
    String listId,
    String itemId, {
    required bool isChecked,
    required String? replacedByAlternativeId,
    required DateTime clientUpdatedAt,
  }) async {
    try {
      await _dio.patch<Map<String, dynamic>>(
        '/shopping-lists/$listId/items/$itemId',
        data: {
          'isChecked': isChecked,
          'replacedByAlternativeId': replacedByAlternativeId,
          'clientUpdatedAt': clientUpdatedAt.toUtc().toIso8601String(),
        },
      );
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de mettre à jour l\'article.');
    }
  }

  Future<void> removeItem(String listId, String itemId) async {
    try {
      await _dio.delete<void>('/shopping-lists/$listId/items/$itemId');
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de supprimer l\'article.');
    }
  }

  ShoppingListApiException _mapError(DioException e, String fallback) {
    final status = e.response?.statusCode;
    if (status == 400 || status == 403 || status == 409) {
      final data = e.response?.data;
      // 403 structuré { code: PREMIUM_LIMIT_*, limit, current } : porté par
      // l'exception pour que l'UI ouvre l'upsell adapté.
      final premiumLimit = PremiumLimitError.fromResponseData(data);
      if (data is Map && data['message'] is String) {
        return ShoppingListApiException(
          data['message'] as String,
          premiumLimit: premiumLimit,
        );
      }
      if (premiumLimit != null) {
        return ShoppingListApiException(fallback, premiumLimit: premiumLimit);
      }
    }
    const connectivityErrors = {
      DioExceptionType.connectionError,
      DioExceptionType.connectionTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.sendTimeout,
    };
    if (connectivityErrors.contains(e.type)) {
      return const ShoppingListApiException(
        'Hors ligne : la synchronisation reprendra automatiquement.',
        isConnectivity: true,
      );
    }
    return ShoppingListApiException(fallback);
  }
}
