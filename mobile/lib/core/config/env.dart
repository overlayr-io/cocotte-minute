import 'package:flutter/foundation.dart';

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
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  /// URL de l'API REST NestJS.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  /// Clé fournie au build via `--dart-define(-from-file)`. Vide si absente.
  static const String _revenueCatApiKeyOverride = String.fromEnvironment(
    'REVENUECAT_API_KEY',
  );

  /// Clé du Test Store RevenueCat — repli de DÉVELOPPEMENT uniquement.
  static const String _revenueCatTestStoreKey =
      'test_kEgnwyHVcQbsaiAcjgSICRMXwOl';

  /// Clé API publique du SDK RevenueCat (abonnement premium).
  ///
  /// Ce n'est PAS un secret : c'est la clé publique embarquée dans l'app.
  /// En debug, on retombe sur la clé du Test Store pour développer sans config.
  /// En release, une clé de prod par plateforme (`appl_...` iOS / `goog_...`
  /// Android) est OBLIGATOIRE : sans elle on renvoie une chaîne vide plutôt que
  /// d'embarquer la clé de test par accident. C'est exactement ce repli
  /// silencieux qui a causé le rejet Apple 2.1 (« Pro page error ») : le Test
  /// Store ne peut pas servir les produits App Store réels sur l'appareil du
  /// reviewer, donc le chargement des offres échouait.
  static String get revenueCatApiKey {
    if (_revenueCatApiKeyOverride.isNotEmpty) return _revenueCatApiKeyOverride;
    return kReleaseMode ? '' : _revenueCatTestStoreKey;
  }

  /// Vrai si un build release n'a reçu aucune clé RevenueCat de prod : le
  /// premium doit alors être désactivé proprement, jamais avec la clé de test.
  static bool get revenueCatKeyMissingInRelease =>
      kReleaseMode && _revenueCatApiKeyOverride.isEmpty;

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
