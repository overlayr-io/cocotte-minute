---
feature: prix-estime
status: done
scope: v1
depends_on: [ingredients, recette-base, liste-courses-auto, limite-freemium, premium-version]
order: 14
---

# Prix estimé (ingrédients, recettes, liste de courses)

## Problème résolu
Donner à l'utilisateur un ordre de grandeur du coût d'une recette et d'une
liste de courses, sans dépendre d'une source de prix externe (aucune API de
prix magasin fiable n'existe en France pour ce cas d'usage — confirmé lors du
cadrage). Le prix est donc **estimé à partir de saisies manuelles de
l'utilisateur**, jamais une vérité absolue.

## Comportement attendu

### Prix par ingrédient
- Chaque utilisateur définit son propre prix par ingrédient (même sur un
  ingrédient système partagé — deux utilisateurs peuvent avoir des prix
  différents pour le même ingrédient).
- Le prix est rattaché à une **unité de référence dédiée** (kilogramme, litre,
  ou pièce), indépendante de l'unité de quantité stockée sur l'ingrédient
  (gramme, milligramme, pièce, cuillère à café, cuillère à soupe) — avec
  conversion automatique au moment du calcul.
  - gramme/milligramme → référence kilogramme.
  - pièce → référence pièce (1:1).
  - cuillère à café/à soupe → référence kilogramme, via une constante de
    conversion générique (voir Règles métier). Pas de prix par densité
    d'ingrédient (v1).
  - litre existe comme unité de référence prévue, mais aucune unité de
    quantité "volume" n'existe encore côté ingrédients — donc inatteignable
    en pratique pour l'instant (réservé à une évolution future).
- Précision de saisie : 3 chiffres après la virgule sur le prix unitaire (bas,
  haut, moyen).
- Par défaut, sans aucune saisie : prix moyen = `null` (inconnu). Pas
  d'historique dans le temps — chaque saisie écrase la précédente, aucune
  conservation de versions successives.

### Différence gratuit / premium (prix ingrédient)
- **Gratuit** : un seul champ "prix moyen", saisi et modifiable directement à
  la main. Pas de bas/haut, pas de slider.
- **Premium** : bas + haut renseignés via un slider (règle graduée, écran 14c). La
  moyenne est calculée automatiquement (`(bas+haut)/2`) à chaque changement de
  bas/haut, mais reste ajustable ensuite en déplaçant un curseur "estimation"
  entre bas et haut (jamais en dehors de la fourchette).
- Vérification de la limite premium **côté serveur** (l'API rejette l'écriture
  de bas/haut si l'utilisateur n'est pas premium) — cohérent avec les autres
  limites freemium déjà appliquées côté serveur.
- Désabonnement : les valeurs bas/haut déjà saisies sont **conservées mais
  masquées** (pas de perte de données) ; seul le prix moyen reste visible et
  éditable tant que l'utilisateur n'est pas premium. Un réabonnement restaure
  l'affichage du slider avec les valeurs bas/haut préexistantes.

### Prix par recette
Deux modes, au choix explicite de l'utilisateur par recette :
- **Mode calculé** : somme des prix moyens des ingrédients de la recette,
  exprimée pour la base (`recipes.servings`) de la recette.
  - Scaling identique à celui des quantités : `prix affiché = prix base ×
    portionsChoisies / servings`.
  - Si un ou plusieurs ingrédients de la recette n'ont pas de prix renseigné :
    affichage `≈ prix€` (total partiel sur les ingrédients connus) + icône
    d'avertissement. Au clic/tap sur l'icône : tooltip "Des ingrédients n'ont
    pas de prix".
- **Mode étiquette (fixe)** : l'utilisateur saisit un prix global pour la
  recette, défini pour la base (`servings`) de la recette. Ce prix **scale
  aussi** proportionnellement aux portions affichées, exactement comme le
  mode calculé (ex: étiquette 10€ pour 2 personnes → 20€ affiché pour 4).
- Affichage fiche recette : uniquement le prix moyen (jamais de fourchette
  bas/haut affichée au niveau recette, même en premium).

### Prix dans la liste de courses
- Écran de sélection des recettes (avant génération) : le total affiché en
  direct est la **somme des prix de chaque recette sélectionnée**, scalée au
  nombre de personnes choisi pour chaque recette — pas une agrégation par
  ingrédient dédupliqué (un ingrédient partagé entre deux recettes est donc
  compté dans chacune des deux).
