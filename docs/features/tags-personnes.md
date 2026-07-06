---
feature: tags-personnes
status: planned     # planned | in-progress | done
scope: v1           # v1 | v2 | later
depends_on: [auth]
order: 3
---

# Tags & Personnes

## Problème résolu
Permettre de qualifier les recettes/sous-recettes selon des critères libres
(régime alimentaire, type de viande, etc.) et de relier ces critères aux
membres de la famille de l'utilisateur, pour mettre en avant les recettes
adaptées à qui on cuisine.

## Comportement attendu

### Tag
- Propriétés : nom, couleur lié au compte utilisateur (créé par lui).
- Contexte d'usage : uniquement recette, sous-recette et personne (pas
  d'autre entité pour l'instant).
- Une recette peut avoir plusieurs tags.
- Utilisable plus tard dans une recherche avancée (filtrage par tag).
- Exemples donnés : végétarien, viande, poulet, sans gluten.

### Personne
- Propriétés : nom, avatar.
- Gérée dans les settings de l'application dans Famille.
- Propre à chaque compte utilisateur (chacun gère sa propre liste de personnes,
  pas de partage entre comptes).
- Une personne peut avoir 0 à n tags (ex: associer "végétarien" à un membre
  de la famille).

### Usage de la liaison Personne ↔ Tags
- Sert à filtrer/mettre en avant les recettes dont les tags correspondent aux
  tags de la ou des personnes sélectionnées (ex: cuisiner pour telle et telle
  personne → recettes compatibles mises en avant).

## Impact technique
- Server :
    - Table `tags` (id, name, owner_id).
    - Table `people` (id, name, avatar, owner_id).
    - Table pivot `person_tags` (person_id, tag_id).
    - Table pivot `recipe_tags` (recipe_id, tag_id) — pour lier tags et recettes.
- Mobile : feature `tags/` et `people/` (Bloc), écran de gestion dans les
  Settings pour créer/gérer les Personnes et leur associer des tags.
- DB : `tags`, `people`, `person_tags`, `recipe_tags`.

## Règles métier spécifiques
- Un tag appartient à un seul compte utilisateur (pas de tag partagé/système
  pour l'instant, contrairement aux ingrédients).
- Une Personne appartient à un seul compte utilisateur.

## Hors scope pour cette feature
- Recherche avancée par tag : mentionnée comme usage futur, pas implémentée ici.
- Tags système/prédéfinis fournis par l'application (à l'inverse des ingrédients,
  rien n'indique que les tags aient un catalogue système de départ — non traité ici).

## Questions ouvertes / à trancher
