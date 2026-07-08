import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../domain/discovery.dart';

class DiscoveryRepositoryException implements Exception {
  const DiscoveryRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'DiscoveryRepositoryException($message)';
}

/// Accès à la vue Découverte de l'Accueil via l'API NestJS.
class DiscoveryRepository {
  DiscoveryRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Dio get _dio => _apiClient.raw;

  Future<DiscoveryData> fetchHome() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/discovery/home');
      return DiscoveryData.fromJson(res.data ?? const {});
    } on DioException catch (_) {
      throw const DiscoveryRepositoryException(
        "Impossible de charger l'accueil.",
      );
    }
  }
}
