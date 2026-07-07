import { relations } from 'drizzle-orm';
import {
  boolean,
  integer,
  numeric,
  pgEnum,
  pgTable,
  primaryKey,
  text,
  timestamp,
  uuid,
  varchar,
  type AnyPgColumn,
} from 'drizzle-orm/pg-core';

import { categories } from './categories.schema';
import { ingredients } from './ingredients.schema';
import { tags } from './tags.schema';

/**
 * Valeur par défaut du nombre de personnes d'une recette. `recipes.md` laissait
 * la question ouverte (0 vs 1/4) : on retient 1 — une recette est utilisable dès
 * sa création, et le prorata futur des quantités part d'une base non nulle.
 */
export const DEFAULT_SERVINGS = 1;

/**
 * Quantité par défaut d'une ligne `recipe_ingredients` (fallback serveur). Le
 * client envoie toujours une quantité explicite (défaut par unité côté mobile).
 */
export const DEFAULT_INGREDIENT_QUANTITY = 1;

/**
 * Recettes — domaine métier central (cf. features/recipes.md).
 *
 * Distinction fondamentale, décidée dès la création : recette « normale » vs
 * recette « de base » (`is_base`). Une recette de base est réutilisable comme
 * composant d'autres recettes (pivot `recipe_components`) ; une normale ne l'est
 * jamais. `is_base` peut passer de false→true librement, mais true→false est
 * interdit tant que la recette est utilisée comme composant (verrou vérifié côté
 * service). Suppression = soft delete (`deleted_at`).
 */
export const recipes = pgTable('recipes', {
  id: uuid('id').primaryKey().defaultRandom(),
  /** UUID Supabase de l'auteur/créateur (feature auth). Une recette a toujours un auteur. */
  authorId: uuid('author_id').notNull(),
  name: varchar('name', { length: 160 }).notNull(),
  /** Photo optionnelle (URL Storage Supabase). Null = pas de photo. */
  photoUrl: text('photo_url'),
  description: text('description'),
  /** Recette de base (réutilisable comme composant). Défini à la création, verrouillable. */
  isBase: boolean('is_base').notNull().default(false),
  /** Temps en minutes, défaut 0 (renseignés plus tard sur la fiche). */
  prepTime: integer('prep_time').notNull().default(0),
  cookTime: integer('cook_time').notNull().default(0),
  restTime: integer('rest_time').notNull().default(0),
  /** Nombre de personnes, défaut `DEFAULT_SERVINGS`. */
  servings: integer('servings').notNull().default(DEFAULT_SERVINGS),
  /** Soft delete : non-null = supprimé. Toujours filtrer `IS NULL` en lecture. */
  deletedAt: timestamp('deleted_at', { withTimezone: true }),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
});

/**
 * Ingrédients d'une recette. Pivot (recipe_id, ingredient_id) + quantité.
 * La quantité est un décimal (feature ingrédients-quantités) exprimé pour
 * `recipes.servings` personnes ; la mise à l'échelle par portions est un calcul
 * d'affichage côté client, jamais persisté. L'unité n'est jamais dupliquée ici :
 * elle est toujours lue depuis `ingredients.unit`.
 */
