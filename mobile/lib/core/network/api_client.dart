import 'package:dio/dio.dart';

import '../config/env.dart';
import '../supabase/supabase_client.dart';

/// Client HTTP pour l'API REST NestJS.
///
/// Toute donnée métier (recettes, ingrédients, tags, catégories, ...) passe par
/// un repository qui utilise ce client. L'auth, elle, ne passe jamais ici :
/// NestJS se contente de vérifier le JWT Supabase envoyé en `Authorization`.
class ApiClient {
  ApiClient({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options
      ..baseUrl = Env.apiBaseUrl
      ..connectTimeout = const Duration(seconds: 10)
      ..receiveTimeout = const Duration(seconds: 15)
      ..contentType = Headers.jsonContentType;

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Injecte le JWT Supabase courant sur chaque requête.
          final token = SupabaseService.auth.currentSession?.accessToken;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;

  Dio get raw => _dio;
}
