import { relations } from 'drizzle-orm';
import { type AnyPgColumn, pgTable, timestamp, uuid, varchar } from 'drizzle-orm/pg-core';

/**
 * Palette de couleurs d'un tag (cf. maquette 3m). Valeurs stockées en base =
 * codes hex stables, choisis dans cette liste fermée (pas de couleur libre pour
 * l'instant, pour garantir un rendu cohérent des pastilles/chips).
 */
export const TAG_COLORS = [
  '#3F7D3A', // vert
  '#B14A3F', // rouge
  '#3D6DA8', // bleu
  '#B8862F', // or
  '#8A5BB0', // violet
  '#C86A3C', // orange
] as const;

export type TagColor = (typeof TAG_COLORS)[number];

/**
 * Catalogue de tags système (`owner_id = null`), semé au premier accès au
 * catalogue (seeding paresseux, cf. `TagsService.ensureSystemDefaults`) et par
 * le script `db:seed:tags`. Source unique de vérité de la liste — chaque
 * couleur doit appartenir à `TAG_COLORS` (garanti au compile-time).
 */
export const SYSTEM_TAGS: readonly { name: string; color: TagColor }[] = [
  { name: 'Rapide', color: '#B8862F' },
  { name: 'Économique', color: '#B8862F' },
  { name: 'Végétarien', color: '#3F7D3A' },
  { name: 'Végan', color: '#3F7D3A' },
  { name: 'Sans gluten', color: '#3F7D3A' },
  { name: 'Sans lactose', color: '#3F7D3A' },
  { name: 'Healthy', color: '#3F7D3A' },
  { name: 'Enfants', color: '#8A5BB0' },
  { name: 'Apéro', color: '#C86A3C' },
  { name: 'Entrée', color: '#3D6DA8' },
  { name: 'Plat principal', color: '#3D6DA8' },
  { name: 'Dessert', color: '#B14A3F' },
  { name: 'Petit-déjeuner', color: '#C86A3C' },
  { name: 'Weekend', color: '#8A5BB0' },
  { name: 'Four', color: '#B8862F' },
  { name: 'Sans cuisson', color: '#3F7D3A' },
  { name: 'Barbecue', color: '#B14A3F' },
  { name: 'Fait maison', color: '#3F7D3A' },
  { name: 'Reste du frigo', color: '#B8862F' },
  { name: 'Fête', color: '#8A5BB0' },
];

/**
 * Tags — système (`owner_id = null`, catalogue) vs copie utilisateur
 * (`owner_id = uid`). Même mécanique que les ingrédients (ingredients.md) :
 * "importer" un tag système crée une copie indépendante qui garde un lien
 * vers l'origine via `imported_from_id`. Un tag qualifie recettes,
 * sous-recettes et personnes.
 *
 * Suppression = soft delete (`deleted_at`), jamais d'effacement réel, pour ne
 * pas casser les entités (recettes/personnes) qui référencent le tag via les
 * tables pivot `recipe_tags` / `person_tags`.
 */
export const tags = pgTable('tags', {
  id: uuid('id').primaryKey().defaultRandom(),
  /** UUID Supabase du propriétaire. NULL = tag système (catalogue de base). */
  ownerId: uuid('owner_id'),
  name: varchar('name', { length: 60 }).notNull(),
  /** Code couleur hex (#RRGGBB) choisi dans `TAG_COLORS`. */
  color: varchar('color', { length: 7 }).notNull(),
  /** Tag système d'origine si cette ligne est une copie importée. */
  importedFromId: uuid('imported_from_id').references((): AnyPgColumn => tags.id, {
    onDelete: 'set null',
  }),
  /** Soft delete : non-null = supprimé. Toujours filtrer `IS NULL` en lecture. */
  deletedAt: timestamp('deleted_at', { withTimezone: true }),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
});

export const tagsRelations = relations(tags, ({ one }) => ({
  importedFrom: one(tags, {
    fields: [tags.importedFromId],
    references: [tags.id],
  }),
}));

export type TagRow = typeof tags.$inferSelect;
export type NewTagRow = typeof tags.$inferInsert;
