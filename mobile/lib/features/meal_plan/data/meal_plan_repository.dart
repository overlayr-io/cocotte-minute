import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/json_list_cache.dart';
import '../../../core/premium/premium_limit_error.dart';
import '../domain/meal_plan_entry.dart';

/// Erreur portant un message exploitable pour l'UI + la limite premium
/// éventuelle (403 structuré) pour ouvrir la feuille d'upsell.
class MealPlanRepositoryException implements Exception {
  const MealPlanRepositoryException(this.message, {this.premiumLimit});

  final String message;
  final PremiumLimitError? premiumLimit;

  @override
  String toString() => 'MealPlanRepositoryException($message)';
}

/// Accès au planning de repas via l'API NestJS.
///
/// Lecture par semaine avec cache (mémoire TTL + disque en repli hors
/// connexion — comportement « cache et connexion requise si pas de données »
/// acté dans planification-repas.md). Chaque mutation invalide le cache de la
/// semaine touchée.
class MealPlanRepository {
  MealPlanRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Un cache par semaine (`weekStart` → entrées JSON).
  final Map<String, JsonListCache> _weekCaches = {};

  Dio get _dio => _apiClient.raw;

  JsonListCache _cacheFor(String weekStart) => _weekCaches.putIfAbsent(
    weekStart,
    () => JsonListCache(storageKey: 'meal-plan/$weekStart'),
  );

  Future<List<MealPlanEntry>> fetchWeek(
    String weekStart, {
    bool forceRefresh = false,
  }) async {
    final cache = _cacheFor(weekStart);
    if (!forceRefresh) {
      final cached = cache.fresh;
      if (cached != null) return cached.map(MealPlanEntry.fromJson).toList();
    }
    try {
      final res = await _dio.get<List<dynamic>>(
        '/meal-plan',
        queryParameters: {'weekStart': weekStart},
      );
      final data = (res.data ?? const []).cast<Map<String, dynamic>>();
      await cache.write(data);
      return data.map(MealPlanEntry.fromJson).toList();
    } on DioException catch (e) {
      // Hors connexion : dernière copie disque si elle existe.
      final fallback = await cache.readDisk();
      if (fallback != null) return fallback.map(MealPlanEntry.fromJson).toList();
      throw _mapError(e, 'Impossible de charger le planning.');
    }
  }

  Future<MealPlanEntry> addEntry({
    required String day,
    required MealSlot slot,
    required MealEntryType type,
    String? recipeId,
    String? noteText,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/meal-plan/entries',
        data: {
          'day': day,
          'slot': slot.wire,
          'entryType': type.wire,
          'recipeId': ?recipeId,
          'noteText': ?noteText,
        },
      );
      await _clearWeekOf(day);
      return MealPlanEntry.fromJson(res.data!);
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible d\'ajouter au planning.');
    }
  }

  Future<void> removeEntry({required String id, required String day}) async {
    try {
      await _dio.delete<void>('/meal-plan/entries/$id');
      await _clearWeekOf(day);
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de retirer cette entrée.');
    }
  }

  /// Invalide le cache de la semaine contenant [day] (`YYYY-MM-DD`).
  Future<void> _clearWeekOf(String day) async {
    final date = DateTime.parse(day);
    final monday = date.subtract(Duration(days: date.weekday - DateTime.monday));
    final key =
        '${monday.year.toString().padLeft(4, '0')}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
    await _cacheFor(key).clear();
  }

  MealPlanRepositoryException _mapError(DioException e, String fallback) {
    const connectivityErrors = {
      DioExceptionType.connectionError,
      DioExceptionType.connectionTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.sendTimeout,
    };
    if (connectivityErrors.contains(e.type)) {
      return const MealPlanRepositoryException(
        'Pas de connexion. Réessaie une fois en ligne.',
      );
    }
    final premiumLimit = PremiumLimitError.fromResponseData(e.response?.data);
    if (premiumLimit != null) {
      return MealPlanRepositoryException(
        premiumLimit.message ?? fallback,
        premiumLimit: premiumLimit,
      );
    }
    final message = (e.response?.data as Map?)?['message'];
    return MealPlanRepositoryException(
      message is String ? message : fallback,
    );
  }
}
