import { pgTable, text, timestamp, uuid } from 'drizzle-orm/pg-core';

import { recipes } from './recipes.schema';

/**
 * Photos « additionnelles » d'une recette (feature galerie-recette) — les
 * réalisations que l'utilisateur poste après avoir cuisiné la recette. Ne
 * stocke JAMAIS la photo de couverture (`recipes.photoUrl`), qui reste un champ
 * à part et n'est jamais comptabilisée dans le quota galerie.
 *
 * Quota (vérifié côté service, pas seulement UI) : 3 photos en gratuit, 6 en
 * Pro, **par recette** — contrairement aux autres limites freemium, le plafond
 * existe même en Pro (ce n'est pas « illimité »).
 *
 * `recipeId` en cascade : un vrai `DELETE FROM recipes` purge les lignes. Mais
 * le soft delete d'une recette (`deleted_at`) ne déclenche pas cette cascade —
 * le nettoyage des fichiers Storage y est donc appelé explicitement côté
 * service (cf. galerie-recette.md : suppression Storage effective, plus stricte
 * que l'existant).
 */
export const recipeGalleryImages = pgTable('recipe_gallery_images', {
  id: uuid('id').primaryKey().defaultRandom(),
  recipeId: uuid('recipe_id')
    .notNull()
    .references(() => recipes.id, { onDelete: 'cascade' }),
  /** URL publique Storage Supabase de la photo (upload direct côté mobile). */
  imageUrl: text('image_url').notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
});

export type RecipeGalleryImageRow = typeof recipeGalleryImages.$inferSelect;
export type NewRecipeGalleryImageRow = typeof recipeGalleryImages.$inferInsert;
