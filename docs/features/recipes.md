---
feature: recette-base
status: done        # planned | in-progress | done
scope: v1           # v1 | v2 | later
depends_on: [auth, ingredients, tags-personnes, categories]
order: 5
---

# Recette (CRUD de base)

> **État de livraison (v1).** Écrans dérivés des maquettes 1d (création),
> 2d (fiche détail) et **8a/8b/8c (ajout d'ingrédient)** — une seule page pour
> recette normale et de base, sections conditionnelles sur `isBase`. Fiche détail
> avec **photo fixe en fond et corps qui remonte au scroll** (photo `Positioned` +
> contenu en `CustomScrollView`).
>
> **Ingrédients dans les recettes (livré).** `recipe_ingredients` porte une
> **quantité** (`quantity numeric(10,2)`, migration `0006`) ; l'unité n'est jamais
> stockée sur la ligne, toujours **lue depuis `ingredients.unit`**. Ajout depuis le
> mobile branché (feuilles 8a/8b/8c : sélection multiple, import système, création
> auto-sélectionnée), édition de quantité et retrait sur la fiche. Saisie de
> quantité par stepper (pas dépendant de l'unité) + clavier décimal. Le serveur
> fait un **upsert** à l'ajout (`PATCH …/ingredients/:id` pour la quantité seule).
>
> **Segment Ingrédients | Étapes (livré).** Vraie bascule sur la fiche : l'onglet
> **Étapes** est actif (feature `recette-etapes`, écrans 9b-9h) — liste
> réordonnable en drag & drop, étapes texte/bannière et références de recette de
> base dépliées récursivement. Voir `docs/features/recipe-steps.md`.
>
> **Portions.** Le stepper Portions fait varier les quantités **affichées**
> (`quantité × portions / servings`) : **scaling d'affichage local et éphémère,
> jamais persisté** ; repart de `servings` (défaut **1**) à chaque ouverture.
>
> **Toujours hors périmètre (features dédiées) :** bouton Play / mode pas-à-pas,
> galerie, note ⭐, bouton Suivre.
>
> **Pivots dette branchés :** `recipe_categories` et `recipe_tags` créés ; les
> `recipeCount` réels sont désormais renvoyés par Tags et Catégories (via
> `RecipesService`, dépendance à sens unique). L'assignation catégorie/tag ↔
> recette existe côté serveur (endpoints) mais son UI mobile est différée.
>
> **Onglet Recettes = vue Dossiers (livré, maquette 7b).** L'onglet Recettes
> n'affiche plus une liste plate : c'est désormais la vue **Dossiers** de la
> feature `categories` (titre, recherche **placeholder visuel** non branchée,
> cartes de dossiers racines « N recettes · M sous-dossiers », bouton « Nouveau
> dossier », FAB corail pour créer une recette). Ouvrir un dossier liste ses
> recettes via le nouvel endpoint `GET /categories/:id/recipes`
> (`RecipesService.listByCategory`, pivot `recipe_categories`, tri récent) —
> chargement non bloquant (`FolderRecipesCubit`), carte partagée
> `RecipeListCard`. Compte → Catégories reste accessible séparément (création
> de sous-dossiers). La vue **Découverte** du 7b (bascule Dossiers/Découverte,
> hero à la une, rangées par saison/temps/personne) n'a **pas** été construite :
> aucune donnée serveur pour l'alimenter (pas de champ saison, pas de requête
> par personne) — différée, décision explicite.
>
> **Différé (non bloquant) :** ajout de **composant / sous-recette** depuis le
> mobile (picker) — l'endpoint serveur existe déjà ; upload de photo réel.

## Problème résolu
Domaine métier central de l'application : permettre la création et la gestion
complète d'une recette, avec la distinction fondamentale recette normale /
recette de base dès la création.

## Comportement attendu

### Flow de création
1. L'utilisateur saisit : nom (obligatoire), photo (optionnelle), toggle
   "recette de base" (important, décidé dès la création).
2. Une fois créée, redirection automatique vers la page Détail de la recette.
3. Depuis la page Détail, toutes les modifications ultérieures sont possibles
   (description, temps, ingrédients, étapes, etc.).

### Propriétés d'une recette
- Nom (obligatoire)
- Photo (optionnelle)
- Description (optionnelle)
- Flag "recette de base" (booléen, défini à la création)
- Temps de préparation (défaut 0)
- Temps de cuisson (défaut 0)
- Temps de pause (défaut 0)
- Nombre de personnes (défaut 0)
- Auteur / créateur (lié à l'utilisateur, via feature auth)
- Étapes (traitées dans une feature séparée, `recette-etapes`) (vide par défault)
- Ingrédients (liste d'ingrédients utilisés, via feature ingredients) (vide par défault)
- Recettes de base utilisées comme composants (si la recette en intègre) (vide par défault)

### Page Détail — informations affichées
- Le créateur de la recette
- Les ingrédients ajoutés
- Les étapes (traité plus tard dans `recette-etapes`)
- Les sous-recettes utilisées par cette recette (composants)
- Si la recette EST elle-même une recette de base : liste des recettes qui
  l'utilisent comme composant (relation inverse — "où est-elle utilisée")

### Règle de verrouillage recette de base ↔ normale
- Une recette de base peut intégrer d'autres recettes de base comme composants
  (imbrication autorisée entre recettes de base).
- Une recette normale ne peut jamais être utilisée comme composant dans une
  autre recette (seules les recettes de base le peuvent).
- Une fois qu'une recette de base a été utilisée comme composant dans au moins
  une autre recette, elle **ne peut plus être repassée en recette normale** —
  le flag est verrouillé tant que cette utilisation existe.

## Ajout d'ingrédient à une recette (précision recipe_ingredients)

### Comportement attendu
- Depuis la recette, l'utilisateur ajoute un ingrédient :
    - soit en sélectionnant un ingrédient qu'il a déjà créé/importé précédemment,
    - soit en créant un nouvel ingrédient directement depuis cette interface
      (puis il est automatiquement sélectionné).
- Une fois l'ingrédient renseigné, l'utilisateur indique la **quantité**
  (ex: 20 grammes, 2 cuillères à soupe).
- L'**unité utilisée est toujours celle définie sur l'ingrédient** — pas de
  choix d'unité différente ligne par ligne. Si l'utilisateur veut une unité
  différente pour un usage ponctuel, il doit modifier l'unité de l'ingrédient
  lui-même (impacte alors toutes ses utilisations).
- Cette structuration (ingrédient + quantité par recette) sert deux objectifs :
    1. Affichage clair des ingrédients dans la page Détail de la recette.
    2. Recherche avancée : retrouver des recettes à partir d'ingrédients demandés
       (feature `recherche-par-ingredients`, plus tard dans l'ordre).

## Impact technique (mise à jour)
- Table `recipe_ingredients` (recipe_id, ingredient_id, quantity) — pas de
  champ unité sur cette table, l'unité est toujours lue depuis `ingredients.unit`.

### Suppression
- Soft delete uniquement

## Impact technique
- Server :
    - Table `recipes` (id, name, photo, description, is_base, prep_time,
      cook_time, rest_time, servings, author_id).
    - Table `recipe_ingredients` (recipe_id, ingredient_id, + quantité — à définir
      dans une feature ultérieure liant ingrédients et recettes précisément).
    - Table `recipe_components` (parent_recipe_id, base_recipe_id) — lien recette
      → sous-recette utilisée, uniquement si `base_recipe.is_base = true`.
    - Validation serveur obligatoire : impossible d'insérer dans
      `recipe_components` une recette dont `is_base = false`.
    - Validation serveur obligatoire : impossible de passer `is_base` de true à
      false si la recette apparaît déjà comme `base_recipe_id` dans
      `recipe_components`.
- Mobile : feature `recipes/` (Bloc), écran de création simplifié (étape 1),
  écran Détail complet avec toutes les sections (étape 2), toggle "recette de
  base" visible et clair dès la création.
- DB : `recipes`, `recipe_components`, `recipe_ingredients` (structure
  précise de cette dernière à affiner avec la feature ingrédients-quantités
  si elle existe séparément).

## Règles métier spécifiques
- Le flag `is_base` peut passer de false à true à tout moment sans contrainte.
- Le flag `is_base` ne peut PAS passer de true à false si la recette est
  référencée dans `recipe_components` en tant que `base_recipe_id`.
- Cette règle doit être appliquée côté server (pas seulement UI), cohérent
  avec ce qui a été acté dans `PROJECT_CONTEXT.md`.

## Hors scope pour cette feature
- ~~Les étapes détaillées~~ → **livré** (feature `recette-etapes`, écrans 9b-9h) :
  onglet Étapes actif, texte/bannière/référence de base, drag & drop.
- ~~La quantité précise par ingrédient~~ → **livré** : `recipe_ingredients.quantity`
  (`numeric(10,2)`), unité toujours lue depuis l'ingrédient. Voir l'en-tête.
- Le mode pas-à-pas d'exécution (feature séparée `mode-pas-a-pas`).

## Questions tranchées
- **Nombre de personnes par défaut = 1** (`DEFAULT_SERVINGS` serveur ≡
  `kDefaultServings` mobile). Une recette est utilisable dès sa création.
- **Une recette peut exister sans ingrédient ni étape** (brouillon) : aucune
  contrainte de complétude en v1 — on crée avec juste un nom puis on complète
  sur la fiche.