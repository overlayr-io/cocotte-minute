import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/premium/premium_limit_error.dart';
import '../domain/ingredient.dart';
import '../domain/ingredient_photo.dart';

/// Erreur portant un message exploitable pour l'UI (snackbar/page d'erreur).
class IngredientsRepositoryException implements Exception {
  const IngredientsRepositoryException(
    this.message, {
    this.alreadyImported = false,
    this.premiumLimit,
  });

  final String message;

  /// Vrai si l'échec vient d'un ingrédient système déjà importé (409).
  final bool alreadyImported;

  /// Limite freemium atteinte (403 `PREMIUM_LIMIT_*`) : la vue ouvre l'upsell.
  final PremiumLimitError? premiumLimit;

  @override
  String toString() => 'IngredientsRepositoryException($message)';
}

/// Sentinelle « champ non fourni » pour distinguer « ne pas toucher » de
/// « mettre à null » dans un PATCH partiel (emoji/image).
const Object _unset = Object();

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
    String? emoji,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/ingredients',
        data: {
          'name': name,
          'unit': unit.wire,
          'imageUrl': ?imageUrl,
          'emoji': ?emoji,
        },
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

  /// Met à jour un ingrédient. [emoji]/[imageUrl] utilisent la sentinelle
  /// [_unset] par défaut : ne rien passer = champ inchangé, passer `null` =
  /// vider explicitement (le serveur tranche l'exclusivité emoji ↔ image).
  Future<Ingredient> update(
    String id, {
    String? name,
    IngredientUnit? unit,
    Object? imageUrl = _unset,
    Object? emoji = _unset,
  }) async {
    try {
      final data = <String, dynamic>{
        'name': ?name,
        if (unit != null) 'unit': unit.wire,
      };
      if (!identical(imageUrl, _unset)) data['imageUrl'] = imageUrl;
      if (!identical(emoji, _unset)) data['emoji'] = emoji;
      final res = await _dio.patch<Map<String, dynamic>>(
        '/ingredients/$id',
        data: data,
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

  /// Photos « Mes produits » (#14) de cet ingrédient, plus anciennes d'abord.
  Future<List<IngredientPhoto>> fetchProductPhotos(String ingredientId) async {
    try {
      final res = await _dio.get<List<dynamic>>('/ingredients/$ingredientId/photos');
      return (res.data ?? const [])
          .cast<Map<String, dynamic>>()
          .map(IngredientPhoto.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de charger tes produits.');
    }
  }

  /// Ajoute une photo produit (URL déjà uploadée). Renvoie la liste à jour ;
  /// peut porter un `premiumLimit` (quota 1 gratuit / 3 Pro).
  Future<List<IngredientPhoto>> addProductPhoto(
    String ingredientId,
    String imageUrl,
  ) async {
    try {
      final res = await _dio.post<List<dynamic>>(
        '/ingredients/$ingredientId/photos',
        data: {'imageUrl': imageUrl},
      );
      return (res.data ?? const [])
          .cast<Map<String, dynamic>>()
          .map(IngredientPhoto.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible d\'ajouter la photo.');
    }
  }

  /// Retire une photo produit (+ son fichier Storage côté serveur).
  Future<void> removeProductPhoto(String ingredientId, String photoId) async {
    try {
      await _dio.delete<void>('/ingredients/$ingredientId/photos/$photoId');
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de retirer la photo.');
    }
  }

  IngredientsRepositoryException _mapError(DioException e, String fallback) {
    final premiumLimit = PremiumLimitError.fromResponseData(e.response?.data);
    if (premiumLimit != null) {
      return IngredientsRepositoryException(
        premiumLimit.message ?? fallback,
        premiumLimit: premiumLimit,
      );
    }
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
