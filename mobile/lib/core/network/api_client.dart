import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
      ..baseUrl = _resolveBaseUrl(Env.apiBaseUrl)
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

  /// Réécrit `localhost` pour l'émulateur Android, où la machine hôte (qui
  /// héberge le serveur NestJS) est joignable via `10.0.2.2` et non `localhost`
  /// (qui pointe vers l'émulateur lui-même). Confort de dev ; sans effet si une
  /// URL explicite est fournie via `--dart-define=API_BASE_URL=...`.
  static String _resolveBaseUrl(String raw) {
    if (kIsWeb) return raw;
    if (Platform.isAndroid) {
      return raw
          .replaceFirst('localhost', '10.0.2.2')
          .replaceFirst('127.0.0.1', '10.0.2.2');
    }
    return raw;
  }
}
