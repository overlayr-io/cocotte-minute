import 'package:shared_preferences/shared_preferences.dart';

import '../../recipes/data/recipes_repository.dart';

/// Onboarding « premier lancement » (#12) : sème une fois des recettes d'exemple
/// (une recette de base + un plat qui l'utilise) pour montrer le but de l'app.
///
/// Déclenché depuis [MainShell] une fois la session Supabase (anonyme incluse)
/// prête — jamais via `AuthBloc` : l'auth passe toujours directement par
/// `supabase_flutter`. Le serveur reste idempotent ; le flag local évite juste
/// un 2e appel réseau inutile après un premier succès.
class OnboardingService {
  OnboardingService({required RecipesRepository recipesRepository})
      : _recipes = recipesRepository;

  final RecipesRepository _recipes;

  /// Préfixe du flag local, **suffixé par l'id du compte**. Le semis se décide
  /// par compte, jamais par appareil : un compte invité recréé (après une
  /// suppression) doit repartir comme une première installation. Un flag global
  /// se serait posé au 1er lancement d'un compte qui avait déjà des recettes,
  /// verrouillant définitivement tous les comptes suivants du téléphone.
  static const _seededKeyPrefix = 'onboarding.sample_recipes_seeded.';

  Future<void> _pending = Future<void>.value();

  /// Semis en cours (déjà terminé si aucun n'était nécessaire). L'accueil
  /// l'attend avant son premier chargement : sans ça il interroge le serveur
  /// pendant le semis et affiche une page vide.
  Future<void> get pending => _pending;

  /// Lance le semis si ce compte ne l'a jamais eu. Ne bloque pas l'appelant :
  /// en cas d'échec réseau le flag n'est pas posé et on réessaiera au prochain
  /// lancement.
  void start(String userId) {
    _pending = _maybeSeed(userId);
  }

  Future<void> _maybeSeed(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_seededKeyPrefix$userId';
    if (prefs.getBool(key) ?? false) return;
    try {
      await _recipes.seedSamples();
      await prefs.setBool(key, true);
    } on RecipesRepositoryException {
      // Silencieux : onboarding facultatif, retenté au prochain démarrage.
    }
  }
}
