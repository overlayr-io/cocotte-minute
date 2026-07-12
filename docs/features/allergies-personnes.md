---
feature: allergies-personnes
status: planned        # planned | in-progress | done
scope: v1               # v1 | v2 | later
depends_on: [tags-personnes]
order: 11
---

# Allergies & interdits (Personne)

## Problème résolu
Permettre de renseigner les allergies/interdits alimentaires d'une personne
(membre de la famille), pour pouvoir plus tard alerter/filtrer les recettes
non compatibles.

## Comportement attendu

### Modèle
- Une allergie est un **tag** existant (table `tags`), avec un flag
  **`is_allergy`** défini **à la création uniquement, non modifiable ensuite**.
- Le flag conditionne uniquement l'affichage (marqueur visuel) et l'exclusion
  du filtre de recherche avancée — aucune autre règle de gestion différenciée.
- Catalogue par compte, comme les tags normaux : créé une fois, réutilisable
  sur 0..n personnes (pivot `person_tags` existant, pas de nouvelle table).
- Aucune limite de nombre (gratuit ou premium), disponible pour tous les
  utilisateurs sans distinction d'abonnement.

### Distinction visuelle
- Même palette de couleur que les tags normaux (pas de palette dédiée).
- Un marqueur visuel (icône/badge) distingue un tag-allergie d'un tag normal,
  partout où les tags sont affichés (sheet de création, page personne,
  liste des tags du compte).

### Page Personne
- Nouvelle section « Allergies » sur la fiche personne (`PersonEditPage`),
  distincte de la section tags existante — les tags-allergies ne se
  tapent/détapent pas au même endroit que les tags de goût.
- Création d'un tag-allergie : même mécanisme que la création d'un tag
  (bottom-sheet nom + couleur), avec un choix explicite « ceci est une
  allergie » au moment de la création, figé ensuite.

## Impact technique
- Server :
    - `tags` : ajout colonne `is_allergy` (boolean, défaut false).
    - Endpoint création tag inchangé dans sa forme, accepte `is_allergy` à la
      création ; PATCH tag ne doit pas permettre de modifier ce champ.
    - Endpoint de recherche avancée (filtre par tag) : exclut les tags où
      `is_allergy = true` du picker de sélection.
- Mobile :
    - `TagsPage`/sheet de création : option "C'est une allergie" (non
      modifiable après création, donc absente du formulaire d'édition).
    - `PersonEditPage` : nouvelle section Allergies (liste + toggle
      association, même pattern que la section tags existante).
    - Badge/icône distinctif partout où un tag est affiché avec
      `is_allergy = true`.

## Règles métier spécifiques
- `is_allergy` est immuable après création du tag (pas d'édition possible,
  ni via l'API ni via l'UI).
- Un tag-allergie reste lié aux personnes via le pivot `person_tags`
  existant — aucune nouvelle table de liaison.
- Un tag-allergie n'est jamais proposé/utilisable pour qualifier une recette
  (hors scope, cf. ci-dessous) : il n'apparaît donc pas dans un contexte de
  tag-recette.

## Hors scope pour cette feature
- Association allergie ↔ Recette/Ingrédient et toute détection ou alerte
  automatique (« telle recette contient un allergène d'une personne ») :
  mentionné comme besoin futur, non traité ici. Cette feature se limite à
  la saisie déclarative de l'allergie sur la personne.
- Niveau de gravité de l'allergie (léger/sévère) : non demandé, non traité.
- Migration des tags déjà existants : aucun tag actuel n'est retro-marqué
  allergie automatiquement.

## Questions ouvertes / à trancher
- Wording exact du choix "C'est une allergie" dans la sheet de création et
  libellé de la section sur la fiche personne — à définir en phase de build.
