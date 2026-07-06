# Mobile Flutter (contexte local, ne s'applique que dans mobile/)

## Stack précise
- Flutter (dernière stable)
- Bloc/Cubit pour le state management (package `flutter_bloc`)
- Supabase Flutter SDK (`supabase_flutter`) pour Auth, Storage, Realtime
- `dio` ou `http` pour appeler l'API REST NestJS (à préciser au premier appel)

## Règles strictes (économie de tokens)
- Pour toute implémentation coté mobile demande moi si je souhaite avoir un aperçu du design au lieu d'effectuer le travail à l'aveugle

## Architecture (feature-first, à respecter strictement)
lib/
core/
supabase/supabase_client.dart
network/api_client.dart
theme/
i18n/
features/
<feature>/
data/
<feature>_repository.dart
domain/
<feature>_model.dart
presentation/
bloc/
<feature>_bloc.dart
<feature>_event.dart
<feature>_state.dart
pages/
widgets/

## Règles
- Un Bloc par feature, pas de Bloc global fourre-tout sauf AuthBloc (partagé, dans core/).
- Auth (login, signup, OAuth, session, compte anonyme) : passe TOUJOURS par `supabase_flutter` directement, jamais par NestJS.
- Toute autre donnée métier : passe par le repository → API NestJS.
- États Bloc explicites (`Loading`, `Success`, `Failure`) — pas de bool `isLoading` flottant.
- Utiliser `freezed` seulement si le state le justifie (sinon classes simples, pour limiter les `.g.dart`/`.freezed.dart` lourds).
- Toute chaîne de texte affichée passe par le système i18n dès maintenant (architecture prête, seul le FR est activé, cf. `docs/ENGINEERING_CONSTRAINTS.md`).

## Gestion des erreurs (cf. ENGINEERING_CONSTRAINTS.md)
- Erreurs mineures/non bloquantes : snackbar/toast discret.
- Erreurs bloquantes : page d'erreur dédiée avec action de retry.

## Stratégie de données locales (deux mécanismes différents, ne pas confondre)

1. **Cache de lecture simple** (recettes, ingrédients, tags, catégories, etc.) :
    - Les données récupérées du serveur sont mises en cache localement pour
      permettre de rouvrir l'app et consulter le contenu déjà chargé sans
      refetch, même avec une connexion faible/absente.
    - Ce cache est **read-only et passif** : pas de queue de synchronisation,
      pas de gestion de conflit. Si l'utilisateur crée/modifie une recette
      sans connexion, ce n'est PAS géré par ce mécanisme (nécessite d'être
      en ligne pour écrire).
    - Techniquement : cache simple (ex: Hive/Isar en lecture, ou juste un
      stockage clé-valeur des dernières réponses API).

2. **Offline-first complet** (liste de courses UNIQUEMENT, cf.
   `docs/features/liste-courses-auto.md`) :
    - Lecture ET écriture possibles sans connexion, avec queue de synchronisation
      et résolution de conflit ("plus récent gagne").
    - Ce mécanisme ne doit pas être étendu à d'autres features sans décision
      explicite — c'est un choix scopé volontairement à la liste de courses
      pour le v1 (complexité de dev + risque de perte de données jugés trop
      élevés pour le généraliser, cf. discussion PROJECT_CONTEXT).

## Ne pas faire
- Ne pas coder de logique d'auth manuelle (token refresh, storage) — `supabase_flutter` le fait déjà.
- Ne pas régénérer un Bloc entier pour ajouter un seul event/state.
- Ne pas utiliser localStorage/sessionStorage (non applicable Flutter natif, mais rappel si contexte web).
