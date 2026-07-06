/**
 * Seed du catalogue d'ingrédients système (owner_id = null).
 *
 * Source : scripts/data/system-ingredients.json (fichier config, cf. ingredients.md).
 * Idempotent : un ingrédient système déjà présent (même nom, owner null, non
 * supprimé) est ignoré — on peut relancer le script sans créer de doublons.
 *
 * Lancement : `npm run db:seed:ingredients` (nécessite DATABASE_URL dans l'env).
 */
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

import 'dotenv/config';
import { and, eq, isNull } from 'drizzle-orm';
import { drizzle } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';

import {
  INGREDIENT_UNITS,
  type IngredientUnit,
  ingredients,
} from '../src/db/schema/ingredients.schema';

interface SeedItem {
  name: string;
  unit: IngredientUnit;
  imageUrl?: string;
}

function loadItems(): SeedItem[] {
  const raw = readFileSync(join(__dirname, 'data', 'system-ingredients.json'), 'utf-8');
  const parsed = JSON.parse(raw) as SeedItem[];
  for (const item of parsed) {
    if (!item.name || !INGREDIENT_UNITS.includes(item.unit)) {
      throw new Error(`Entrée invalide dans system-ingredients.json : ${JSON.stringify(item)}`);
    }
  }
  return parsed;
}

async function main(): Promise<void> {
  const connectionString = process.env.DATABASE_URL;
  if (!connectionString) {
    throw new Error('DATABASE_URL manquant : impossible de seeder les ingrédients système.');
  }

  const client = postgres(connectionString, { prepare: false });
  const db = drizzle(client, { schema: { ingredients } });

  try {
    const items = loadItems();
    let created = 0;
    let skipped = 0;

    for (const item of items) {
      const [existing] = await db
        .select({ id: ingredients.id })
        .from(ingredients)
        .where(
          and(
            eq(ingredients.name, item.name),
            isNull(ingredients.ownerId),
            isNull(ingredients.deletedAt),
          ),
        );

      if (existing) {
        skipped += 1;
        continue;
      }

      await db.insert(ingredients).values({
        ownerId: null,
        name: item.name,
        unit: item.unit,
        imageUrl: item.imageUrl ?? null,
      });
      created += 1;
    }

    // eslint-disable-next-line no-console
    console.log(`Seed ingrédients système : ${created} créés, ${skipped} déjà présents.`);
  } finally {
    await client.end();
  }
}

main().catch((err) => {
  // eslint-disable-next-line no-console
  console.error(err);
  process.exit(1);
});
