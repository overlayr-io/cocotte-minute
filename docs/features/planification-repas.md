---
feature: planification-repas
status: done        # planned | in-progress | done
scope: v2
depends_on: [recipes, limite-freemium, premium-version, list-courses-auto]
order: 17
---

> **État 2026-07-12** : livrée sur `feat/planification-repas` (migration
> `0017_meal_plan.sql` **non appliquée** — `npx drizzle-kit push` à lancer).
> Écarts d'implémentation vs prototype en bas de document.

# Planification des repas

## Problème résolu
Permettre de placer des recettes déjà créées sur un calendrier matin/midi/soir
pour préparer les repas à l'avance (usage cité : préparer les repas d'une
semaine de vacances), plutôt que de choisir au jour le jour.

## Comportement attendu
- Vue calendaire par **semaine calendaire fixe (lundi → dimanche)**, avec
  navigation semaine précédente / semaine suivante.
- Chaque jour a 3 créneaux : matin, midi, soir.
- L'utilisateur sélectionne une recette (parmi ses recettes existantes) et la
  place sur un créneau par **drag and drop**.
- Un créneau peut contenir **plusieurs recettes** (en premium — voir limites
  freemium ci-dessous).
- Suppression d'une recette d'un créneau à tout moment (indépendamment de la
  limite d'ajout).
- Planning **global au compte** (pas de déclinaison par personne/famille).

## Limites freemium

### Compte gratuit
- Accès uniquement à la semaine en cours (T) et à la semaine suivante (T+1).
  Navigation vers T-1 ou T+2 et au-delà possible mais **en lecture seule**
  (visualisation uniquement si des données existent déjà là, aucun
  ajout/modification/suppression) — pas de paywall bloquant à la navigation.
- **1 seule recette par créneau** maximum → 3 recettes par jour max.
- Tentative d'ajouter une 2e recette sur un créneau déjà occupé → ouvre le
  paywall (même pattern que les autres quotas, cf.
  `docs/features/limite-freemium.md`).

### Compte premium
- Plusieurs recettes par créneau, sans limite.
- Accès à toutes les semaines dans la limite de rétention de stockage
  (voir ci-dessous), y compris pour l'ajout/modification.

## Rétention de stockage
- Le planning conserve au maximum **4 semaines** de données (au-delà, purge).
- Cette limite de rétention est indépendante de la limite freemium T/T+1 :
  elle borne le stockage technique pour tous les comptes (y compris premium).
- ⚠️ Question ouverte sur le déclenchement exact de la purge — voir plus bas.

## Cascade suppression de recette
- Si une recette utilisée dans le planning est supprimée par l'utilisateur,
  son entrée disparaît automatiquement de tous les créneaux où elle était
  placée (suppression en cascade, pas de blocage de la suppression).

## Ajout à la liste de courses depuis le planning
- Interface de sélection des jours/créneaux/recettes à ajouter à la liste de
  courses (pas de génération automatique globale du planning entier).
- **Compte gratuit** :
  - Si la liste de courses active est vide → ajout direct des ingrédients
    sélectionnés.
  - Si la liste de courses active n'est pas vide → demande confirmation
    "souhaitez-vous remplacer la liste actuelle ?" avant d'ajouter (cohérent
    avec la limite "1 seule liste active" du gratuit, cf.
    `docs/features/limite-freemium.md`).
- **Compte premium** : crée toujours une **nouvelle liste de courses** dédiée
  à partir de la sélection, sans toucher à la liste active existante.

## Comportement hors-ligne
- Le planning utilise un cache local (dernières données synchronisées
  affichées hors-ligne).
- Une connexion est requise dès qu'il n'y a pas de données en cache pour la
  semaine consultée (pas d'édition offline-first avec queue de sync comme la
  liste de courses — plus proche du comportement des recettes).

## Impact technique

### Server
- Nouvelle table de planning : créneau (jour de semaine calendaire, moment
  matin/midi/soir), lié à une recette et à un utilisateur/compte.
- Job ou logique de purge des semaines au-delà des 4 semaines de rétention.
- Vérification serveur des limites freemium (semaine T/T+1 uniquement, 1
  recette/créneau max) — jamais uniquement côté UI, cohérent avec le pattern
  déjà en place pour les autres quotas.
- Suppression en cascade des entrées de planning quand la recette liée est
  supprimée (contrainte FK ON DELETE CASCADE ou équivalent applicatif).
- Endpoint(s) pour ajouter à la liste de courses depuis une sélection de
  créneaux du planning (réutilise la logique d'ajout d'ingrédients déjà
  existante côté `list-courses-auto`).

### Mobile
- Vue calendrier semaine avec drag & drop des recettes vers les créneaux.
- Sélecteur de recette (parmi les recettes existantes) pour l'ajout à un
  créneau.
- Navigation semaine précédente/suivante avec état lecture-seule visuel
  au-delà de T/T+1 en gratuit.
- Écran/flow de sélection multi-créneaux pour l'ajout à la liste de courses,
  avec la confirmation de remplacement en gratuit.
- Cache local pour affichage hors-ligne des dernières données synchronisées.

## Règles métier spécifiques
- Semaine calendaire fixe lundi → dimanche (pas de semaine glissante).
- 3 créneaux fixes par jour : matin, midi, soir (pas de créneaux
  personnalisables dans cette version).
- Planning global au compte, pas de déclinaison par personne.

## Hors scope pour cette feature
- Génération automatique de la liste de courses pour tout le planning sans
  sélection manuelle.
