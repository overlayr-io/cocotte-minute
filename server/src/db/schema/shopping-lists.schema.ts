import {
  boolean,
  integer,
  jsonb,
  numeric,
  pgTable,
  primaryKey,
  text,
  timestamp,
  uuid,
  varchar,
} from 'drizzle-orm/pg-core';

/**
 * Contribution d'une recette à un article agrégé de la liste. Stockée en JSON sur
 * l'article (pas de table dédiée) : sert à la fois à la vue « par recette » et au
 * détail du calcul affiché sous la ligne agrégée (ex: « 20 g + 15 g + 10 g »).
 * `recipeId` référence une entrée de `shopping_list_recipes` (nom/photo y sont).
 */
export interface ShoppingItemSource {
  recipeId: string;
  /** Quantité apportée par cette recette, déjà mise à l'échelle du nombre de parts choisi. */
  quantity: number;
}

/**
 * Listes de courses (cf. features/liste-courses-auto.md).
 *
 * Offline-first : la liste vit d'abord en local (Drift côté mobile) puis est
 * synchronisée. `client_updated_at` porte l'horodatage **client** de dernière
 * modification, base de la résolution de conflit « le plus récent gagne » à la
 * synchronisation (jamais l'`updated_at` généré serveur).
 *
 * Gratuit : une seule liste active à la fois (garde serveur avant création).
 * « Vider » une liste = soft delete (`deleted_at`) : pas d'historique en gratuit,
 * l'historique/les listes multiples relevant du premium (non implémenté ici).
 */
export const shoppingLists = pgTable('shopping_lists', {
  id: uuid('id').primaryKey().defaultRandom(),
  /** UUID Supabase du propriétaire. Une liste appartient toujours à un compte. */
  ownerId: uuid('owner_id').notNull(),
  name: varchar('name', { length: 160 }).notNull(),
  /** Liste archivée/terminée (null = active). Réservé au premium (historique). */
  archivedAt: timestamp('archived_at', { withTimezone: true }),
  /** Soft delete : non-null = supprimée/vidée. Toujours filtrer `IS NULL` en lecture. */
  deletedAt: timestamp('deleted_at', { withTimezone: true }),
  /** Horodatage client de dernière modif (dédup/résolution de conflit à la sync). */
  clientUpdatedAt: timestamp('client_updated_at', { withTimezone: true })
    .defaultNow()
    .notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
});

/**
 * Recettes ayant généré une liste (vue « par recette »). Nom/photo sont **snapshotés**
 * pour rester affichables même si la recette d'origine est modifiée/supprimée ensuite
 * (la liste, une fois générée, ne suit plus la recette). `recipeId` est un uuid nu
 * (pas de FK) pour préserver ce découplage historique, à l'image d'`owner_id`.
 */
export const shoppingListRecipes = pgTable(
  'shopping_list_recipes',
  {
    shoppingListId: uuid('shopping_list_id')
      .notNull()
      .references(() => shoppingLists.id, { onDelete: 'cascade' }),
    /** Recette source (uuid nu, snapshot). Peut ne plus exister côté recettes. */
    recipeId: uuid('recipe_id').notNull(),
    recipeName: varchar('recipe_name', { length: 160 }).notNull(),
    photoUrl: text('photo_url'),
    /** Nombre de parts choisi pour cette recette (facteur d'échelle des quantités). */
    servings: integer('servings').notNull(),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (t) => [primaryKey({ columns: [t.shoppingListId, t.recipeId] })],
);

/**
 * Articles d'une liste, **agrégés par ingrédient** (un article = une ligne, quantités
 * additionnées entre recettes). Entièrement dénormalisé (nom/unité/quantité snapshotés)
 * pour un affichage 100 % hors-ligne et une liste qui ne bouge plus après génération.
 *
 * - `ingredientId` (uuid nu, nullable) : renseigné si l'article vient d'un ingrédient
 *   de recette — sert à l'agrégation et à retrouver ses alternatives. NULL = article
 *   libre (ajouté à la main).
 * - `customLabel` : libellé d'un article libre (mutuellement exclusif avec l'ingrédient).
 * - `replacedByAlternativeId` : alternative choisie « introuvable en magasin ». Modifie
 *   **seulement l'affichage de cette liste** (`replacementName` snapshoté), jamais la
 *   recette d'origine (règle métier liste-courses-auto.md).
 * - `sources` : contributions par recette (vue « par recette » + détail du calcul).
 */
export const shoppingListItems = pgTable('shopping_list_items', {
  id: uuid('id').primaryKey().defaultRandom(),
  shoppingListId: uuid('shopping_list_id')
    .notNull()
    .references(() => shoppingLists.id, { onDelete: 'cascade' }),
  /** Ingrédient source (uuid nu, snapshot). NULL pour un article libre. */
  ingredientId: uuid('ingredient_id'),
  /** Libellé d'un article libre (hors recette). NULL si l'article vient d'un ingrédient. */
  customLabel: varchar('custom_label', { length: 160 }),
  /** Nom affiché (snapshot : nom de l'ingrédient ou libellé libre). */
  name: varchar('name', { length: 160 }).notNull(),
  /** Quantité totale agrégée (pour `recipes.servings` mises à l'échelle). Null possible (article libre). */
  quantity: numeric('quantity', { precision: 10, scale: 2, mode: 'number' }),
  /** Unité snapshotée (identifiant stable, ex: 'gramme') ou libellé libre. Null possible. */
  unit: varchar('unit', { length: 32 }),
  isChecked: boolean('is_checked').notNull().default(false),
  /** Alternative affichée à la place de l'ingrédient (uuid nu, snapshot). NULL = original. */
  replacedByAlternativeId: uuid('replaced_by_alternative_id'),
  replacementName: varchar('replacement_name', { length: 160 }),
  /** Contributions par recette (JSON). Vide pour un article libre. */
  sources: jsonb('sources').$type<ShoppingItemSource[]>().notNull().default([]),
  /** Ordre d'affichage dans la liste. */
  position: integer('position').notNull().default(0),
  /** Horodatage client de dernière modif (résolution « le plus récent gagne »). */
  clientUpdatedAt: timestamp('client_updated_at', { withTimezone: true })
    .defaultNow()
    .notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
});

export type ShoppingListRow = typeof shoppingLists.$inferSelect;
export type NewShoppingListRow = typeof shoppingLists.$inferInsert;
export type ShoppingListRecipeRow = typeof shoppingListRecipes.$inferSelect;
export type NewShoppingListRecipeRow = typeof shoppingListRecipes.$inferInsert;
export type ShoppingListItemRow = typeof shoppingListItems.$inferSelect;
export type NewShoppingListItemRow = typeof shoppingListItems.$inferInsert;
