---
feature: ingredients
status: done        # planned | in-progress | done
scope: v1           # v1 | v2 | later
depends_on: [auth]
order: 2
---

# Ingrédients

## Problème résolu
Fournir une base d'ingrédients réutilisable, avec un catalogue de départ fourni
par le système (pour éviter à chaque utilisateur de tout créer de zéro) tout en
permettant une personnalisation complète une fois importé.

## Comportement attendu

### Propriétés d'un ingrédient
- Nom
- Image
- Unité de mesure (gramme, milligramme, pièce, cuillère à café, cuillère à soupe)
    - Choisie à la création de l'ingrédient.
    - Modifiable ensuite par l'utilisateur.

### Ingrédients système vs ingrédients utilisateur
- Le système fournit un catalogue de base d'ingrédients ("ingrédients système").
- Un utilisateur peut "importer" un ingrédient système : cela crée une **copie
  indépendante** propre à cet utilisateur (pas une référence partagée), avec un
  lien conservé vers l'ingrédient système d'origine.
- Une fois importée, la copie est personnalisable librement (nom, image, unité)
  sans impacter l'ingrédient système original ni les copies des autres utilisateurs.
- Un utilisateur peut aussi créer un ingrédient entièrement custom (sans passer
  par l'import), avec les mêmes propriétés.

### Alternatives
- Un ingrédient peut avoir n ingrédients alternatifs.
- Une "alternative" est elle-même un ingrédient à part entière (même structure,
  pas de type spécial "alternative").
- La relation est **symétrique** : si A est déclaré alternative de B, B devient
  automatiquement alternative de A (pas besoin de déclarer les deux sens
  manuellement).

### Suppression
- Soft delete uniquement : un ingrédient supprimé garde sa référence en base
  (pour ne pas casser les recettes qui l'utilisent), marqué comme supprimé
  plutôt que réellement effacé.
- Un ingrédient importé depuis le système garde la notion de "provient du
  système" même après import, mais peut être soft-deleted par l'utilisateur
  (seule sa copie est affectée, jamais l'ingrédient système original).

### Ingrédients du système
- Les ingrédients du système sont créés à partir d'un fichier config en json 
  qui peut être importé en lancant via un script.  

## Impact technique
- Server :
    - Table `ingredients` avec un champ distinguant type système vs copie utilisateur
      (ex: `owner_id` nullable — null = ingrédient système, sinon appartient à un user).
    - Champ de lien vers l'ingrédient système d'origine en cas d'import
      (ex: `imported_from_id`).
    - Champ `deleted_at` (soft delete) plutôt que suppression réelle.
    - Table pivot `ingredient_alternatives` gérant la relation symétrique — à
      trancher techniquement : soit stocker les deux sens à l'écriture, soit
      stocker un seul sens et déduire la symétrie côté requête (à voir à
      l'implémentation).
- Mobile : feature `ingredients/` (Bloc), avec vue "catalogue système"
  distincte de "mes ingrédients importés/créés".
- DB : `ingredients`, `ingredient_alternatives`.

## Règles métier spécifiques
- Un ingrédient système (`owner_id = null`) ne peut jamais être modifié ni
  soft-deleted directement par un utilisateur — seule sa copie importée peut l'être.
- La relation alternative doit toujours rester symétrique, y compris à la
  suppression d'un lien (si on retire A comme alternative de B, retirer aussi
  B comme alternative de A).

## Hors scope pour cette feature
- Le cas "un ingrédient peut être une recette de base (ex: béchamel)" —
  explicitement mentionné comme évolution future, pas dans cette feature.
- Liaison ingrédient ↔ recette/étape — sera traité dans la feature recette.
- Interface d'administration pour gérer le catalogue système d'ingrédients
  (comment le système lui-même crée ses ingrédients de base n'est pas définie ici).

## Questions ouvertes / à trancher
- Qui/comment le catalogue système d'ingrédients est-il créé initialement
  (seed manuel, script, interface admin future) ?
- Stockage de la symétrie des alternatives : lignes dupliquées (A→B et B→A)
  ou déduction à la lecture (une seule ligne, requête bidirectionnelle) ?

## Réalisation (fait)

Questions ouvertes tranchées à l'implémentation :
- **Catalogue système** : seedé via un **script** (`npm run db:seed:ingredients`
  → `server/scripts/seed-ingredients.ts`) à partir d'un fichier JSON. Pas
  d'interface admin (hors scope confirmé).
- **Symétrie des alternatives** : **une seule ligne canonique** par paire
  (`low_id < high_id` + index unique), symétrie déduite à la lecture (requête
  bidirectionnelle). Pas de doublon A→B / B→A.

### Backend
- Table `ingredients` (`owner_id` nullable = système vs copie user, `imported_from_id`,
  `unit` enum, `deleted_at` soft delete) + pivot `ingredient_alternatives`.
- Endpoints : `GET /ingredients`, `GET /ingredients/system` (annoté
  `alreadyImported`), `GET /ingredients/:id` (avec alternatives),
  `POST /ingredients`, `POST /ingredients/:id/import` (409 si déjà importé),
  `PATCH /ingredients/:id`, `DELETE /ingredients/:id` (soft delete),
  `POST`/`DELETE /ingredients/:id/alternatives[/:altId]`.
- Un ingrédient système est non modifiable/supprimable par un user (403). Purge
  branchée dans le « repartir de zéro ».

### Mobile
- Écran `IngredientsPage` : onglets « Mes ingrédients » / « Catalogue système »
  (avec import + badge « déjà importé ») + recherche. Page détail avec édition
  nom/unité, gestion des alternatives (picker), suppression. Bottom-sheet de
  création (nom + unité).

### Gap connu
- **Image** : le champ `imageUrl` existe (URL externe) mais **l'upload réel
  d'image n'est pas branché** (pas de widget d'upload) — à faire ultérieurement.