- Une fois la liste générée : le total continue d'être **recalculé en
  direct** au fil des cases cochées/décochées et des remplacements par
  alternative (le prix suit alors l'ingrédient effectivement affiché dans
  l'item, alternative comprise).
- Un article libre (sans ingrédient lié, `ingredientId` null) n'a pas de prix
  associable : il est simplement exclu du total.
- Absence totale de prix connu (aucun ingrédient renseigné) : afficher un état
  neutre "prix inconnu" plutôt que masquer complètement le bloc.

### Contrainte transverse
- **Tout le calcul (moyenne, scaling, agrégation, conversion d'unité) est
  effectué côté client (Flutter), jamais côté serveur.** Le serveur ne fait
  que stocker/retourner les valeurs saisies (bas, haut, moyenne, mode de prix
  recette, prix étiquette).

## Impact technique

### Server
- Table `ingredient_prices` (migration `0015_prix_estime`, clé composite
  `user_id + ingredient_id` via index unique) :
  `user_id`, `ingredient_id` (FK cascade), `price_reference_unit` (enum:
  `kilogram`, `litre`, `piece`), `low_price` numeric(10,3) nullable,
  `high_price` numeric(10,3) nullable, `average_price` numeric(10,3) nullable,
  `updated_at`.
  - `low_price`/`high_price` : écriture bloquée serveur si l'utilisateur
    n'est pas premium (403 nu — pas le format `PREMIUM_LIMIT_*` des quotas,
    puisque ce n'est pas une limite chiffrée mais un verrou de fonctionnalité
    binaire ; l'UI ne propose de toute façon ces champs qu'aux premium, ce 403
    est un garde-fou serveur, jamais un chemin normal).
  - Module `IngredientPricesModule` (`GET /ingredient-prices` liste complète
    par utilisateur, `PUT /ingredient-prices/:ingredientId` upsert) —
    accessible même sur un ingrédient système, via `IngredientsService.assertVisible`
    (existence + visibilité, sans exiger la possession).
- `recipes` : `price_mode` (enum: `calculated` | `fixed`, défaut `calculated`),
  `fixed_price` numeric(10,2) nullable, et `price_bracket` (enum:
  `under_5` | `from_5_to_10` | `from_10_to_20` | `over_20`, nullable — cf.
  section Badge tranche de prix ci-dessous). Les trois sont exposés/modifiables
  via l'endpoint `PATCH /recipes/:id` existant (DTO étendu), pas de nouvel
  endpoint.
- Aucun endpoint de calcul de total — contrainte transverse actée : le
  serveur ne fait que stocker/retourner les valeurs saisies (ou poussées par
  le client pour `price_bracket`, cf. ci-dessous).

### Mobile
- Fiche ingrédient (`ingredient_price_section.dart`) : bloc prix inséré entre
  l'unité de mesure et les alternatives — champ moyen simple en gratuit (avec
  aperçu verrouillé de la fourchette, CTA → écran Premium), règle graduée
  bas/estimation/haut en premium (glisser + tap pour une saisie précise, cf.
  Règles métier ci-dessous), état vide tant qu'aucun prix n'existe (quel que
  soit le palier — la bascule gratuit/premium ne se décide qu'au moment de
  saisir).
- Fiche recette (`recipe_price_section.dart`) : bloc juste après la carte
  Portions, toggle Calculé/Étiquette, avertissement (icône + tooltip au tap)
  si des ingrédients n'ont pas de prix, badge de tranche de prix (cf.
  ci-dessous).
