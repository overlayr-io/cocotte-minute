---
feature: recette-etapes
status: done        # planned | in-progress | done
scope: v1           # v1 | v2 | later
depends_on: [recette-base]
order: 6
---

# Étapes de recette

> **État de livraison (v1).** Onglet **Étapes** sur la fiche recette (le segment
> Ingrédients | Étapes est une vraie bascule). Écrans dérivés des maquettes
> **9b** (liste), 9c (vide, 2 entrées), 9d (import texte), 9e (composer une par
> une), 9f (édition + bannière), 9g (ingrédients de l'étape), 9h (modale de
> consultation). Pas de module serveur séparé : tout dans `RecipesService` /
> `RecipesController` et dans la feature mobile `recipes/`.
>
> **Modèle retenu.** Une étape est **texte** (`description` + bannière + ingrédients
> optionnels) **ou** une **référence de base** (`base_recipe_ref_id` seul) —
> exclusif, validé serveur. **Bannière = préréglage + texte** : `banner_type`
> (enum `warning|info|danger|learn`) + `banner_text` ; la couleur et l'icône sont
> dérivées du type côté client (**pas de `banner_color`**). Bannière affichée
> pleine largeur.
>
> **Dépliage récursif = côté serveur.** `GET /recipes/:id` renvoie `steps` déjà
> aplati : les blocs référence portent leurs sous-étapes dépliées récursivement,
> **anti-cycle**, une **référence dont la base est soft-deleted est omise** (ni
> recette ni étapes). Listes petites → pas de pagination. La numérotation globale
> continue est recalculée à l'affichage côté mobile (résiste au drag & drop).
>
> **Drag & drop livré.** Réordonnancement des étapes de premier niveau
> (`ReorderableListView`, poignée dédiée) ; le bloc référence se déplace comme une
> étape, mais **ses sous-étapes internes restent figées** (jamais réordonnées ni
> éditées depuis la recette parente).
>
> **Tables :** `recipe_steps` (position, description?, banner_type, banner_text?,
> base_recipe_ref_id?) + `step_ingredients` (step_id, ingredient_id — la table
> `recipe_ingredients` n'ayant pas d'id propre) ; migration `0007`.
>
> **Endpoints :** `POST /recipes/:id/steps`, `POST …/steps/import`,
> `PATCH …/steps/:stepId`, `DELETE …/steps/:stepId`, `PUT …/steps/order`,
> `PUT …/steps/:stepId/ingredients`.

## Problème résolu
Permettre de décrire le déroulé d'une recette étape par étape, tout en évitant
la duplication : si une recette de base (ex: béchamel) est utilisée dans une
autre recette (ex: lasagnes), ses étapes ne sont jamais réécrites — seulement
référencées et affichées au bon endroit.

## Comportement attendu

### Deux modes d'ajout d'étapes
1. **Import texte (textarea)** : l'utilisateur colle un texte, chaque saut de
   ligne entre deux paragraphes crée une étape distincte. Ce mode ne produit
   que des étapes texte simples — jamais de référence à une recette de base.
2. **Ajout pas à pas** : une fenêtre dédiée où l'utilisateur ajoute les étapes
   une par une (étape 1, étape 2, étape 3...).

### Structure d'une étape
- **Description** (texte) : toujours présente, obligatoire.
- Optionnellement, l'une des deux choses suivantes (pas les deux à la fois) :
    - **Bannière** : icône + couleur parmi warning, info, danger, learn.
    - **Référence à une recette de base** : insère l'ensemble des étapes de
      cette recette de base comme bloc, sans les dupliquer/copier.

### Référence à une recette de base (le point "tricky")
- Ajouter une recette de base comme étape n'importe ni ne copie son texte —
  c'est une **référence** vers cette recette de base.
- À l'affichage, l'ensemble des étapes de la recette de base référencée affiché
  à la place du bloc de référence.
- **Récursif** : si cette recette de base contient elle-même une référence
  vers une autre recette de base, ses étapes sont également affichées en
  cascade (jamais réécrites, toujours affichées par référence).
- Le bloc de référence recette de base, en tant qu'élément de la liste
  d'étapes de la recette parente, **peut être réordonné** comme une étape
  texte normale (drag & drop).
- En revanche, **les étapes internes de la recette de base référencée ne
  peuvent jamais être réordonnées ni modifiées** depuis la recette parente —
  elles restent figées telles que définies dans la recette de base d'origine.

### Réordonnancement (drag & drop)
- Un seul ordre global : étapes texte et blocs "référence recette de base"
  sont mélangés dans la même liste ordonnée et peuvent être réordonnés
  librement entre eux.

## Ajout — liaison ingrédient ↔ étape (ajouté suite à la feature mode-pas-a-pas)

### Comportement attendu
- Chaque étape peut référencer un sous-ensemble des ingrédients déjà listés
  sur la recette (pas de nouvel ingrédient créé au niveau de l'étape —
  uniquement une sélection parmi ceux déjà ajoutés à la recette globale).
- Sert à afficher, dans le mode pas-à-pas, uniquement les ingrédients
  concernés par l'étape en cours.

### Impact technique (ajout)
- Table `step_ingredients` (step_id, recipe_ingredient_id) — table de liaison,
  many-to-many entre `recipe_steps` et `recipe_ingredients`.

## Impact technique
- Server :
    - Table `recipe_steps` (id, recipe_id, order, description,
      banner_type nullable, banner_color nullable, base_recipe_ref_id nullable).
    - `banner_type/banner_color` et `base_recipe_ref_id` sont mutuellement
      exclusifs (contrainte de validation : jamais les deux remplis en même temps).
    - Validation serveur : `base_recipe_ref_id` ne peut pointer que vers une
      recette avec `is_base = true`.
    - Endpoint de récupération des étapes d'une recette doit résoudre
      récursivement les références aux recettes de base
      avant de retourner la réponse, ou laisser le mobile résoudre récursivement
      via des appels successifs (à trancher à l'implémentation).
- Mobile : feature `recipe_steps/` intégrée à `recipes/`, UI drag & drop pour
  réordonner, rendu récursif de l'affichage des étapes imbriquées.
- DB : `recipe_steps`.

## Règles métier spécifiques
- Une étape a toujours une description (sauf si référencé vers une recette de
  base).
- Une étape a soit une bannière (icône+couleur), soit une référence recette de
  base, jamais les deux, potentiellement aucun des deux.
- Une référence recette de base ne peut cibler qu'une recette avec `is_base = true`.
- Les étapes d'une recette de base référencée ne sont jamais copiées en base
  de données dans la recette parente — uniquement liées par `base_recipe_ref_id`.

## Hors scope pour cette feature
- Mode d'exécution pas-à-pas en cuisine (feature séparée `mode-pas-a-pas`).
- Gestion du cas où la recette de base référencée est supprimée/soft-deleted
  (comportement d'affichage non précisé ici).

## Questions ouvertes / à trancher (tranchées)
- **Réf. de base soft-deleted** → le bloc de référence est **omis** de l'affichage
  (ni recette ni étapes ; la numérotation saute), la ligne `recipe_steps` reste en
  base (réapparaît si la base est restaurée). L'utilisateur peut la retirer.
- **Résolution récursive** → **côté serveur** : `GET /recipes/:id` renvoie l'arbre
  déjà déplié et numéroté (une seule requête), pas d'appels successifs mobile.