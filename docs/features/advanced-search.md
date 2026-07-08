---
feature: recherche-avancee
status: done        # planned | in-progress | done
scope: v1           # v1 | v2 | later
depends_on: [recette-base, tags-personnes, categories, ingredients]
order: 9
---

# Recherche avancée

## Problème résolu
Permettre de retrouver rapidement une recette selon des critères multiples 
(nom, tags, personnes, ingrédients), avec un scope de recherche restreignable 
à une catégorie/dossier précis — dans l'esprit d'une recherche façon Notion 
(filtres combinables + scope de dossier).

## Comportement attendu

### Filtres du v1 (livrés)
- Recherche textuelle sur le **nom** de la recette.
- Filtre par **tags** (un ou plusieurs).
- Filtre par **personnes** (une ou plusieurs — via les tags associés à la 
  personne, cf. `tags-personnes.md`).
- Filtre par **catégorie/dossier** : restreindre la recherche à 
  l'intérieur d'une catégorie donnée (et ses sous-catégories, imbriquées 
  récursivement, cf. `categories.md`).

### Interaction retenue à l'implémentation : barre unique façon Notion
Plutôt qu'un panneau de filtres séparé, la recherche est **une seule barre** :
taper `/` ouvre l'autocomplétion dossiers, `#` l'autocomplétion tags (avec
création à la volée), `@` l'autocomplétion personnes ; trois boutons sous le
champ ouvrent les mêmes menus sans taper. Chaque sélection devient une
**pastille** affichée sous la ligne de saisie, cumulée avec les précédentes.
Le texte non préfixé reste la recherche libre par nom.

### Combinaison des filtres (tranchée avec le PO à l'implémentation)
- **Entre dimensions** (dossier / tag / personne / texte) : logique **ET** —
  une recette doit correspondre à TOUTES les dimensions actives.
- **Tags explicites** (si plusieurs sélectionnés) : **ET** — la recette doit
  porter tous les tags cochés.
- **Dossiers** (si plusieurs sélectionnés) : **OU**, et chaque dossier est
  déplié en incluant tous ses descendants (récursif).
- **Personnes** (si plusieurs sélectionnées) : la recette doit porter **au
  moins un** tag parmi l'union des tags de toutes les personnes sélectionnées
  (**OU**) — reste de son côté combiné en ET avec les autres dimensions.
- Évolution future prévue (pas dans ce v1) : une marge de pertinence 
  permettant de faire remonter des recettes correspondant à au moins un 
  des filtres entre dimensions (logique OU/scoring), pas encore définie précisément.

### Architecture pensée pour la future IA locale
- L'API de recherche doit être conçue avec des **paramètres structurés** 
  dès maintenant (ex: `{ name, tagIds[], personIds[], ingredientIds[], 
  categoryId }`), plutôt qu'une recherche ad hoc non réutilisable.
- Objectif : une future couche IA locale pourra traduire un prompt utilisateur 
  en ces mêmes paramètres structurés et appeler la même API de recherche, 
  sans qu'il soit nécessaire de recoder un endpoint dédié à l'IA plus tard.

## Impact technique
- Server :
  - Endpoint `GET /search/recipes` (params : `q`, `categoryIds[]`, `tagIds[]`,
    `personIds[]`), chemin choisi plutôt que `/recipes/search` pour ne pas
    entrer en collision avec la route `@Get(':id')` de `RecipesController`.
  - Nouveau **`SearchModule`** transverse (orchestration) qui importe
    `RecipesModule`/`CategoriesModule`/`PeopleModule` et délègue aux services
    propriétaires — acyclique car ces modules importent déjà `RecipesModule`
    pour leurs compteurs (dépendance à sens unique préexistante). Ne stocke ni
    n'interroge aucun schéma Drizzle directement.
  - `CategoriesService.expandWithDescendants` (déplie un dossier + ses
    descendants), `PeopleService.tagIdsForPeople` (union des tags d'une
    sélection de personnes), `RecipesService.search` (combine nom/dossiers/tags
    résolus, restreint à ses propres pivots `recipe_tags`/`recipe_categories`).
