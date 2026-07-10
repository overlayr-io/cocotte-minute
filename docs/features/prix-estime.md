---
feature: prix-estime
status: planned
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
- **Premium** : bas + haut renseignés via un slider (maquette à venir). La
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
- Nouvelle table `ingredient_prices` (clé composite `user_id + ingredient_id`) :
  `user_id`, `ingredient_id`, `price_reference_unit` (enum: `kilogram`,
  `litre`, `piece`), `low_price` numeric(10,3) nullable, `high_price`
  numeric(10,3) nullable, `average_price` numeric(10,3) nullable,
  `updated_at`.
  - `low_price`/`high_price` : écriture bloquée serveur si l'utilisateur
    n'est pas premium (403).
- `recipes` : ajout de `price_mode` (enum: `calculated` | `fixed`, défaut
  `calculated`) et `fixed_price` numeric(10,2) nullable (rempli seulement si
  `price_mode = fixed`).
- Endpoints : lecture/écriture de `ingredient_prices` (par utilisateur), PATCH
  du mode de prix + prix étiquette sur une recette. Aucun endpoint de calcul
  de total — c'est une contrainte transverse actée.
- Migration Drizzle à prévoir pour les deux ajouts.

### Mobile
- Écran de gestion d'ingrédient : ajout du bloc prix (champ unique moyen en
  gratuit, slider bas/moyen/haut en premium selon maquette à venir).
- Fiche recette : bloc prix (moyen, mode calculé/étiquette, icône
  avertissement si incomplet).
- Écran de sélection de recettes (liste de courses) et liste générée : total
  en direct, recalculé localement à chaque changement de sélection/case
  cochée/remplacement.
- Cache local des prix ingrédients nécessaire pour le calcul offline,
  cohérent avec le pattern déjà utilisé pour tags/personnes/catégories
  (`JsonListCache`) et avec le mode offline-first Drift de la liste de
  courses.

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

## Questions ouvertes / à trancher
- UX exacte de conversion "frustration → premium" quand un non-abonné voit
  le champ prix moyen sans slider (CTA visible ou non vers l'écran premium) —
  non cadré, à décider à l'implémentation.
- Maquette du slider bas/moyen/haut : en attente, à fournir avant
  l'implémentation mobile.
- Emplacement exact de saisie du prix (uniquement depuis la fiche ingrédient,
  ou aussi accessible directement depuis la fiche recette au niveau de chaque
  ligne d'ingrédient) — non tranché explicitement.
