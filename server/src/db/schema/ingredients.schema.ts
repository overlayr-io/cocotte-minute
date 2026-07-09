import { relations } from 'drizzle-orm';
import {
  type AnyPgColumn,
  pgEnum,
  pgTable,
  text,
  timestamp,
  uuid,
  varchar,
} from 'drizzle-orm/pg-core';

/**
 * Unités de mesure d'un ingrédient (cf. features/ingredients.md).
 * Valeurs stockées en base = identifiants stables (jamais le libellé i18n).
 */
export const INGREDIENT_UNITS = [
  'gramme',
  'milligramme',
  'piece',
  'cuillere_cafe',
  'cuillere_soupe',
] as const;

export type IngredientUnit = (typeof INGREDIENT_UNITS)[number];

export const ingredientUnitEnum = pgEnum('ingredient_unit', INGREDIENT_UNITS);

/**
 * Ingrédients — système (owner_id = null) vs copie utilisateur (owner_id = uid).
 *
 * - Un ingrédient système est un modèle non modifiable/supprimable par un user.
 * - "Importer" un ingrédient système crée une copie indépendante (owner_id = uid)
 *   qui garde un lien vers l'origine via `imported_from_id`.
 * - Suppression = soft delete (`deleted_at`), jamais d'effacement réel, pour ne pas
 *   casser les recettes qui référencent l'ingrédient.
 */
export const ingredients = pgTable('ingredients', {
  id: uuid('id').primaryKey().defaultRandom(),
  /** UUID Supabase du propriétaire. NULL = ingrédient système (catalogue de base). */
  ownerId: uuid('owner_id'),
  name: varchar('name', { length: 120 }).notNull(),
  imageUrl: text('image_url'),
  /**
   * Emoji illustrant l'ingrédient (alternative à `imageUrl`, mutuellement
   * exclusifs : le service vide l'un quand l'autre est renseigné).
   */
  emoji: varchar('emoji', { length: 16 }),
  unit: ingredientUnitEnum('unit').notNull(),
  /** Ingrédient système d'origine si cette ligne est une copie importée. */
  importedFromId: uuid('imported_from_id').references(
    (): AnyPgColumn => ingredients.id,
    { onDelete: 'set null' },
  ),
  /** Soft delete : non-null = supprimé. Toujours filtrer `IS NULL` en lecture. */
  deletedAt: timestamp('deleted_at', { withTimezone: true }),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
});

export const ingredientsRelations = relations(ingredients, ({ one }) => ({
  importedFrom: one(ingredients, {
    fields: [ingredients.importedFromId],
    references: [ingredients.id],
  }),
}));

export type IngredientRow = typeof ingredients.$inferSelect;
export type NewIngredientRow = typeof ingredients.$inferInsert;
