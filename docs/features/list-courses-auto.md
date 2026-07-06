---
feature: liste-courses-auto
status: planned     # planned | in-progress | done
scope: v1           # v1 | v2 | later
depends_on: [auth, ingredients, recette-base]
order: 8
---

# Liste de courses automatique

## Problème résolu
Générer automatiquement une liste de courses à partir des recettes qu'un
utilisateur prévoit de cuisiner, en agrégeant les ingrédients nécessaires,
plutôt que de recopier manuellement chaque recette.

## Comportement attendu

### Création d'une liste
1. L'utilisateur sélectionne une ou plusieurs recettes qu'il souhaite faire.
2. Pour chaque recette sélectionnée, il choisit pour combien de personne et 
   les ingrédients dont il a réellement besoin (pas obligatoirement tous — 
   il peut en désélectionner, ex: s'il a déjà du sel chez lui).
3. Le système agrège l'ensemble en une liste de courses.

### Agrégation des quantités
- Si un même ingrédient est utilisé dans plusieurs recettes sélectionnées,
  les quantités sont **additionnées automatiquement** en une seule ligne.
- Une note/détail est affichable sous la ligne agrégée, montrant le détail
  du calcul (ex: "20g + 15g + 10g").

### Articles libres
- L'utilisateur peut ajouter manuellement des articles à la liste qui ne
  proviennent d'aucune recette (ex: un article oublié, un produit non
  culinaire).

### Plusieurs listes
- Plusieurs listes de courses peuvent exister en parallèle.
- Un historique des listes est conservé (pas de suppression automatique
  après usage).
- tout est sauvegarder localement !

### Pendant les courses
- L'utilisateur peut cocher les ingrédients récupérés.
- Si un ingrédient n'est pas trouvé en magasin, l'utilisateur peut cliquer
  dessus et choisir une des alternatives déjà définies pour cet ingrédient
  (cf. feature `ingredients`).
- Ce remplacement par une alternative **modifie uniquement l'affichage dans
  la liste de courses** — la recette d'origine n'est jamais modifiée.

### Modes d'affichage
- Vue "par recette" : ingrédients regroupés sous le nom de chaque recette
  sélectionnée.
- Vue "tout regroupé" : liste unique agrégée, tous ingrédients confondus,
  toutes recettes mélangées.
- L'utilisateur peut basculer entre les deux vues.

## Ajout — Mode offline-first

### Comportement attendu
- La liste de courses doit être créable, consultable et modifiable (cocher
  des articles, ajouter un article libre, choisir une alternative)
  **entièrement en local, même si l'appareil n'a jamais eu de connexion
  depuis un moment** (pas seulement une coupure temporaire).
- Dès que la connexion revient, synchronisation automatique en arrière-plan
  avec le serveur, sans action manuelle de l'utilisateur.
- En cas de conflit (même liste modifiée sur deux appareils, l'un ayant été
  offline) : la modification la plus récente (par timestamp) écrase l'ancienne
  côté serveur. Accepté comme limite du v1, pas de fusion intelligente.

### Impact technique (ajout)
- Mobile : nécessite une base de données locale persistante (ex: `sqlite`/`drift`,
  ou `hive`/`isar`) pour stocker les listes de courses et leurs items — pas
  uniquement un cache mémoire ou un cache HTTP classique.
- Chaque item de liste doit avoir un timestamp de dernière modification
  (`updated_at` local) pour permettre la logique "le plus récent gagne" à
  la synchronisation.
- File d'attente de synchronisation (queue d'actions à rejouer : coché,
  ajouté, remplacé par alternative) déclenchée automatiquement à la
  détection du retour réseau (ex: package `connectivity_plus`).
- Server : doit accepter une écriture avec un timestamp client fourni par
  le mobile (pas uniquement `updated_at` généré serveur), pour permettre
  la comparaison "plus récent gagne" au moment de la synchronisation.

## Impact technique
- Server :
    - Table `shopping_lists` (id, owner_id, name/label, created_at).
    - Table `shopping_list_items` (shopping_list_id, ingredient_id nullable,
      custom_label nullable, quantity, is_checked, replaced_by_alternative_id nullable).
        - `ingredient_id` rempli si l'item provient d'une recette/ingrédient existant.
        - `custom_label` rempli si c'est un article libre (pas d'ingrédient lié).
    - Table `shopping_list_recipes` (shopping_list_id, recipe_id) — pour garder
      la trace de quelles recettes ont généré cette liste (nécessaire pour la
      vue "par recette").
    - Endpoint de génération : reçoit une liste de recipe_id + ingrédients
      sélectionnés par recette, retourne la liste agrégée calculée.
- Mobile : feature `shopping_list/` (Bloc), écran de sélection de recettes →
  sélection d'ingrédients par recette → écran liste générée avec toggle
  vue par recette / vue globale, cases à cocher, sélection d'alternative
  au clic sur un item.
- DB : `shopping_lists`, `shopping_list_items`, `shopping_list_recipes`.

## Règles métier spécifiques
- L'agrégation de quantités ne fonctionne que si l'unité est identique entre
  les usages du même ingrédient (l'unité étant fixée sur l'ingrédient lui-même,
  cf. feature `ingredients`, ce cas ne devrait pas se poser en pratique).
- Le remplacement par une alternative est propre à l'item de la liste de
  courses (`replaced_by_alternative_id`), jamais propagé à `recipe_ingredients`.

## Hors scope pour cette feature
- Partage d'une liste de courses entre plusieurs comptes/personnes.
- Synchronisation avec une app tierce (Google Keep, etc.).
- Suggestion automatique d'articles non liés à une recette.

## Questions ouvertes / à trancher
- Une liste de courses peut-elle être régénérée/mise à jour si l'utilisateur
  modifie sa sélection de recettes après coup, ou faut-il créer une nouvelle
  liste à chaque fois ?
- Faut-il un nom/label personnalisable par liste (ex: "Courses de la semaine")
  ou un nom généré automatiquement (date de création) ?
- Cette nécessité de DB locale offline-first ne concerne-t-elle QUE la liste
  de courses, ou est-ce une brique d'architecture mobile transverse à prévoir
  dès maintenant pour d'autres features (ex: consultation de recettes hors-ligne) ?
- Que se passe-t-il si une liste de courses est créée entièrement en local
  et que l'utilisateur désinstalle l'app avant toute synchronisation (perte
  de données, cf. règle déjà actée pour les comptes anonymes) ?