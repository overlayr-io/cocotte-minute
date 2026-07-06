---
feature: auth
status: planned     # planned | in-progress | done
scope: v1           # v1 | v2 | later
depends_on: []
order: 1
---

# Authentification & gestion des comptes

## Problème résolu
Permettre l'utilisation immédiate de l'app sans inscription (réduire la friction
au premier lancement) tout en associant dès le départ chaque donnée créée à un
utilisateur réel, pour permettre plus tard un passage fluide vers un compte complet.

## Comportement attendu

### Compte anonyme (par défaut, dès l'installation)
- Dès le premier lancement, création automatique d'un compte Supabase anonyme
  (`signInAnonymously()`) — un vrai `userId`, pas de stockage local.
- Aucune invitation à s'inscrire/se connecter au premier lancement.
- Un seul compte anonyme par appareil, lié à l'installation de l'app.
- L'utilisateur anonyme peut tout faire — exactement comme un utilisateur inscrit.
- Après 2 semaines depuis la création du compte anonyme : affichage d'un
  rappel/popup incitant à créer un compte. Pas de blocage, l'utilisation
  reste illimitée. Récurrence de la notification : Chaque fois qu'il relance l'app.

### Passage à un compte complet
- Méthodes disponibles : email + mot de passe, Google, Apple.
- Utilise `linkIdentity()` de Supabase : le `userId` anonyme est conservé,
  toutes les données déjà créées (recettes, sous-recettes, ingrédients, tags)
  restent automatiquement liées au compte final — aucune migration de données
  à coder.
- Au moment de passer à un compte complet, deux choix proposés à l'utilisateur :
    1. **Garder toutes ses données** → `linkIdentity()`, même userId, tout est conservé.
    2. **Repartir de zéro** → suppression forcée (force delete) du compte anonyme
       et de toutes ses données, puis création d'un nouveau compte complet vierge.

## Ajout — Suppression de compte (RGPD, cf. ENGINEERING_CONSTRAINTS.md)

### Comportement attendu
- L'utilisateur peut demander la suppression de son compte depuis les settings.
- À la demande : le compte passe en statut **anonymisé** immédiatement
  (données personnelles identifiantes retirées/remplacées), mais les
  données restent en base.
- Un délai de **30 jours** s'ouvre : pendant cette période, l'utilisateur
  peut annuler la suppression et récupérer son compte tel quel (rollback).
- Passé les 30 jours, un **job CRON côté server** effectue la **suppression
  définitive et complète** de toutes les données liées à ce compte
  (cascade sur recettes, sous-recettes, ingrédients personnalisés, tags,
  personnes, listes de courses, etc.).

### Statuts de compte
- `active` : compte normal.
- `pending_deletion` : anonymisé, en attente du délai de 30 jours,
  annulation possible.
- `deleted` : suppression définitive effectuée (état terminal, plus de
  données réelles associées).

## Impact technique (ajout)
- Server :
  - Champ `account_status` sur l'utilisateur (`active` | `pending_deletion` | `deleted`).
  - Champ `deletion_requested_at` (timestamp), utilisé pour calculer
    l'échéance des 30 jours.
  - Endpoint pour déclencher la demande de suppression (anonymisation
    immédiate + passage en `pending_deletion`).
  - Endpoint pour annuler la suppression (rollback) tant que
    `account_status = pending_deletion` et que le délai de 30 jours
    n'est pas dépassé.
  - Job CRON planifié (ex: `@nestjs/schedule`, exécution quotidienne) qui
    recherche tous les comptes `pending_deletion` dont `deletion_requested_at`
    dépasse 30 jours, et déclenche leur suppression définitive en cascade.
- Mobile : écran de demande de suppression dans les settings, avec
  confirmation explicite + information claire sur le délai de 30 jours
  et la possibilité d'annuler.

## Règles métier spécifiques (ajout)
- L'anonymisation doit retirer toute donnée directement identifiante
  (email, nom si stocké) sans supprimer les recettes/contenus, pour
  permettre un rollback fidèle pendant les 30 jours.
- La suppression définitive après 30 jours est irréversible et doit
  couvrir toutes les tables liées à l'utilisateur (cascade complète).
- Un compte anonyme (non premium, sans email/OAuth lié) suit-il la même
  logique de suppression à la demande, ou n'a-t-il pas besoin de ce
  mécanisme puisqu'il n'a pas de données "personnelles" identifiantes au
  sens strict ? → cf. question ouverte ci-dessous.

## Questions ouvertes / à trancher (ajout)
- Un compte anonyme (jamais lié à un email/Google/Apple) a-t-il besoin du
  même parcours de suppression à 30 jours, ou peut-il être supprimé
  immédiatement puisqu'il ne contient aucune donnée directement identifiante ?
- Le job CRON doit-il envoyer une notification/email de rappel avant la
  suppression définitive (ex: à J+25) ? Non précisé pour l'instant.

## Impact technique
- Server : middleware/guard de vérification du token Supabase (valable aussi
  bien pour un utilisateur anonyme que complet — un `userId` valide est un
  `userId` valide, pas de distinction de traitement niveau guard).
- Mobile :
    - Appel `signInAnonymously()` au tout premier lancement de l'app (avant tout écran).
    - Stockage de la date de création du compte anonyme pour déclencher le rappel à J+14.
    - Écran/flow de conversion : choix des 3 méthodes (email/mdp, Google, Apple)
        + les 2 options (garder / repartir à zéro) si compte anonyme existant.
- DB : aucune table spécifique nécessaire pour l'auth (gérée par Supabase Auth).
  Prévoir un champ ou une requête permettant de savoir si un `userId` est anonyme
  ou complet (Supabase expose `is_anonymous` sur l'utilisateur).

## Règles métier spécifiques
- Toute donnée (recette, sous-recette, ingrédient, tag ect..) créée par un compte
  anonyme est traitée exactement comme celle d'un compte complet — pas de
  logique de permission différenciée entre anonyme et inscrit.
- Le rappel à J+14 est informatif uniquement, jamais bloquant.
- La suppression forcée ("repartir à zéro") doit supprimer réellement toutes
  les données liées à ce userId (cascade DB), pas juste désactiver le compte.

## Hors scope pour cette feature
- Import de recette provenant d'un autre utilisateur (copie + provenance) —
  prévu plus tard, pas dans cette feature auth.

## Questions ouvertes / à trancher
- Comportement si `linkIdentity()` échoue (ex: email déjà utilisé par un autre
  compte) : message d'erreur à définir.
- Comment faire/afficher le création du compte ? Via l'onglet Compte et se connecter ?
  Puis modal avec les deux questions ? avant ou après l'inscription ?