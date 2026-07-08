import { pgTable, timestamp, uniqueIndex, uuid } from 'drizzle-orm/pg-core';

import { people } from './people.schema';
import { recipes } from './recipes.schema';

/**
 * Liaison Personne ↔ Recette (n-n) : « ses recettes ». Association directe,
 * complémentaire du lien indirect via les tags (person_tags × recipe_tags).
 * Index unique sur (person_id, recipe_id) contre les doublons ; FK en cascade :
 * supprimer une personne ou une recette retire les liaisons.
 */
export const personRecipes = pgTable(
  'person_recipes',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    personId: uuid('person_id')
      .notNull()
      .references(() => people.id, { onDelete: 'cascade' }),
    recipeId: uuid('recipe_id')
      .notNull()
      .references(() => recipes.id, { onDelete: 'cascade' }),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (table) => [
    uniqueIndex('person_recipes_pair_uq').on(table.personId, table.recipeId),
  ],
);

export type PersonRecipeRow = typeof personRecipes.$inferSelect;
