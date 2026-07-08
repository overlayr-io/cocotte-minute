import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/json_list_cache.dart';
import '../domain/category.dart';

/// Erreur portant un message exploitable pour l'UI (snackbar/page d'erreur).
class CategoriesRepositoryException implements Exception {
  const CategoriesRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'CategoriesRepositoryException($message)';
}

/// Accès aux catégories (dossiers) via l'API NestJS.
///
/// Les lectures passent par un cache simple (mémoire TTL + disque en repli
/// hors connexion, comme tags/personnes) ; chaque mutation invalide ce cache.
class CategoriesRepository {
  CategoriesRepository({required ApiClient apiClient, JsonListCache? cache})
    : _apiClient = apiClient,
      _cache = cache ?? JsonListCache(storageKey: 'categories');

  final ApiClient _apiClient;
  final JsonListCache _cache;

  Dio get _dio => _apiClient.raw;

  Future<List<Category>> fetchMine({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = _cache.fresh;
      if (cached != null) return cached.map(Category.fromJson).toList();
    }
    try {
      final res = await _dio.get<List<dynamic>>('/categories');
      final data = (res.data ?? const []).cast<Map<String, dynamic>>();
      await _cache.write(data);
      return data.map(Category.fromJson).toList();
    } on DioException catch (e) {
      // Réseau indisponible : on sert la dernière copie disque si elle existe.
      final fallback = await _cache.readDisk();
      if (fallback != null) return fallback.map(Category.fromJson).toList();
      throw _mapError(e, 'Impossible de charger tes dossiers.');
    }
  }

  Future<Category> create({
    required String name,
    String? icon,
    String? parentCategoryId,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/categories',
        data: {
          'name': name,
          'icon': ?icon,
          'parentCategoryId': ?parentCategoryId,
        },
      );
      await _cache.clear();
      return Category.fromJson(res.data!);
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de créer le dossier.');
    }
  }

  Future<Category> update(String id, {String? name, String? icon}) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        '/categories/$id',
        data: {'name': ?name, 'icon': ?icon},
      );
      await _cache.clear();
      return Category.fromJson(res.data!);
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible d\'enregistrer les modifications.');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete<void>('/categories/$id');
      await _cache.clear();
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de supprimer le dossier.');
    }
  }

  CategoriesRepositoryException _mapError(DioException e, String fallback) {
    // 400 (profondeur), 403 (dossier par défaut), 409 (nom pris / non vide) :
    // le serveur renvoie un message FR actionnable, on le remonte tel quel.
    final status = e.response?.statusCode;
    if (status == 400 || status == 403 || status == 409) {
      final data = e.response?.data;
      if (data is Map && data['message'] is String) {
        return CategoriesRepositoryException(data['message'] as String);
      }
    }
    // API injoignable (serveur éteint, mauvaise URL, ou HTTP bloqué).
    const connectivityErrors = {
      DioExceptionType.connectionError,
      DioExceptionType.connectionTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.sendTimeout,
    };
    if (connectivityErrors.contains(e.type)) {
      return const CategoriesRepositoryException(
        'Serveur injoignable. Vérifie que l\'API tourne et que l\'URL est correcte.',
      );
    }
    return CategoriesRepositoryException(fallback);
  }
}
