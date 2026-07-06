# Contraintes transverses d'ingénierie — Cocotte Minute

Ce document s'applique à TOUTES les features, en complément des CLAUDE.md
et des docs par feature. En cas de conflit, ce document prévaut sur des
choix ad hoc faits dans une feature isolée.

## Gestion des erreurs et du chargement (mobile)
- Erreurs mineures (échec ponctuel, non bloquant) : snackbar/toast discret.
- Erreurs bloquantes (impossible de continuer, ex: perte totale de connexion
  sur un écran qui en dépend) : page d'erreur dédiée avec action de retry.
- Chaque état Bloc doit distinguer explicitement Loading / Success / Failure
  (déjà acté dans `mobile/CLAUDE.md`), et Failure doit porter un message
  exploitable pour choisir entre snackbar et page dédiée.

## Cache et performance réseau
- Ne jamais refetch une donnée déjà en cache tant qu'elle n'est pas explicitement
  invalidée (nouvelle création/modification, pull-to-refresh manuel, ou
  expiration de cache définie).
- Cache passif en lecture pour recettes/ingrédients/tags/catégories (cf.
  décision actée dans `PROJECT_CONTEXT.md` — à ne pas confondre avec
  l'offline-first de la liste de courses).

## Design
- Design moderne, cohérent avec le produit (maquettes Figma à venir, à
  intégrer au moment de leur disponibilité).
- Pas de gabarit générique/template par défaut : respecter la direction
  visuelle donnée par les maquettes une fois fournies.

## Internationalisation (i18n)
- Architecture i18n prête dès le v1 (ex: `flutter_localizations` + fichiers
  de traduction structurés dès le départ), mais un seul langage activé pour
  l'instant : **français uniquement**.
- Toute chaîne de texte affichée à l'utilisateur doit passer par le système
  i18n dès le départ, même si une seule langue est active — pour éviter un
  refactoring de masse plus tard.

## RGPD / données personnelles
- CGU et politique de confidentialité obligatoires dès le v1.
- Suppression de compte à la demande : passe par une **anonymisation** des
  données plutôt qu'une suppression immédiate.
- Délai de rollback de **30 jours** avant suppression définitive : le compte
  et ses données restent récupérables pendant cette période, puis sont
  définitivement supprimées passé ce délai.
- Implication technique : prévoir un statut de compte (ex: `active`,
  `pending_deletion`, `deleted`) et un `deletion_requested_at` pour piloter
  le délai de 30 jours (mécanisme à préciser dans une feature dédiée
  "suppression de compte" le moment venu).

## Accessibilité (a11y)
- Non prioritaire pour le v1. Pas de contrainte spécifique à respecter
  maintenant.

## Tests
- Tests unitaires uniquement, côté **server (NestJS)**, focalisés sur la
  logique métier (services, règles comme la validation sous-recette, calcul
  d'agrégation de liste de courses, etc.).
- Pas de tests mobile ni d'e2e prévus pour le v1.

## Convention Git
- Commits de type conventional commits, format court : `fix(scope): description`,
  `feat(scope): description`.
- Toujours plusieurs commits distincts plutôt qu'un gros commit unique, pour
  permettre un rollback ciblé si besoin.
- Pas de squash systématique qui perdrait cette granularité.