export const recipeIngredients = pgTable(
  'recipe_ingredients',
  {
    recipeId: uuid('recipe_id')
      .notNull()
      .references(() => recipes.id, { onDelete: 'cascade' }),
    ingredientId: uuid('ingredient_id')
      .notNull()
      .references(() => ingredients.id, { onDelete: 'cascade' }),
    /** Quantité pour `recipes.servings` personnes. Décimal (ex: 2,5 c.à.s). */
    quantity: numeric('quantity', { precision: 10, scale: 2, mode: 'number' })
      .notNull()
      .default(DEFAULT_INGREDIENT_QUANTITY),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (t) => [primaryKey({ columns: [t.recipeId, t.ingredientId] })],
);

/**
 * Composition : `parent_recipe_id` utilise `base_recipe_id` comme sous-recette.
 * Contrainte métier (vérifiée côté service, pas seulement en base) : la recette
 * pointée par `base_recipe_id` doit avoir `is_base = true`. Une fois présente ici,
 * elle ne peut plus repasser en recette normale (verrou `is_base`).
 */
export const recipeComponents = pgTable(
  'recipe_components',
  {
    parentRecipeId: uuid('parent_recipe_id')
      .notNull()
      .references(() => recipes.id, { onDelete: 'cascade' }),
    baseRecipeId: uuid('base_recipe_id')
      .notNull()
      .references((): AnyPgColumn => recipes.id, { onDelete: 'cascade' }),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (t) => [primaryKey({ columns: [t.parentRecipeId, t.baseRecipeId] })],
);

/**
 * Bannière d'une étape (cf. features/recipe-steps.md). 4 préréglages ; l'icône
 * et la couleur sont dérivées du type côté client (pas de couleur stockée).
 */
export const RECIPE_STEP_BANNERS = ['warning', 'info', 'danger', 'learn'] as const;
export type RecipeStepBanner = (typeof RECIPE_STEP_BANNERS)[number];
export const recipeStepBannerEnum = pgEnum('recipe_step_banner', RECIPE_STEP_BANNERS);

/**
 * Étapes d'une recette (feature recette-etapes). Une étape est de l'un des deux
 * types, mutuellement exclusifs (contrainte vérifiée côté service) :
 *  - **texte** : `description` obligatoire, `banner_type`/`banner_text` optionnels
 *    (ensemble), pas de `base_recipe_ref_id` ;
 *  - **référence de base** : `base_recipe_ref_id` seul (pointe une recette
 *    `is_base = true`), pas de description ni bannière — ses étapes sont affichées
 *    par référence (dépliées récursivement au rendu), jamais copiées.
 * `position` porte l'ordre global (drag & drop). Les étapes internes d'une
 * référence ne sont jamais réordonnées/éditées depuis la recette parente.
 */
export const recipeSteps = pgTable('recipe_steps', {
  id: uuid('id').primaryKey().defaultRandom(),
  recipeId: uuid('recipe_id')
    .notNull()
    .references(() => recipes.id, { onDelete: 'cascade' }),
  /** Ordre dans la recette (0-based, réécrit au réordonnancement). */
  position: integer('position').notNull(),
  /** Étape texte : description obligatoire ; null pour une référence de base. */
  description: text('description'),
  bannerType: recipeStepBannerEnum('banner_type'),
  bannerText: text('banner_text'),
  /** Référence vers une recette de base (is_base = true) — exclusif avec le texte/bannière. */
  baseRecipeRefId: uuid('base_recipe_ref_id').references(
    (): AnyPgColumn => recipes.id,
    { onDelete: 'cascade' },
  ),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
});

/**
 * Liaison étape ↔ ingrédient de la recette (feature recette-etapes / mode cuisine).
 * Sous-ensemble des ingrédients déjà sur la recette (jamais de nouvel ingrédient
 * ici). Pas d'id propre sur `recipe_ingredients` → on référence l'ingrédient
 * directement ; la recette est implicite via l'étape.
 */
export const stepIngredients = pgTable(
  'step_ingredients',
  {
    stepId: uuid('step_id')
      .notNull()
      .references(() => recipeSteps.id, { onDelete: 'cascade' }),
    ingredientId: uuid('ingredient_id')
      .notNull()
      .references(() => ingredients.id, { onDelete: 'cascade' }),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (t) => [primaryKey({ columns: [t.stepId, t.ingredientId] })],
);

/**
 * Rangement : une recette peut appartenir à plusieurs dossiers (feature
 * categories). Pivot (recipe_id, category_id). Alimente le `recipeCount` réel
 * exposé par la feature Catégories.
 */
export const recipeCategories = pgTable(
  'recipe_categories',
  {
    recipeId: uuid('recipe_id')
      .notNull()
      .references(() => recipes.id, { onDelete: 'cascade' }),
    categoryId: uuid('category_id')
      .notNull()
      .references(() => categories.id, { onDelete: 'cascade' }),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (t) => [primaryKey({ columns: [t.recipeId, t.categoryId] })],
);

/**
 * Étiquetage : une recette peut porter plusieurs tags (feature tags-personnes).
 * Pivot (recipe_id, tag_id). Alimente le `recipeCount` réel exposé par Tags.
 */
export const recipeTags = pgTable(
  'recipe_tags',
  {
    recipeId: uuid('recipe_id')
      .notNull()
      .references(() => recipes.id, { onDelete: 'cascade' }),
    tagId: uuid('tag_id')
      .notNull()
      .references(() => tags.id, { onDelete: 'cascade' }),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (t) => [primaryKey({ columns: [t.recipeId, t.tagId] })],
);

export const recipesRelations = relations(recipes, ({ many }) => ({
  ingredients: many(recipeIngredients),
  components: many(recipeComponents, { relationName: 'parent' }),
  usedIn: many(recipeComponents, { relationName: 'base' }),
}));

export type RecipeRow = typeof recipes.$inferSelect;
export type NewRecipeRow = typeof recipes.$inferInsert;
export type RecipeIngredientRow = typeof recipeIngredients.$inferSelect;
export type RecipeComponentRow = typeof recipeComponents.$inferSelect;
export type RecipeStepRow = typeof recipeSteps.$inferSelect;
export type StepIngredientRow = typeof stepIngredients.$inferSelect;
