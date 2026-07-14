import 'package:shared_preferences/shared_preferences.dart';

import '../../recipes/data/recipes_repository.dart';

/// Onboarding « premier lancement » (#12) : sème une fois des recettes d'exemple
/// (une recette de base + un plat qui l'utilise) pour montrer le but de l'app.
///
/// Déclenché depuis [MainShell] une fois la session Supabase (anonyme incluse)
/// prête — jamais via `AuthBloc` : l'auth passe toujours directement par
/// `supabase_flutter`. Le serveur reste idempotent ; ce flag local évite juste
/// un 2e appel réseau inutile après un premier succès.
class OnboardingService {
  OnboardingService({required RecipesRepository recipesRepository})
      : _recipes = recipesRepository;

  final RecipesRepository _recipes;

  static const _seededKey = 'onboarding.sample_recipes_seeded';

  /// Sème les recettes d'exemple si ce n'est pas déjà fait. Non bloquant : en
  /// cas d'échec réseau, le flag n'est pas posé et on réessaiera au prochain
  /// lancement.
  Future<void> maybeSeedSampleRecipes() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_seededKey) ?? false) return;
    try {
      await _recipes.seedSamples();
      await prefs.setBool(_seededKey, true);
    } on RecipesRepositoryException {
      // Silencieux : onboarding facultatif, retenté au prochain démarrage.
    }
  }
}
