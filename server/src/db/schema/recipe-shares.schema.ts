import { relations } from 'drizzle-orm';
import { pgTable, timestamp, uuid, varchar } from 'drizzle-orm/pg-core';

import { recipes } from './recipes.schema';

/**
 * Liens de partage d'une recette (feature partage-recette).
 *
 * Une recette est privée par défaut (rattachée à son auteur). Générer un lien de
 * partage crée ici un `token` opaque, révélé dans une URL publique (`/share/:token`,
 * page web `/r/:token`, deep link app). Le token — et non l'id de la recette — est
 * la seule clé exposée : il peut être révoqué (`revoked_at`) sans toucher la recette,
 * et ne divulgue pas l'identifiant interne.
 *
 * Un même auteur peut créer plusieurs tokens pour une recette (ex. renouvellement),
 * d'où l'absence de contrainte d'unicité sur `recipe_id` ; seul `token` est unique.
 * `author_id` fige le propriétaire au moment de la création (contrôle d'accès à la
 * génération, jamais à la lecture publique).
 */
export const recipeShares = pgTable('recipe_shares', {
  id: uuid('id').primaryKey().defaultRandom(),
  recipeId: uuid('recipe_id')
    .notNull()
    .references(() => recipes.id, { onDelete: 'cascade' }),
  /** UUID Supabase de l'auteur ayant généré le lien (propriétaire de la recette au partage). */
  authorId: uuid('author_id').notNull(),
  /** Jeton opaque URL-safe (généré côté service). Seule clé publique exposée. */
  token: varchar('token', { length: 32 }).notNull().unique(),
  /** Révocation : non-null = lien désactivé. Toujours filtrer `IS NULL` en lecture publique. */
  revokedAt: timestamp('revoked_at', { withTimezone: true }),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
});

export const recipeSharesRelations = relations(recipeShares, ({ one }) => ({
  recipe: one(recipes, {
    fields: [recipeShares.recipeId],
    references: [recipes.id],
  }),
}));

export type RecipeShareRow = typeof recipeShares.$inferSelect;
export type NewRecipeShareRow = typeof recipeShares.$inferInsert;
