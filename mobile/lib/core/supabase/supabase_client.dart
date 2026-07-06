import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';

/// Point d'accès unique au client Supabase.
///
/// L'auth (login, signup, OAuth, session, compte anonyme) passe TOUJOURS par
/// ce client directement — jamais par l'API NestJS (cf. mobile/CLAUDE.md).
class SupabaseService {
  const SupabaseService._();

  /// À appeler une seule fois au démarrage, avant `runApp`.
  static Future<void> init() {
    return Supabase.initialize(
      url: Env.supabaseUrl,
      // `anonKey` est déprécié au profit de `publishableKey` (même valeur côté
      // dashboard Supabase : la clé publique `anon`).
      publishableKey: Env.supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  static GoTrueClient get auth => client.auth;
}
