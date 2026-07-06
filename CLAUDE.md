# Projet Cocotte Minute

Monorepo : `mobile/` (Flutter + Bloc) + `server/` (NestJS + TS + Supabase).

## Règles strictes (économie de tokens)
- Ne jamais relire un fichier déjà présent dans le contexte de ce tour.
- Chercher avec `rg` (ripgrep), jamais `grep -r` ni parcours manuel de dossiers.
- Ne pas lancer `flutter pub get` / `npm install` sauf si pubspec.yaml/package.json a changé.
- Pas de résumé de fin de tâche sauf si demandé explicitement.
- Vérifier l'existence d'un fichier avec `ls`/`rg --files`, jamais avec `cat`.
- Pour toute tâche exploratoire ("où est géré X ?"), utiliser un sous-agent (Task) plutôt que de remplir le contexte principal.

## Stack
- Mobile : Flutter, Bloc/Cubit
- Server : NestJS + TypeScript, Supabase (DB Postgres + Auth + Storage + Realtime), Drizzle ORM
- Auth : Supabase Auth (JWT + OAuth + anonyme) — Flutter s'authentifie directement contre Supabase, NestJS ne fait que vérifier le token

## Architecture générale
Flutter (Bloc) ⇄ NestJS (REST) ⇄ Supabase (Postgres via Drizzle)
Flutter ⇄ Supabase directement pour : Auth, Storage, Realtime (pas besoin de passer par NestJS)

## Documents de référence
- Contexte produit complet : `PROJECT_CONTEXT.md`
- Contraintes transverses d'ingénierie (cache, erreurs, i18n, RGPD, tests, git) : `docs/ENGINEERING_CONSTRAINTS.md`
- Documentation détaillée par feature : `docs/features/*.md`

## Commandes
- Lint mobile : `cd mobile && flutter analyze`
- Lint server : `cd server && npm run lint`
- Tests mobile : `cd mobile && flutter test`
- Tests server : `cd server && npm run test`
- Migration DB : `cd server && npx drizzle-kit push`

## Fin de tache
- si tu juges que la feature a changer au cours de route ou léger changement, 
  demande moi si je souhaite changer le fichier et le mettre à jour avec les changements.