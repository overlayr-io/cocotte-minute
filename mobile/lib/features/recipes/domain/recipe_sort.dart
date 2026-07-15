import 'recipe.dart';

/// Critère de tri des listes de recettes (recherche avancée + page recettes,
/// vue Liste). Le tri par prix est volontairement absent : le prix est calculé
/// côté client (contrainte transverse), il n'y a pas de prix fiable à ordonner
/// sur le résumé de recette.
enum RecipeSort {
  recent('recent'),
  time('time'),
  name('name');

  const RecipeSort(this.wire);

  /// Valeur échangée avec l'API (`GET /recipes?sort=`).
  final String wire;
}

/// Tri client d'une liste de résumés — utilisé côté recherche (résultats non
/// paginés). `recent` conserve l'ordre reçu du serveur (récence / pertinence).
/// La page recettes, paginée, trie côté serveur (cf. `sort` de `fetchMine`).
List<RecipeSummary> sortRecipeSummaries(
  List<RecipeSummary> list,
  RecipeSort sort,
) {
  if (sort == RecipeSort.recent) return list;
  final sorted = [...list];
  switch (sort) {
    case RecipeSort.time:
      sorted.sort((a, b) => (a.prepTime + a.cookTime + a.restTime)
          .compareTo(b.prepTime + b.cookTime + b.restTime));
    case RecipeSort.name:
      sorted.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    case RecipeSort.recent:
      break;
  }
  return sorted;
}
