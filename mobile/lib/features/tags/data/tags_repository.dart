import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/json_list_cache.dart';
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
///
/// Les lectures passent par un cache simple (mémoire TTL + disque en repli
/// hors connexion) ; chaque mutation invalide ce cache et ceux qui embarquent
/// des tags (ex: personnes).
class TagsRepository {
  TagsRepository({
    required ApiClient apiClient,
    JsonListCache? cache,
    List<JsonListCache> linkedCaches = const [],
  }) : _apiClient = apiClient,
       _cache = cache ?? JsonListCache(storageKey: 'tags'),
       _linkedCaches = linkedCaches;

  final ApiClient _apiClient;
  final JsonListCache _cache;

  /// Caches d'autres features dont les données embarquent des tags : ils sont
  /// invalidés en même temps (ex: `person.tags` après un renommage de tag).
  final List<JsonListCache> _linkedCaches;

  Dio get _dio => _apiClient.raw;

  Future<void> _invalidateCaches() async {
    await _cache.clear();
    for (final linked in _linkedCaches) {
      await linked.clear();
    }
  }

  Future<List<Tag>> fetchMine({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = _cache.fresh;
      if (cached != null) return cached.map(Tag.fromJson).toList();
    }
    try {
      final res = await _dio.get<List<dynamic>>('/tags');
      final data = (res.data ?? const []).cast<Map<String, dynamic>>();
      await _cache.write(data);
      return data.map(Tag.fromJson).toList();
    } on DioException catch (e) {
      // Réseau indisponible : on sert la dernière copie disque si elle existe.
      final fallback = await _cache.readDisk();
      if (fallback != null) return fallback.map(Tag.fromJson).toList();
      throw _mapError(e, 'Impossible de charger tes tags.');
    }
  }

  Future<Tag> create({required String name, required String color}) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/tags',
        data: {'name': name, 'color': color},
      );
      await _invalidateCaches();
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
      await _invalidateCaches();
      return Tag.fromJson(res.data!);
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible d\'enregistrer les modifications.');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete<void>('/tags/$id');
      await _invalidateCaches();
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
