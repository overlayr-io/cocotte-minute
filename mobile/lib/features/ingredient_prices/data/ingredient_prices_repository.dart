import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/json_list_cache.dart';
import '../domain/ingredient_price.dart';

/// Erreur portant un message exploitable pour l'UI (snackbar/page d'erreur).
class IngredientPricesRepositoryException implements Exception {
  const IngredientPricesRepositoryException(
    this.message, {
    this.premiumRequired = false,
  });

  final String message;

  /// Vrai si l'échec vient d'une écriture bas/haut par un compte non premium (403).
  final bool premiumRequired;

  @override
  String toString() => 'IngredientPricesRepositoryException($message)';
}

/// Sentinelle « champ non fourni » pour distinguer « ne pas toucher » de
/// « mettre à null » dans un PATCH partiel (bas/haut/moyen).
const Object _unset = Object();

/// Accès aux prix d'ingrédients via l'API NestJS (donnée métier → jamais
/// Supabase direct).
///
/// Les lectures passent par un cache simple (mémoire TTL + disque en repli
/// hors connexion), même pattern que tags/personnes/catégories : nécessaire
/// pour calculer un prix de recette ou un total de liste de courses hors ligne
/// (le calcul lui-même reste toujours côté client, jamais côté serveur).
class IngredientPricesRepository {
  IngredientPricesRepository({required ApiClient apiClient, JsonListCache? cache})
    : _apiClient = apiClient,
      _cache = cache ?? JsonListCache(storageKey: 'ingredient_prices');

  final ApiClient _apiClient;
  final JsonListCache _cache;

  Dio get _dio => _apiClient.raw;

  Future<List<IngredientPrice>> fetchMine({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = _cache.fresh;
      if (cached != null) return cached.map(IngredientPrice.fromJson).toList();
    }
    try {
      final res = await _dio.get<List<dynamic>>('/ingredient-prices');
      final data = (res.data ?? const []).cast<Map<String, dynamic>>();
      await _cache.write(data);
      return data.map(IngredientPrice.fromJson).toList();
    } on DioException catch (e) {
      // Réseau indisponible : on sert la dernière copie disque si elle existe.
      final fallback = await _cache.readDisk();
      if (fallback != null) return fallback.map(IngredientPrice.fromJson).toList();
      throw _mapError(e, 'Impossible de charger tes prix.');
    }
  }

  /// Enregistre le prix d'un ingrédient. [lowPrice]/[highPrice]/[averagePrice]
  /// utilisent la sentinelle [_unset] par défaut : ne rien passer = champ
  /// inchangé (ex: un gratuit qui ne renvoie que [averagePrice] ne touche pas
  /// à un bas/haut déjà enregistré), passer `null` = vider explicitement.
  /// Lève [IngredientPricesRepositoryException.premiumRequired] (403) si
  /// [lowPrice]/[highPrice] sont envoyés par un compte non premium.
  Future<IngredientPrice> upsert(
    String ingredientId, {
    required PriceReferenceUnit priceReferenceUnit,
    Object? lowPrice = _unset,
    Object? highPrice = _unset,
    Object? averagePrice = _unset,
  }) async {
    try {
      final data = <String, dynamic>{
        'priceReferenceUnit': priceReferenceUnit.wire,
      };
      if (!identical(lowPrice, _unset)) data['lowPrice'] = lowPrice;
      if (!identical(highPrice, _unset)) data['highPrice'] = highPrice;
      if (!identical(averagePrice, _unset)) data['averagePrice'] = averagePrice;
      final res = await _dio.put<Map<String, dynamic>>(
        '/ingredient-prices/$ingredientId',
        data: data,
      );
      await _cache.clear();
      return IngredientPrice.fromJson(res.data!);
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible d\'enregistrer le prix.');
    }
  }

  IngredientPricesRepositoryException _mapError(DioException e, String fallback) {
    if (e.response?.statusCode == 403) {
      return const IngredientPricesRepositoryException(
        'La fourchette bas/haut est réservée aux comptes premium.',
        premiumRequired: true,
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
      return const IngredientPricesRepositoryException(
        'Serveur injoignable. Vérifie que l\'API tourne et que l\'URL est correcte.',
      );
    }
    return IngredientPricesRepositoryException(fallback);
  }
}
