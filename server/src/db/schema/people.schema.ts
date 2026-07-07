import { pgTable, text, timestamp, uuid, varchar } from 'drizzle-orm/pg-core';

/**
 * Personnes (famille) — propres à chaque compte (`owner_id` non-null).
 *
 * Une personne a un prénom (requis), un nom (optionnel) et un avatar (optionnel,
 * upload branché plus tard — un avatar par défaut initiale+couleur est dérivé
 * côté client tant que `avatar_url` est null). On lui associe des tags via la
 * table pivot `person_tags`.
 *
 * Suppression = soft delete (`deleted_at`), jamais d'effacement réel.
 */
export const people = pgTable('people', {
  id: uuid('id').primaryKey().defaultRandom(),
  ownerId: uuid('owner_id').notNull(),
  firstName: varchar('first_name', { length: 80 }).notNull(),
  lastName: varchar('last_name', { length: 80 }),
  avatarUrl: text('avatar_url'),
  deletedAt: timestamp('deleted_at', { withTimezone: true }),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
});

export type PersonRow = typeof people.$inferSelect;
export type NewPersonRow = typeof people.$inferInsert;
