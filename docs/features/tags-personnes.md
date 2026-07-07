---
feature: tags-personnes
status: done        # planned | in-progress | done
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

## Réalisation (2026-07-07)

Livré en 2 phases (tags d'abord, personnes ensuite). Écarts assumés par rapport
au plan initial, validés avec le PO :

### Écrans (mobile)
- **Tags et Personnes sont deux écrans distincts**, pas un seul écran « Famille »
  unifié : ligne « Tags » (Compte › Mon contenu) → `TagsPage` ; ligne
  « Personnes » (Compte › Ma famille) → `FamillePage`.
- **Création d'un tag** = bottom-sheet (nom + couleur parmi une palette fermée de
  6 couleurs + aperçu). Édition/suppression via la même sheet.
- **Personne = prénom (requis) + nom (optionnel) + avatar**. L'avatar réel
  (upload) n'est pas branché : un avatar par défaut (initiale + couleur stable)
  est dérivé côté client.
- **Les tags ne sont PAS proposés à la création d'une personne** : la sheet de
  création ne saisit que prénom/nom/avatar. L'association des tags se fait
  ensuite dans une **page d'édition** dédiée (`PersonEditPage`), où les tags du
  compte se **tapent/détapent** (toggle). Suppression en action d'AppBar,
  enregistrement épinglé en bas d'écran.
- Convention transverse : le bouton **Créer/Ajouter** est toujours une **action
  trailing d'AppBar** (Tags + Famille), jamais un bouton au milieu de l'écran.
  État vide = caption grise centrée.

### Backend
- Tables créées : `tags` (owner non-null, `color` hex issu d'une palette fermée,
  soft delete), `people` (prénom/nom/avatar, owner, soft delete), pivot
  `person_tags` (FK cascade, index unique). Migrations `0001_tags.sql`,
  `0002_people.sql`.
- Endpoints : `GET/POST/PATCH/DELETE /tags` ; `GET/POST/PATCH/DELETE /people`
  + `POST /people/:id/tags` et `DELETE /people/:id/tags/:tagId`.
- Unicité du nom de tag (insensible à la casse) par compte. Ownership vérifié
  partout. `PeopleService` hydrate les tags associés via `TagsService`
  (isolation des modules — pas d'accès croisé au schéma).
- Purge `tags` + `people` branchée dans le « repartir de zéro » (account reset).

### Reporté (hors périmètre effectif)
- **Table pivot `recipe_tags` NON créée** : elle dépend d'une table `recipes`
  qui n'existe pas encore (feature recettes non implémentée). À faire avec la
  feature recettes. En conséquence, le **compteur de recettes par tag
  (`recipeCount`) renvoie 0 en dur** pour l'instant (l'UI l'affiche déjà).
- Filtrage/recherche par tag : toujours hors scope (usage futur).
