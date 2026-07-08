---
feature: auth
status: in-progress     # planned | in-progress | done
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

## État d'implémentation v1 (mobile + server)

### Mobile — `features/auth/`
- Écran unique Login/Inscription (bascule `Créer un compte` / `Se connecter`
  sur le même écran), calé sur la maquette handoff (design "1c/2b"). Header en
  `Scaffold.appBar` avec flèche retour ; tous les écrans de la feature suivent
  la structure `Scaffold(appBar: ..., body: ...)`.
- `AuthRepository` : `createAccountWithEmail`/`signInWithEmail` (Supabase
  direct), conversion anonyme via `updateUser` (garde le même `userId`),
  `continueWithOAuth` (Google/Apple, via `linkIdentity` si invité),
  `resetGuestData` (appel NestJS pour "repartir de zéro").
- **Boutons Google/Apple visibles uniquement en dev (`kDebugMode`)** :
  le câblage Supabase existe, mais l'activation en production est différée
  tant que les redirect URLs Supabase + la config native (deep link iOS,
  Sign in with Apple) ne sont pas faites.
- Modal "conserver mes données / repartir de zéro" : bottom-sheet système
  (radio + carte "Conseillé"), affichée uniquement si l'utilisateur était
  invité au moment de la conversion. N'affiche pas de compteur de recettes
  (pas de table métier en v1, cf. écart ci-dessous) — wording générique.
- Point d'entrée : **onglet Compte** (`features/account/`), désormais en place —
  carte profil invité/connecté + **carte d'invitation permanente** « Créer ton
  compte » (invité) qui ouvre l'écran d'auth. (L'ancien CTA temporaire sur
  `HomePage` n'est plus le point d'entrée ; cf. section « Compte invité » ci-dessous.)
- Thème global aligné sur la maquette (`AppColors` : vert `#6B8E5A` + corail
  `#FF6F61` sur fond crème `#F7F6F2`) et polices bundlées (Bricolage
  Grotesque / Hanken Grotesk) — appliqué à toute l'app, pas seulement à l'auth.

### Server — `modules/account/`
- `POST /account/reset-guest-data` (protégé par `SupabaseAuthGuard`) déclenche
  "repartir de zéro" : efface les données de l'utilisateur courant (le compte
  Supabase, lui, est conservé — la conversion a déjà eu lieu côté mobile).
- `AccountService.resetGuestData` **purge désormais réellement** les domaines
  déjà livrés via leurs services exportés (jamais leur schéma) : **personnes**
  (→ `person_tags` en cascade), **ingrédients**, **tags**. Les domaines à venir
  (recettes, sous-recettes, listes de courses) restent à y brancher au fil de
  leur implémentation.

### Écarts assumés vs. le comportement cible
- Suppression cascade « repartir de zéro » réelle pour les domaines livrés
  (personnes, ingrédients, tags) ; reste à étendre aux domaines futurs.
- "Repartir de zéro" repose sur un wipe des données du compte existant plutôt
  qu'un delete + recreate complet du compte — comportement fonctionnellement
  équivalent, plus simple à implémenter.
- Pour un flux OAuth (redirection), la modal conserver/repartir n'est pas
  encore déclenchée (seul le flux email/mot de passe la propose) — à
  compléter quand OAuth sera activé en production.

### Reste à faire (raison du statut `in-progress`)
- **OAuth en production** : boutons Google/Apple limités au `kDebugMode`.
- **« Gérer le compte » (utilisateur connecté)** : la tuile pointe encore vers
  l'écran « bientôt disponible » (édition d'e-mail/mot de passe non faite).

## Compte invité, déconnexion & confidentialité (2026-07-08)

Retours PO sur l'accessibilité des actions de compte en mode invité, corrigés
côté mobile (le circuit serveur de suppression RGPD existait déjà) :

- **Rappel J+14 remplacé par une invitation permanente** : la carte de rappel
  conditionnée à ≥ 14 jours est retirée au profit d'une **carte verte
  permanente** en tête de l'onglet Compte (titre + sous-titre + **un seul
  bouton « Créer ton compte »**), toujours visible pour un invité. Plus de
  dépendance à la date de création — l'invité peut convertir son compte dès le
  premier jour. (Le tracking temporel J+14 devient donc sans objet.)
- **Déconnexion visible en invité** : auparavant masquée par `if (!isGuest)`.
  Désormais affichée, avec un **dialogue d'avertissement** (perte des données
  locales) proposant « Créer ton compte » en action mise en avant.
- **Suppression des données visible en invité** : la tuile mène à
  `DeleteAccountPage` (branche anonyme = purge immédiate côté serveur, déjà
  codée). Libellé adapté (« Supprimer mes données »).
- **Pages Confidentialité réelles** : Politique de confidentialité et
  Conditions d'utilisation (composant `LegalPage` partagé) + **Gérer mes
  données** (`ManageDataPage` : ce qui est conservé + droit de suppression),
  ne pointent plus vers « bientôt disponible ». Contrainte PO : **wording sans
  jargon technique** (pas de mention d'un fournisseur cloud), et pas d'export
  de données dans « Gérer mes données ». Les liens CGU/Confidentialité de
  l'écran d'auth (`LegalNotice`) sont désormais cliquables.