- Mobile : 
  - Feature `search/` (Cubit, pas Bloc — lecture seule + debounce), barre
    unique + pastilles (cf. ci-dessus) plutôt qu'un panneau de filtres séparé.
  - Cache passif : dossiers/tags/personnes chargés une seule fois au montage
    de l'écran (pas de refetch), cohérent avec `ENGINEERING_CONSTRAINTS.md`.
- DB : aucune nouvelle table — la recherche s'appuie sur les tables déjà 
  définies dans les features précédentes.

## Règles métier spécifiques
- Le filtre "personnes" recherche les recettes dont les tags correspondent 
  aux tags associés à la/les personne(s) sélectionnée(s) — réutilise la 
  logique déjà définie dans `tags-personnes.md`.
- Le scope "catégorie" inclut les sous-catégories si la catégorie choisie 
  en contient (cohérent avec l'imbrication définie dans `categories.md`).

## Hors scope pour cette feature
- **Filtre par ingrédients à inclure** : retiré du périmètre par décision PO à
  l'implémentation (la maquette de référence retenue, 11a-e, ne le montre pas —
  contrairement à un écran antérieur écarté). Non implémenté ni côté server ni
  mobile.
- **Plafond freemium de critères cumulés** : la maquette 11a-e n'affiche aucune
  limite (contrairement à l'écran antérieur écarté) ; le plafond reste planifié
  dans `limite-freemium.md`, pas dans ce v1.
- Intégration réelle de l'IA locale (prompt → paramètres de recherche) — 
  prévue architecturalement (paramètres structurés) mais pas implémentée 
  dans ce v1.
- Logique de scoring/pertinence OU (marge de pertinence évoquée) — reportée.
- Recherche full-text avancée (fautes de frappe, synonymes) — non précisée, 
  recherche simple sur le nom pour ce v1.

## Réalisation (2026-07-07)

Livré en un point (server + mobile), à partir des maquettes handoff **11a-e**
(barre façon Notion, `/` `#` `@`) plutôt que du panneau de filtres envisagé
initialement dans ce document.

- **Questions ouvertes résolues** : recherche par nom = `ilike` (insensible à
  la casse, "contient"), tri des résultats = date de création décroissante
  (les plus récentes d'abord, cohérent avec `listMine`/`listByCategory`).
- **Endpoint** : `GET /search/recipes`, pas `POST` — les paramètres restent
  simples (listes d'ids + texte), un `GET` suffisait.
- **Écart de nommage** : chemin `/search/recipes` (et non `/recipes/search`)
  pour éviter la collision avec `RecipesController@Get(':id')`.
- **Pas de panneau de filtres séparé** : remplacé par la barre unique à
  pastilles cumulées (cf. section interaction ci-dessus).
- Tests unitaires server sur `SearchService` (résolution des critères
  transverses) ; pas de tests mobile (hors périmètre v1, cf.
  `ENGINEERING_CONSTRAINTS.md`).

## Finitions UX (2026-07-08)

Retours PO sur le ressenti de la recherche, corrigés côté mobile (aucun impact
server) :
- **Ouverture en fondu** : la route `SearchPage` passe d'un `MaterialPageRoute`
  (glissement plateforme) à une `FadeTransition` (~220 ms). Comme la barre de
  l'accueil est désormais visuellement identique au vrai champ, l'entrée en
  recherche se lit comme un simple changement de mode, pas une navigation.
- **Focus automatique** : le champ prend le focus à l'arrivée (clavier ouvert
  immédiatement) — auparavant il fallait toucher le champ.
- **Chargement non bloquant** : pendant une requête, les résultats précédents
  restent affichés (estompés) sous une fine barre de progression, au lieu d'un
  spinner plein écran qui faisait « perdre le fil ». Débounce du texte libre
  porté à 500 ms.
- **Barres unifiées** : la barre décorative de l'accueil et le champ de la page
  recherche partagent rayon, bordure, ombre, tailles d'icônes et hint ; l'icône
  filtre est un `tune` sur fond transparent des deux côtés.
- **Cache dossiers/tags/personnes** : le chargement initial de l'autocomplétion
  profite désormais du cache de lecture des tags/personnes (cf.
  `tags-personnes.md`), réduisant l'écran de chargement à l'ouverture.