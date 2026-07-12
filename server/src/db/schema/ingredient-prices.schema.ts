import { numeric, pgEnum, pgTable, timestamp, uniqueIndex, uuid } from 'drizzle-orm/pg-core';

import { ingredients } from './ingredients.schema';

/**
 * Unité de référence du prix d'un ingrédient (feature prix-estime), indépendante
 * de l'unité de quantité de l'ingrédient — conversion appliquée côté client au
 * moment du calcul. `litre` est prévue mais inatteignable en v1 (aucune unité de
 * quantité "volume" côté ingrédients) — réservée à une évolution future.
 */
export const PRICE_REFERENCE_UNITS = ['kilogram', 'litre', 'piece'] as const;
export type PriceReferenceUnit = (typeof PRICE_REFERENCE_UNITS)[number];
export const priceReferenceUnitEnum = pgEnum('price_reference_unit', PRICE_REFERENCE_UNITS);

/**
 * Prix d'un ingrédient — propre à chaque utilisateur, y compris sur un ingrédient
 * système partagé (deux utilisateurs peuvent avoir des prix différents pour le
 * même ingrédient). Une seule ligne par (utilisateur, ingrédient) : chaque
 * saisie écrase la précédente, aucun historique conservé.
 *
 * `lowPrice`/`highPrice` réservés Premium — écriture bloquée côté service si
 * l'utilisateur n'est pas premium (403). Conservés mais masqués côté client
 * après désabonnement (jamais supprimés) ; `averagePrice` reste seul
 * visible/éditable en gratuit.
 */
export const ingredientPrices = pgTable(
  'ingredient_prices',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    /** UUID Supabase du propriétaire du prix. Jamais système : toujours un utilisateur réel. */
    userId: uuid('user_id').notNull(),
    ingredientId: uuid('ingredient_id')
      .notNull()
      .references(() => ingredients.id, { onDelete: 'cascade' }),
    priceReferenceUnit: priceReferenceUnitEnum('price_reference_unit').notNull(),
    lowPrice: numeric('low_price', { precision: 10, scale: 3, mode: 'number' }),
    highPrice: numeric('high_price', { precision: 10, scale: 3, mode: 'number' }),
    averagePrice: numeric('average_price', { precision: 10, scale: 3, mode: 'number' }),
    updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (table) => [uniqueIndex('ingredient_prices_user_ingredient_uq').on(table.userId, table.ingredientId)],
);

export type IngredientPriceRow = typeof ingredientPrices.$inferSelect;
export type NewIngredientPriceRow = typeof ingredientPrices.$inferInsert;
