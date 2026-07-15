/**
 * Seed du catalogue de tags système (owner_id = null).
 *
 * Source : constante `SYSTEM_TAGS` (src/db/schema/tags.schema.ts), source unique
 * partagée avec le seeding paresseux du service. Idempotent : un tag système
 * déjà présent (même nom, owner null, non supprimé) est ignoré — on peut
 * relancer le script sans créer de doublons.
 *
 * Note : depuis l'ajout du seeding paresseux (`TagsService.ensureSystemDefaults`),
 * ce script est surtout un filet manuel — le catalogue se remplit tout seul au
 * premier accès. Lancement : `npm run db:seed:tags` (nécessite DATABASE_URL).
 */
import 'dotenv/config';
import { and, eq, isNull } from 'drizzle-orm';
import { drizzle } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';

import { SYSTEM_TAGS, tags } from '../src/db/schema/tags.schema';

async function main(): Promise<void> {
  const connectionString = process.env.DATABASE_URL;
  if (!connectionString) {
    throw new Error('DATABASE_URL manquant : impossible de seeder les tags système.');
  }

  const client = postgres(connectionString, { prepare: false });
  const db = drizzle(client, { schema: { tags } });

  try {
    const items = SYSTEM_TAGS;
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
