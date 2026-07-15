# Feature — Recettes d'exemple à la 1ère ouverture (onboarding)

> Item #12 du backlog. À la création du compte, semer une recette et une recette
> de base qui l'utilise, pour montrer le but de l'application dès le départ.

## Décisions (validées)

- **Quand** : à la **1ère ouverture** de l'app (compte anonyme inclus — Supabase
  crée un utilisateur anonyme au démarrage). Une seule fois par compte.
- **Contenu** : **1 recette de base** (« Sauce tomate maison ») + **1 plat**
  (« Pâtes à la sauce tomate ») qui l'ajoute en **sous-recette**, pour illustrer
  le concept clé base ⇄ plat.
- **Source** : généré **côté serveur** (pas un JSON figé côté mobile) via les
  méthodes métier existantes (`create`, `addIngredient`, `addStep`,
  `addComponent`), pour rester cohérent avec toutes les règles (positions,
  quotas, validation sous-recette).

## Idempotence

- Le service ne sème **rien** si le compte a déjà eu au moins une recette
  (`count(recipes) where author_id = user > 0`, y compris supprimées) — évite
  les doublons si l'endpoint est rappelé.
- **Verrou consultatif** (`pg_advisory_xact_lock`, cf.
  `common/db/advisory-locks.ts`) tenu pendant **tout** le semis : entre le
  `count` et la 1re recette il y a ~10 allers-retours, donc deux appels
  concurrents (2 lancements qui se chevauchent pendant un cold start Render)
  semaient chacun leur jeu. Le verrou tient jusqu'au commit de la transaction ;
  comme le semis est `await`é à l'intérieur, le 2e appelant attend puis voit les
  recettes commitées et sort.
- Côté mobile, un flag local (`SharedPreferences`) empêche même le 2e appel
  réseau après le 1er succès. Le serveur reste la vraie garde.
- **Le flag est scopé par compte** : clé `onboarding.sample_recipes_seeded.<userId>`.
  Un flag global à l'appareil serait posé au 1er lancement d'un compte qui avait
  déjà des recettes (le serveur répondant 204 sans rien semer), ce qui
  verrouillerait définitivement **tous les comptes suivants** du téléphone —
  c'était le bug corrigé le 2026-07-15.

## API (module recipes)

- `POST /recipes/seed-samples` → 204. Idempotent. Sème 6 ingrédients
  utilisateur (tomate, oignon, ail, huile, pâtes, parmesan), la base + le plat
  avec leurs ingrédients, étapes et le lien de sous-recette.

## Mobile

- Appel unique au démarrage (après que la session Supabase — anonyme ou non —
  est prête), **hors** `auth_bloc` : l'auth passe toujours directement par
  `supabase_flutter`, jamais par NestJS. Le déclencheur est
  `OnboardingService.start(userId)`, appelé depuis `MainShell.initState` (la
  coquille n'est montée qu'après `AuthAuthenticated`, et elle est keyée par
  `user.id` : un compte invité recréé repart comme une première installation).
- **L'accueil attend le semis** : `OnboardingService.pending` expose le futur du
  semis en cours, et `HomeCubit.load()` l'attend avant d'interroger le serveur.
  Sans ça, l'accueil se charge en parallèle du semis et affiche un état vide
  (d'autant plus visible avec les cold starts Render).
- En cas d'échec réseau : non bloquant, on réessaiera à la prochaine ouverture
  (le flag n'est posé qu'après un 204).

## Notes

- Les unités d'ingrédient utilisées (`piece`, `cuillere_soupe`, `gramme`) font
  partie de l'enum `INGREDIENT_UNITS`.
- La base est créée avec `isBase: true` : elle compte dans le quota freemium des
  recettes de base, mais un compte neuf part de 0.
