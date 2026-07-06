---
feature: categories
status: planned     # planned | in-progress | done
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

## Hors scope pour cette feature
- Tags (feature séparée, `tags-personnes.md`) — catégorie et tag sont deux
  concepts distincts, ne pas les fusionner.
- Limite de profondeur d'imbrication : non précisée, à trancher à l'implémentation
  si besoin (illimité par défaut sauf indication contraire).

## Questions ouvertes / à trancher
- Une catégorie peut-elle être supprimée si elle contient encore des
  sous-catégories ou des recettes ? (cascade, blocage, ou détachement automatique
  à définir avant l'implémentation)
- Soft delete ou suppression réelle pour les catégories ? (non précisé, à l'inverse
  des ingrédients où le soft delete a été explicitement demandé)