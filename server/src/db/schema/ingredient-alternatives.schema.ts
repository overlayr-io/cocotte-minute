import { pgTable, timestamp, uniqueIndex, uuid } from 'drizzle-orm/pg-core';

import { ingredients } from './ingredients.schema';

/**
 * Alternatives entre ingrédients — relation **symétrique** (si A alt. de B alors
 * B alt. de A). Choix technique : une **seule ligne** par paire (pas de doublon
 * A→B / B→A), la symétrie est déduite à la lecture (requête bidirectionnelle).
 *
 * Invariant d'écriture : la paire est canonisée avec `lowId < highId` (ordre des
 * UUID) + index unique, ce qui rend impossible d'enregistrer deux fois la même
 * paire, quel que soit le sens de déclaration.
 */
export const ingredientAlternatives = pgTable(
  'ingredient_alternatives',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    lowId: uuid('low_id')
      .notNull()
      .references(() => ingredients.id, { onDelete: 'cascade' }),
    highId: uuid('high_id')
      .notNull()
      .references(() => ingredients.id, { onDelete: 'cascade' }),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (table) => [uniqueIndex('ingredient_alternatives_pair_uq').on(table.lowId, table.highId)],
);

export type IngredientAlternativeRow = typeof ingredientAlternatives.$inferSelect;
