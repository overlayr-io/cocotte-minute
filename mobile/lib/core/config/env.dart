/// Configuration d'environnement.
///
/// Les valeurs sont injectées au build via `--dart-define` :
///   flutter run \
///     --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=xxx \
///     --dart-define=API_BASE_URL=http://localhost:3000
class Env {
  const Env._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  /// URL de l'API REST NestJS.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  /// Clé API publique du SDK RevenueCat (abonnement premium).
  ///
  /// Ce n'est PAS un secret : c'est la clé publique embarquée dans l'app.
  /// TODO(premium): la valeur par défaut est la clé du Test Store RevenueCat,
  /// commune aux deux plateformes. Avant toute release en production, la
  /// remplacer par les clés par plateforme (`appl_...` pour iOS, `goog_...`
  /// pour Android), par ex. via --dart-define=REVENUECAT_API_KEY=....
  static const String revenueCatApiKey = String.fromEnvironment(
    'REVENUECAT_API_KEY',
    defaultValue: 'test_kEgnwyHVcQbsaiAcjgSICRMXwOl',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
