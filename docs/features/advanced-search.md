---
feature: recherche-avancee
status: planned     # planned | in-progress | done
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

### Filtres du v1
- Recherche textuelle sur le **nom** de la recette.
- Filtre par **tags** (un ou plusieurs).
- Filtre par **personnes** (une ou plusieurs — via les tags associés à la 
  personne, cf. `tags-personnes.md`).
- Filtre par **ingrédients à inclure** (une ou plusieurs).
- Scope optionnel par **catégorie/dossier** : restreindre la recherche à 
  l'intérieur d'une catégorie donnée (et ses sous-catégories si imbriquées, 
  cf. `categories.md`).

### Combinaison des filtres
- Par défaut : logique **ET** — une recette doit correspondre à TOUS les 
  filtres actifs simultanément pour apparaître dans les résultats.
- Évolution future prévue (pas dans ce v1) : une marge de pertinence 
  permettant de faire remonter des recettes correspondant à au moins un 
  des filtres (logique OU/scoring), pas encore définie précisément.

### Architecture pensée pour la future IA locale
- L'API de recherche doit être conçue avec des **paramètres structurés** 
  dès maintenant (ex: `{ name, tagIds[], personIds[], ingredientIds[], 
  categoryId }`), plutôt qu'une recherche ad hoc non réutilisable.
- Objectif : une future couche IA locale pourra traduire un prompt utilisateur 
  en ces mêmes paramètres structurés et appeler la même API de recherche, 
  sans qu'il soit nécessaire de recoder un endpoint dédié à l'IA plus tard.

## Impact technique
- Server :
  - Endpoint `GET /recipes/search` (ou `POST` si la complexité des filtres 
    le justifie) acceptant les paramètres structurés ci-dessus.
  - Requête combinant les jointures nécessaires (`recipe_tags`, `person_tags`, 
    `recipe_ingredients`, `recipe_categories`) avec logique ET entre les 
    familles de filtres actives.
- Mobile : 
  - Feature `search/` (Bloc), barre de recherche + panneau de filtres 
    (tags, personnes, ingrédients, catégorie).
  - Les paramètres de recherche sont construits sous une forme structurée 
    identique à celle attendue par le server, pour rester cohérent avec la 
    future intégration IA.
- DB : aucune nouvelle table — la recherche s'appuie sur les tables déjà 
  définies dans les features précédentes.

## Règles métier spécifiques
- Le filtre "personnes" recherche les recettes dont les tags correspondent 
  aux tags associés à la/les personne(s) sélectionnée(s) — réutilise la 
  logique déjà définie dans `tags-personnes.md`.
- Le scope "catégorie" inclut les sous-catégories si la catégorie choisie 
  en contient (cohérent avec l'imbrication définie dans `categories.md`).

## Hors scope pour cette feature
- Intégration réelle de l'IA locale (prompt → paramètres de recherche) — 
  prévue architecturalement (paramètres structurés) mais pas implémentée 
  dans ce v1.
- Logique de scoring/pertinence OU (marge de pertinence évoquée) — reportée.
- Recherche full-text avancée (fautes de frappe, synonymes) — non précisée, 
  recherche simple sur le nom pour ce v1.

## Questions ouvertes / à trancher
- La recherche par nom est-elle une correspondance stricte, "contient", ou 
  insensible à la casse/accents ? (à définir à l'implémentation)
- Tri des résultats de recherche : par pertinence, alphabétique, date de 
  création ? (non précisé)