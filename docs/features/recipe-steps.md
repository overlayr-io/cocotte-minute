---
feature: recette-etapes
status: planned     # planned | in-progress | done
scope: v1           # v1 | v2 | later
depends_on: [recette-base]
order: 6
---

# Étapes de recette

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

## Questions ouvertes / à trancher
- Que se passe-t-il à l'affichage si la recette de base référencée dans une
  étape a été soft-deleted entre-temps ?
- La résolution récursive des étapes imbriquées se fait-elle côté server
  (une seule requête, réponse déjà dépliée) ou côté mobile (appels successifs) ?