# Feature — Nutrition manuelle (calories & macros)

> Item #8 du backlog. Permettre à l'utilisateur de saisir à la main les valeurs
> nutritionnelles d'une recette et de les afficher sur la fiche.

## Décisions (validées)

- **Champs** : calories (kcal) + macros **protéines / glucides / lipides** (g).
  Tous optionnels (null = non renseigné).
- **Échelle** : valeurs saisies **par portion** (convention des étiquettes).
  Affichage par portion ; possibilité de montrer un total = valeur × portions
  choisies.
- **Freemium** : **gratuit** pour tous, sans limite.
- Pas de calcul automatique depuis les ingrédients (saisie manuelle uniquement,
  cohérent avec « le calcul nutritionnel n'est pas dérivé »).

## Modèle de données

- 4 colonnes nullables sur `recipes`, PAR PORTION :
  `calories_per_serving`, `proteins_per_serving`, `carbs_per_serving`,
  `fats_per_serving` (`numeric(8,2)`).

## API

- Édition via `PATCH /recipes/:id` (comme description/prix) : `UpdateRecipeDto`
  gagne `caloriesPerServing` / `proteinsPerServing` / `carbsPerServing` /
  `fatsPerServing` (nombres ≥ 0, nullable = effacé).
- `RecipeDetailDto` expose les 4 valeurs (null si non renseigné). Pas dans le
  résumé (`RecipeSummaryDto`) : seule la fiche en a besoin.

## Mobile

- `RecipeDetail` : 4 champs nutrition nullable + parsing.
- Fiche édition : section « Nutrition (par portion) » avec 4 champs numériques
  optionnels.
- Fiche détail : carte nutrition affichant les valeurs renseignées (par portion),
  masquée si tout est vide.
- i18n FR/EN.

## Hors périmètre V1

- Calcul automatique depuis les ingrédients.
- Fibres, sel, autres micro-nutriments.
- Objectifs / suivi nutritionnel par personne.
