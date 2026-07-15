import {
  date,
  integer,
  pgEnum,
  pgTable,
  timestamp,
  uuid,
  varchar,
} from 'drizzle-orm/pg-core';

import { recipes } from './recipes.schema';

/** Créneaux fixes d'une journée (cf. features/planification-repas.md). */
export const MEAL_SLOTS = ['matin', 'midi', 'soir'] as const;
export type MealSlot = (typeof MEAL_SLOTS)[number];
export const mealSlotEnum = pgEnum('meal_slot', MEAL_SLOTS);

/**
 * Types d'entrée d'un créneau : une recette existante, « manger dehors »
 * (repas hors planning) ou une note libre (repas à la volée sans recette).
 */
export const MEAL_ENTRY_TYPES = ['recipe', 'eating_out', 'note'] as const;
export type MealEntryType = (typeof MEAL_ENTRY_TYPES)[number];
export const mealEntryTypeEnum = pgEnum('meal_entry_type', MEAL_ENTRY_TYPES);

/**
 * Entrées du planning de repas (cf. features/planification-repas.md).
 *
 * Une ligne = une entrée sur un créneau (jour + matin/midi/soir) du planning
 * global du compte. Rétention glissante T-1 → T+2 (4 semaines calendaires,
 * lundi → dimanche) purgée en lazy à la lecture/écriture — pas de cron.
 *
 * Gratuit : 1 entrée max par créneau (tous types confondus) et écriture
 * limitée aux semaines T/T+1 — gardes serveur dans MealPlanService.
 *
 * `recipeId` est une **FK vive** en cascade : à la suppression d'une recette,
 * ses entrées de planning disparaissent (décision actée, contrairement aux
 * listes de courses qui snapshotent).
 */
export const mealPlanEntries = pgTable('meal_plan_entries', {
  id: uuid('id').primaryKey().defaultRandom(),
  /** UUID Supabase du propriétaire (uuid nu, pas de table users). */
  ownerId: uuid('owner_id').notNull(),
  /** Jour planifié (date calendaire, sans heure). */
  day: date('day', { mode: 'string' }).notNull(),
  slot: mealSlotEnum('slot').notNull(),
  entryType: mealEntryTypeEnum('entry_type').notNull(),
  /** Recette planifiée — requis si `entry_type = recipe`, NULL sinon. */
  recipeId: uuid('recipe_id').references(() => recipes.id, { onDelete: 'cascade' }),
  /** Texte d'une note libre — requis si `entry_type = note`, NULL sinon. */
  noteText: varchar('note_text', { length: 160 }),
  /** Ordre d'affichage dans le créneau (multi-entrées premium). */
  position: integer('position').notNull().default(0),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
});

export type MealPlanEntryRow = typeof mealPlanEntries.$inferSelect;
export type NewMealPlanEntryRow = typeof mealPlanEntries.$inferInsert;
