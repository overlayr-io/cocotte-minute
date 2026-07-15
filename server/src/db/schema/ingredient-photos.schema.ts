import { pgTable, text, timestamp, uuid } from 'drizzle-orm/pg-core';

import { ingredients } from './ingredients.schema';

/**
 * Photos « Mes produits » (feature #14) : galerie personnelle par ingrédient —
 * le vrai produit que l'utilisateur achète, distinct de l'icône (emoji/image)
 * de l'ingrédient. Scopée par utilisateur (`user_id`), y compris sur les
 * ingrédients du catalogue système (chacun voit les siennes).
 *
 * Quota (vérifié côté service, pas seulement UI) : 1 photo en gratuit, 3 en Pro,
 * par (utilisateur, ingrédient).
 *
 * `ingredient_id` en cascade : la suppression réelle d'un ingrédient purge ses
 * photos ; le nettoyage des fichiers Storage est fait explicitement côté service.
 */
export const ingredientPhotos = pgTable('ingredient_photos', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').notNull(),
  ingredientId: uuid('ingredient_id')
    .notNull()
    .references(() => ingredients.id, { onDelete: 'cascade' }),
  /** URL publique Storage Supabase de la photo (upload direct côté mobile). */
  imageUrl: text('image_url').notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
});

export type IngredientPhotoRow = typeof ingredientPhotos.$inferSelect;
export type NewIngredientPhotoRow = typeof ingredientPhotos.$inferInsert;
