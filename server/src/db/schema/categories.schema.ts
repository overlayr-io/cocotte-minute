import {
  boolean,
  integer,
  pgTable,
  timestamp,
  uuid,
  varchar,
  type AnyPgColumn,
} from 'drizzle-orm/pg-core';

/**
 * Profondeur maximale d'imbrication d'un dossier. La racine compte comme le
 * niveau 1, donc au plus 4 niveaux de sous-dossiers en dessous (cf. décision
 * produit categories.md). Vérifié côté service à la création.
 */
export const CATEGORY_MAX_DEPTH = 5;

/**
 * Dossiers par défaut semés à la première ouverture des catégories d'un compte.
 * Non supprimables et non renommables (nom + emoji figés, `is_default = true`) ;
 * l'utilisateur peut seulement créer des sous-dossiers à l'intérieur.
 */
export const DEFAULT_CATEGORIES = [
  { name: 'Entrée', icon: '🥗' },
  { name: 'Plat', icon: '🍽️' },
  { name: 'Dessert', icon: '🍰' },
  { name: 'Boisson', icon: '🥤' },
] as const;

/**
 * Catégories — dossiers de rangement des recettes, propres à chaque compte
 * (`owner_id` non-null), imbricables via `parent_category_id` (arborescence).
 *
 * Une recette peut appartenir à plusieurs catégories (pivot `recipe_categories`,
 * à venir avec la feature recettes). `depth` est stocké (racine = 1) pour borner
 * l'imbrication à `CATEGORY_MAX_DEPTH` sans requête récursive.
 *
 * Suppression = soft delete (`deleted_at`), bloquée si le dossier n'est pas vide
 * ou s'il est par défaut (règles vérifiées côté service). La FK auto-référencée
 * est en cascade : elle ne sert qu'à la purge en masse du compte ("repartir de
 * zéro"), la suppression unitaire passant toujours par le service.
 */
export const categories = pgTable('categories', {
  id: uuid('id').primaryKey().defaultRandom(),
  /** UUID Supabase du propriétaire. Une catégorie appartient toujours à un compte. */
  ownerId: uuid('owner_id').notNull(),
  name: varchar('name', { length: 120 }).notNull(),
  /**
   * Emoji système, optionnel. Null = icône dossier par défaut côté client.
   * 32 caractères pour encaisser les emojis composés (ZWJ familles, drapeaux)
   * dont la longueur UTF-16 dépasse 16.
   */
  icon: varchar('icon', { length: 32 }),
  /** Dossier parent (null = racine). Pointe toujours vers une catégorie du même compte. */
  parentCategoryId: uuid('parent_category_id').references(
    (): AnyPgColumn => categories.id,
    { onDelete: 'cascade' },
  ),
  /** Profondeur dans l'arborescence, racine = 1, borne haute `CATEGORY_MAX_DEPTH`. */
  depth: integer('depth').notNull().default(1),
  /** Dossier par défaut (Entrée/Plat/Dessert/Boisson) : non supprimable, non renommable. */
  isDefault: boolean('is_default').notNull().default(false),
  /** Soft delete : non-null = supprimé. Toujours filtrer `IS NULL` en lecture. */
  deletedAt: timestamp('deleted_at', { withTimezone: true }),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
});

export type CategoryRow = typeof categories.$inferSelect;
export type NewCategoryRow = typeof categories.$inferInsert;
