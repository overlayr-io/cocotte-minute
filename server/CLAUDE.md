# Server NestJS (contexte local, ne s'applique que dans server/)

## Stack précise
- NestJS + TypeScript strict
- Drizzle ORM (choisi pour sa légèreté — pas de moteur de requête séparé,
  important dans une optique d'hébergement futur sur Raspberry Pi)
- Supabase Postgres comme DB (cloud pour l'instant ; auto-hébergement complet
  envisagé plus tard sur Raspberry Pi, potentiellement via Dokploy, si passage
  en payant sur Supabase cloud)
- Auth : vérification du JWT Supabase côté server, jamais de logique d'auth
  custom, pas de Passport

## Principes d'architecture (SOLID + protection des domaines métier)
- Chaque module NestJS représente un domaine métier isolé. Un module ne doit
  jamais importer/appeler directement le repository ou le schema Drizzle
  d'un autre module — uniquement son service, exposé via les exports du module.
- Aucune librairie externe (Supabase client, Drizzle, etc.) n'est appelée
  directement depuis un controller ou un service métier "haut niveau" :
  toujours encapsulée derrière une classe dédiée (ex: un `SupabaseAuthGuard`
  pour l'auth, un provider Drizzle unique pour l'accès DB), jamais instanciée
  à la volée dans le code métier.
- Single Responsibility : un service ne fait qu'une chose (ex: un service de
  validation des règles sous-recette ne fait pas aussi de la persistance —
  il délègue au repository/schema Drizzle).
- Dependency Inversion : les services métier dépendent d'abstractions
  (interfaces/tokens d'injection NestJS), pas d'implémentations concrètes
  de librairies externes, pour permettre de remplacer une brique (ex: Drizzle
  par autre chose) sans réécrire la logique métier.

## Architecture (à respecter strictement)
src/
common/
guards/supabase-auth.guard.ts
decorators/current-user.decorator.ts
db/
schema/          # schémas Drizzle, un fichier par table
drizzle.provider.ts
modules/
<feature>/
<feature>.module.ts
<feature>.controller.ts
<feature>.service.ts
dto/
create-<feature>.dto.ts
update-<feature>.dto.ts

## Règles
- Toujours valider les DTO avec `class-validator`.
- Toute route protégée utilise `@UseGuards(SupabaseAuthGuard)` + `@CurrentUser()`.
- Jamais de logique DB directe dans le controller — toujours via service.
- Schéma Drizzle = source de vérité, jamais de SQL brut sauf cas de perf
  justifié en commentaire (pertinent à surveiller vu la contrainte Raspberry Pi).
- Un module = une feature métier, pas de "god module".
- Variables d'env : `DATABASE_URL`, `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`,
  `SUPABASE_JWT_SECRET`.
- Toutes les règles métier critiques (validation sous-recette, limites
  freemium, suppression de compte) vérifiées côté server, jamais uniquement UI.
- Tests unitaires sur la logique métier des services.

## Ne pas faire
- Ne pas générer de code Passport/JWT custom, Supabase gère déjà ça.
- Ne pas ajouter Prisma ou TypeORM même "en complément".
- Ne pas régénérer tout un module si une seule route change.
- Ne pas appeler le client Supabase ou Drizzle directement depuis un controller.