import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/json_list_cache.dart';
import '../domain/person.dart';

/// Erreur portant un message exploitable pour l'UI (snackbar/page d'erreur).
class PeopleRepositoryException implements Exception {
  const PeopleRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'PeopleRepositoryException($message)';
}

/// Accès aux personnes via l'API NestJS (donnée métier → jamais Supabase direct).
///
/// Les lectures passent par un cache simple (mémoire TTL + disque en repli
/// hors connexion) ; chaque mutation invalide ce cache.
class PeopleRepository {
  PeopleRepository({required ApiClient apiClient, JsonListCache? cache})
    : _apiClient = apiClient,
      _cache = cache ?? JsonListCache(storageKey: 'people');

  final ApiClient _apiClient;
  final JsonListCache _cache;

  Dio get _dio => _apiClient.raw;

  Future<List<Person>> fetchMine({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = _cache.fresh;
      if (cached != null) return cached.map(Person.fromJson).toList();
    }
    try {
      final res = await _dio.get<List<dynamic>>('/people');
      final data = (res.data ?? const []).cast<Map<String, dynamic>>();
      await _cache.write(data);
      return data.map(Person.fromJson).toList();
    } on DioException catch (e) {
      // Réseau indisponible : on sert la dernière copie disque si elle existe.
      final fallback = await _cache.readDisk();
      if (fallback != null) return fallback.map(Person.fromJson).toList();
      throw _mapError(e, 'Impossible de charger ta famille.');
    }
  }

  Future<Person> create({required String firstName, String? lastName}) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/people',
        data: {
          'firstName': firstName,
          if (lastName != null && lastName.isNotEmpty) 'lastName': lastName,
        },
      );
      await _cache.clear();
      return Person.fromJson(res.data!);
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de créer la personne.');
    }
  }

  /// Édite prénom + nom (+ avatar). `lastName` null/vide → le nom est retiré
  /// (envoyé null). `avatarUrl` n'est envoyé que s'il est renseigné (jamais effacé).
  Future<Person> update(
    String id, {
    required String firstName,
    String? lastName,
    String? avatarUrl,
  }) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        '/people/$id',
        data: {
          'firstName': firstName,
          'lastName': (lastName == null || lastName.isEmpty) ? null : lastName,
          'avatarUrl': ?avatarUrl,
        },
      );
      await _cache.clear();
      return Person.fromJson(res.data!);
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible d\'enregistrer les modifications.');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete<void>('/people/$id');
      await _cache.clear();
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de supprimer la personne.');
    }
  }

  /// Associe un tag et retourne la personne à jour.
  Future<Person> addTag(String personId, String tagId) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/people/$personId/tags',
        data: {'tagId': tagId},
      );
      await _cache.clear();
      return Person.fromJson(res.data!);
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible d\'associer le tag.');
    }
  }

  /// Retire l'association d'un tag et retourne la personne à jour.
  Future<Person> removeTag(String personId, String tagId) async {
    try {
      final res = await _dio.delete<Map<String, dynamic>>(
        '/people/$personId/tags/$tagId',
      );
      await _cache.clear();
      return Person.fromJson(res.data!);
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de retirer le tag.');
    }
  }

  /// Associe une recette (« ses recettes ») et retourne la personne à jour.
  Future<Person> addRecipe(String personId, String recipeId) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/people/$personId/recipes',
        data: {'recipeId': recipeId},
      );
      await _cache.clear();
      return Person.fromJson(res.data!);
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible d\'associer la recette.');
    }
  }

  /// Retire l'association d'une recette et retourne la personne à jour.
  Future<Person> removeRecipe(String personId, String recipeId) async {
    try {
      final res = await _dio.delete<Map<String, dynamic>>(
        '/people/$personId/recipes/$recipeId',
      );
      await _cache.clear();
      return Person.fromJson(res.data!);
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de retirer la recette.');
    }
  }

  PeopleRepositoryException _mapError(DioException e, String fallback) {
    const connectivityErrors = {
      DioExceptionType.connectionError,
      DioExceptionType.connectionTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.sendTimeout,
    };
    if (connectivityErrors.contains(e.type)) {
      return const PeopleRepositoryException(
        'Serveur injoignable. Vérifie que l\'API tourne et que l\'URL est correcte.',
      );
    }
    return PeopleRepositoryException(fallback);
  }
}