- Créneaux personnalisables (au-delà de matin/midi/soir).
- Planning par personne/famille.
- Édition offline-first avec queue de synchronisation (comme la liste de
  courses).

## Questions ouvertes / à trancher
- Aucune — tout est tranché.

## Ajout — design Claude Design validé (2026-07-12)

Le handoff Claude Design (« Planification des repas ») précise et étend le
cadrage. Écrans à reproduire fidèlement : 1a-1g, 2a-2c, 3a-3b, 4a-4c.

### Types d'entrée sur un créneau (nouveau)
Un créneau peut contenir trois types d'entrée, pas seulement des recettes :
- **Recette** (référence à une recette existante) ;
- **« Manger dehors »** (repas hors planning, pastille dédiée) ;
- **« Note libre »** (texte court, ex. « pâtes sauce tomate », avec
  suggestions rapides).
La limite gratuit « 1 par créneau » compte **toutes les entrées confondues**
(comme le prototype : une note bloque aussi l'ajout d'une 2e entrée).

### UI actée par le design
- **Onglet « Planning »** ajouté dans la tab bar principale (5 onglets :
  Accueil, Recettes, Planning, Courses, Compte).
- **Deux layouts** commutables : Grille (7 jours × 3 colonnes, écran 1a) et
  Blocs (un bloc par jour, créneaux empilés, écran 1b).
- **Bandeau « À planifier »** en bas : liste horizontale de recettes choisies
  par l'utilisateur (sheet de gestion multi-sélection), qu'on glisse sur les
  créneaux. C'est la source du drag & drop.
- Ajout aussi possible via « + » sur créneau vide → sheet « Ajouter au
  créneau » (recherche recette + Manger dehors + Note libre, écrans 2a/2c).
- **Créneau multi-recettes (Premium)** : miniatures empilées + compteur doré
  (1d) ; tap → sheet détail du créneau listant chaque entrée, retirable une à
  une, + « Ajouter une recette » (1g).
- **Retrait** : menu contextuel sur la mini-card (Voir la recette / Retirer,
  écran 3a) puis snackbar avec « Annuler » ≈ 5 s (3b) — jamais de dialog.
- **Lecture seule** (gratuit hors T/T+1) : bandeau cadenas + CTA Premium,
  créneaux estompés, « + »/drag/suppression désactivés (1f).
- **Navigation semaine** bornée à la fenêtre de rétention : T-1 → T+2
  (4 semaines au total, cohérent avec la rétention de stockage).
- **Vers les courses** : mode sélection par créneaux cochables + FAB
  récapitulatif (4a) ; gratuit avec liste non vide → dialog « Remplacer ? »
  (4b) ; premium → toast « Liste “Courses du …” créée » (4c).
- État vide première utilisation : carte d'accroche dans le calendrier (1e).

### Décisions tranchées
- **Purge de rétention : lazy** — à la lecture/écriture du planning d'un
  utilisateur, suppression de ses semaines hors fenêtre T-1 → T+2 (pas de
  cron, peu fiable sur Render free tier).
- Écran 1g inclus (nécessaire pour gérer les créneaux multi-recettes).
- **Liste « À planifier » : locale au device** (shared_preferences) — c'est un
  brouillon de travail, pas une donnée métier synchronisée.

## Ajout — écarts d'implémentation (livraison 2026-07-12)

- **Serveur** : module `meal-plan` (table `meal_plan_entries`, migration 0017),
  `GET /meal-plan?weekStart`, `POST/DELETE /meal-plan/entries`. Codes premium
  `PREMIUM_LIMIT_MEAL_SLOT_ENTRIES` (1 entrée/créneau gratuit) et
  `PREMIUM_LIMIT_MEAL_PLAN_WEEK` (écriture hors T/T+1 gratuit — s'applique
  aussi au retrait, cohérent avec la lecture seule). Semaine calculée en jours
  civils Europe/Paris.
- **Cascade recettes** : FK `ON DELETE CASCADE` pour les hard deletes + purge
  lazy à la lecture pour les recettes *soft*-supprimées (le soft delete ne
  déclenche pas la FK).
- **Aucun nouvel endpoint courses** : le mobile réutilise
  `POST /shopping-lists` (generate) et `DELETE /shopping-lists/:id` (clear).
  Gratuit avec liste active *vide* : remplacement direct sans dialog (le
  dialog n'apparaît que si la liste contient des articles).
- **Menu contextuel 3a** : popover partagé `showActionMenu` de l'app (sans le
  bloc d'en-tête « Créneau · nom » du prototype).
- **Drag & drop** : démarre par appui long court (~150 ms) sur une chip du
  bandeau — pattern mobile (le prototype desktop draguait au pointeur).
- **Sheet détail 1g** : reste ouverte pendant les retraits, se ferme
  automatiquement quand le créneau est vide.
- **Snackbar/toast** : snackbar sombre « Annuler » (4 s) pour le retrait ;
  toast vert sombre + coche dorée pour le succès courses (gratuit et premium,
  textes distincts), comme le prototype.
  - **Piège Flutter** : ce snackbar porte une `action` (« Annuler »), et
    `SnackBar` calcule `persist = persist ?? action != null`. Sans `persist:
    false` explicite, le snackbar devient **persistant** et sa `duration` est
    ignorée (le timer sort sans masquer, cf. `scaffold.dart`) — le toast
    « Recette retirée du créneau » restait affiché indéfiniment (corrigé le
    2026-07-15). C'est le seul snackbar de l'app avec une `action`.
