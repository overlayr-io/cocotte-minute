import { pgTable, timestamp, uniqueIndex, uuid } from 'drizzle-orm/pg-core';

import { people } from './people.schema';
import { tags } from './tags.schema';

/**
 * Liaison Personne ↔ Tag (n-n). Une personne peut porter 0..n tags, un tag peut
 * être associé à plusieurs personnes. Index unique sur (person_id, tag_id) pour
 * empêcher les doublons ; FK en cascade : supprimer une personne ou un tag
 * retire automatiquement les liaisons correspondantes.
 */
export const personTags = pgTable(
  'person_tags',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    personId: uuid('person_id')
      .notNull()
      .references(() => people.id, { onDelete: 'cascade' }),
    tagId: uuid('tag_id')
      .notNull()
      .references(() => tags.id, { onDelete: 'cascade' }),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (table) => [uniqueIndex('person_tags_pair_uq').on(table.personId, table.tagId)],
);

export type PersonTagRow = typeof personTags.$inferSelect;
