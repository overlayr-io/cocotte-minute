# Feature — « J'aime » (favoris de recettes)

> Item #15 du backlog. Permettre à l'utilisateur de marquer des recettes comme
> « J'aime » (favoris / à suivre) et de les retrouver dans une section dédiée.

## Décisions (validées)

- **Toggle** : une icône **cœur sur la fiche recette** (sur le hero) **+** une
  entrée « J'aime / Ne plus aimer » dans le menu « … ». Pas de cœur sur les
  cartes de liste (V1).
- **Section** : un **dossier virtuel « J'aime »** en tête de la page Recettes
  (même mécanique que le dossier virtuel « Autres » / non rangées), qui liste
  les recettes aimées.
- **Périmètre** : liste de favoris **personnelle** (pas de dimension sociale).
  « Suivre » = ajouter à J'aime.
- **Freemium** : **illimité pour tout le monde**, gratuit inclus. Décision
  révisée le 2026-07-15 : le plafond gratuit initial de 10 favoris a été
  **retiré** (code `PREMIUM_LIMIT_FAVORITES` supprimé de bout en bout). Aimer
  une recette est un geste de confort, pas un levier d'upsell.

## Modèle de données

- Table `recipe_favorites` : `(user_id uuid, recipe_id uuid, created_at)`,
  PK composite `(user_id, recipe_id)`, FK `recipe_id → recipes.id` cascade.
- L'utilisateur favorise **ses propres recettes** (les recettes sont déjà
  scopées par `author_id`). Un favori pointe donc toujours une recette possédée.
- Suppression d'une recette → cascade supprime ses favoris.

## API (module recipes — favoris scopés recette)

- `GET /recipes/favorites` → `RecipeSummaryDto[]` (recettes aimées, plus
  récemment aimées d'abord). Route déclarée **avant** `GET /recipes/:id`.
- `POST /recipes/:id/favorite` → 204. Ajoute (idempotent). Vérifie uniquement la
  propriété de la recette : aucun quota.
- `DELETE /recipes/:id/favorite` → 204. Retire (idempotent).
- `RecipeDetailDto` gagne `isFavorite: boolean` (renseigné pour le
  propriétaire ; `false` en lecture publique/partage).

## Freemium

- **Aucune limite** : les favoris sont illimités en gratuit comme en Pro.
- Le code `PREMIUM_LIMIT_FAVORITES`, la garde `assertFavoritesQuota` et la
  feuille d'upsell associée ont été retirés (serveur, mobile, i18n).

## Mobile

- `RecipesRepository` : `addFavorite`, `removeFavorite`, `fetchFavorites`.
- `RecipeDetail` : champ `isFavorite`. `RecipeDetailCubit.toggleFavorite`
  (optimiste).
- Fiche : bouton cœur sur le hero + entrée menu « … ».
- Page Recettes : dossier virtuel « J'aime » en tête → page liste des favoris
  (cubit dédié, calqué sur le dossier « Autres »).
- i18n FR/EN pour tous les libellés.

## Hors périmètre V1

- Cœur sur les cartes de liste / carrousels.
- Favoriser une recette d'un autre utilisateur (pas de recettes partagées
  persistées côté compte).
- Tri/filtre spécifique dans la section J'aime (réutilise l'ordre par date d'ajout).
