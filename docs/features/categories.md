---
feature: categories
status: done        # planned | in-progress | done
scope: v1           # v1 | v2 | later
depends_on: [auth]
order: 4
---

# Catégories

## Problème résolu
Permettre à l'utilisateur d'organiser ses recettes en dossiers (rangement
hiérarchique), à distinguer des tags qui servent au filtrage/qualification
plutôt qu'au rangement.

## Comportement attendu
- Une catégorie fonctionne comme un dossier pouvant contenir plusieurs recettes.
- Une recette peut appartenir à **plusieurs catégories** simultanément.
- Les catégories sont **imbricables** : une catégorie peut contenir d'autres
  catégories (sous-dossiers), comme une arborescence de dossiers.
- Créées librement par l'utilisateur, propres à son compte (pas de catalogue
  système comme pour les ingrédients).

## Impact technique
- Server :
    - Table `categories` (id, name, owner_id, parent_category_id nullable —
      pour l'imbrication).
    - Table pivot `recipe_categories` (recipe_id, category_id) — relation
      many-to-many.
- Mobile : feature `categories/` (Bloc), vue arborescente/navigation par
  dossiers, sélection multiple de catégories à l'assignation sur une recette.
- DB : `categories`, `recipe_categories`.

## Règles métier spécifiques
- Une catégorie appartient à un seul compte utilisateur.
- `parent_category_id` doit pouvoir être null (catégorie racine) ou pointer
  vers une autre catégorie du même utilisateur (pas de parent cross-compte).

## Décisions d'implémentation (tranchées avec l'utilisateur)
- **Dossiers par défaut** : Entrée, Plat, Dessert, Boisson, semés paresseusement
  au premier accès d'un compte (`is_default = true`). **Verrouillés** : nom +
  emoji figés, non renommables, non supprimables. On peut seulement créer des
  sous-dossiers à l'intérieur.
  - **Verrou consultatif obligatoire** (`pg_advisory_xact_lock`, cf.
    `common/db/advisory-locks.ts`) : `ensureDefaults` tourne à **chaque**
    `GET /categories`, et le motif « lire puis insérer si absent » sans verrou
    faisait semer les 4 défauts **deux fois** quand deux requêtes concurrentes
    tombaient sur un compte vierge (8 dossiers affichés en double). Bug corrigé
    le 2026-07-15. Aucune contrainte unique ne peut servir de repli : deux
    dossiers de même nom sous des parents différents sont légitimes.
- **Emoji** : chaque dossier peut porter un emoji système optionnel (colonne
  `icon`). Null = icône dossier par défaut à l'affichage.
- **Profondeur** : bornée à **5 niveaux, racine = niveau 1** (`CATEGORY_MAX_DEPTH`).
  Vérifiée côté serveur à la création.
- **Suppression** : **soft delete** (`deleted_at`), cohérent avec tags/personnes.
  **Bloquée si le dossier n'est pas vide** (sous-dossiers, et à terme recettes)
  → 409. Refusée pour les dossiers par défaut → 403.
- **Navigation** : drill-down (une page par dossier, récursive), bouton `+` en
  trailing d'AppBar (pas de bouton central). Écrans maquette : 3e (arborescence)
  + 3l adaptée (modale nouveau/éditer dossier).

## Hors scope pour cette feature
- Tags (feature séparée, `tags-personnes.md`) — catégorie et tag sont deux
  concepts distincts, ne pas les fusionner.
- **Pivot `recipe_categories` différé** : la table `recipes` n'existe pas encore,
  le pivot sera créé avec la feature recettes (même dette que `recipe_tags`).
  En conséquence `recipeCount` renvoie 0 en dur pour l'instant.
- **Déplacement d'un dossier** (changer son parent après création) : non prévu en
  v1 (le parent se choisit à la création uniquement).