- Liste de courses : total en direct à l'écran de sélection des recettes
  (étapes 1-2, somme par recette scalée — pas d'agrégation par ingrédient
  dédupliqué, se complète progressivement pendant le chargement des fiches) ;
  sur la liste générée, total des **articles restants non cochés**
  (recalculé à chaque case cochée/décochée ou remplacement par alternative,
  qui suit alors l'ingrédient effectivement affiché).
- Cache local des prix ingrédients (`IngredientPricesRepository`, pattern
  `JsonListCache` déjà utilisé pour tags/personnes/catégories — liste complète
  par utilisateur, jamais le mode offline-first Drift de la liste de courses).
- Calcul 100 % côté client (`core/pricing/price_calculator.dart` : conversion
  d'unité, agrégation, scaling ; `core/pricing/price_formatter.dart` :
  affichage/parsing) — le serveur ne fait que stocker.

### Badge tranche de prix (ajouté en cours de route, hors cadrage initial)
Décidé avec l'utilisateur après la maquette initiale (écrans 14b/14c/14d) :
un badge sur la fiche recette identifie une tranche de prix, pour permettre
une future section d'accueil filtrée (ex. « moins de 10€ »).
- Tranches : `< 5 €` / `5 – 10 €` / `10 – 20 €` / `> 20 €` (`RecipePriceBracket`,
  seuils dans `priceBracketForValue`).
- Calculée et poussée par le **client**, jamais par le serveur (même
  contrainte transverse que le reste de la feature) : synchronisée en tâche
  de fond (`RecipeDetailCubit._syncPriceBracket`) à chaque chargement/rechargement
  de la fiche recette, silencieuse et best-effort (jamais d'erreur affichée).
- Basée sur le prix de **base** (`servings`), jamais un prix déjà scalé par
  les portions affichées, ni un total partiel (`≈`) — absente tant que le
  prix n'est pas entièrement connu.
- Portée limitée à la fiche recette pour cette itération : les cartes
  compactes (accueil, listes, recherche) ne l'affichent pas encore —
  `RecipeSummary` ne porte ni prix ni tranche, il faudrait l'enrichir + 4
  endpoints serveur (`GET /recipes`, `/categories/:id/recipes`,
  `/search/recipes`, `/discovery/home`) et créer un composant badge partagé
  (aucun n'existe aujourd'hui, chaque carte réimplémente son propre pill).
  Reporté avec la section d'accueil elle-même à une itération dédiée.

## Règles métier spécifiques
- Prix propre à chaque utilisateur, y compris sur un ingrédient système
  partagé (jamais de prix partagé entre utilisateurs).
- Conversion cuillère → gramme (pour appliquer un prix au kilogramme) : constantes
  génériques fixes, indépendantes de la densité de l'ingrédient — 1 cuillère à
  café = 5 g, 1 cuillère à soupe = 15 g (équivalence volumique 5 mL / 15 mL,
  densité eau ≈ 1 g/mL). Usage conventionnel largement répandu en France,
  **pas une norme AFNOR officielle** — imprécision assumée et documentée.
- Moyenne premium toujours comprise dans `[bas, haut]` (jamais en dehors),
  calculée par défaut à `(bas+haut)/2`, ajustable via le curseur du slider.
- Aucun historique de prix : chaque saisie écrase la précédente.
- Affichage monétaire arrondi à 2 décimales ; stockage unitaire à 3 décimales.

## Hors scope pour cette feature
- Toute source de prix externe (API magasin, prix géolocalisés) — confirmé
  non réaliste en France pour ce projet.
- Historisation des prix dans le temps (graphique d'évolution, etc.).
- Prix par densité réelle de l'ingrédient pour la conversion cuillère→gramme.
- Agrégation par ingrédient dédupliqué pour le total pendant la sélection de
  recettes (choix acté : somme par recette, doublons possibles).
- Prix sur les articles libres de la liste de courses (sans ingrédient lié).
- Partage de prix entre utilisateurs.

## Décisions prises à l'implémentation
Les points laissés ouverts au cadrage ont été tranchés avec l'utilisateur
avant/pendant l'implémentation (écrans fournis 14b/14c/14d + échanges) :
- **Conversion frustration → premium** : CTA visible — un non-abonné voit un
  aperçu verrouillé (cadenas) de la fourchette bas/haut sous son champ prix
  moyen, qui ouvre l'écran Premium au tap (écran 14b).
- **Maquette du slider** : fournie (écran 14c) — règle graduée bas/estimation/haut,
  implémentée avec un ajout non présent sur la maquette : un tap sur Bas/Haut
  ouvre une saisie numérique précise en plus du glisser, nécessaire pour tenir
  les 3 décimales demandées (un glisser seul ne peut pas garantir cette
  précision sur un petit écran).
- **Emplacement de saisie** : fiche ingrédient uniquement — aucun champ prix
  depuis la fiche recette ou une ligne d'ingrédient.
- **Unité de référence** (kilogramme/pièce, litre toujours désactivée) :
  librement modifiable par l'utilisateur, indépendamment de l'unité de mesure
  de l'ingrédient (ex: un ingrédient mesuré en pièces peut avoir un prix au
  kilo). Si la combinaison est inconvertible (aucune conversion poids↔pièce
  sans densité), le prix est traité comme non renseigné dans tous les calculs.
