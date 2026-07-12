/**
 * Seed du catalogue de tags système (owner_id = null).
 *
 * Source : scripts/data/system-tags.json. Idempotent : un tag système déjà
 * présent (même nom, owner null, non supprimé) est ignoré — on peut relancer
 * le script sans créer de doublons.
 *
 * Lancement : `npm run db:seed:tags` (nécessite DATABASE_URL dans l'env).
 */
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

import 'dotenv/config';
import { and, eq, isNull } from 'drizzle-orm';
import { drizzle } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';

import { TAG_COLORS, type TagColor, tags } from '../src/db/schema/tags.schema';

interface SeedItem {
  name: string;
  color: TagColor;
}

function loadItems(): SeedItem[] {
  const raw = readFileSync(join(__dirname, 'data', 'system-tags.json'), 'utf-8');
  const parsed = JSON.parse(raw) as SeedItem[];
  for (const item of parsed) {
    if (!item.name || !TAG_COLORS.includes(item.color)) {
      throw new Error(`Entrée invalide dans system-tags.json : ${JSON.stringify(item)}`);
    }
  }
  return parsed;
}

async function main(): Promise<void> {
  const connectionString = process.env.DATABASE_URL;
  if (!connectionString) {
    throw new Error('DATABASE_URL manquant : impossible de seeder les tags système.');
  }

  const client = postgres(connectionString, { prepare: false });
  const db = drizzle(client, { schema: { tags } });

  try {
    const items = loadItems();
    let created = 0;
    let skipped = 0;

    for (const item of items) {
      const [existing] = await db
        .select({ id: tags.id })
        .from(tags)
        .where(and(eq(tags.name, item.name), isNull(tags.ownerId), isNull(tags.deletedAt)));

      if (existing) {
        skipped += 1;
        continue;
      }

      await db.insert(tags).values({
        ownerId: null,
        name: item.name,
        color: item.color,
      });
      created += 1;
    }

    // eslint-disable-next-line no-console
    console.log(`Seed tags système : ${created} créés, ${skipped} déjà présents.`);
  } finally {
    await client.end();
  }
}

main().catch((err) => {
  // eslint-disable-next-line no-console
  console.error(err);
  process.exit(1);
});
