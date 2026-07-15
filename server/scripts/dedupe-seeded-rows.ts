/**
 * Nettoyage des doublons laissés par les semis paresseux non verrouillés.
 *
 * Contexte : `categories.ensureDefaults`, `tags.ensureSystemDefaults` et
 * `recipes.seedSamples` faisaient « lire puis insérer si absent » sans verrou.
 * Deux requêtes concurrentes sur un compte/catalogue vierge semaient chacune
 * leur jeu, d'où des dossiers et tags en double. Le verrou consultatif
 * (`common/db/advisory-locks.ts`) empêche les NOUVEAUX doublons, mais ne
 * répare pas les lignes déjà écrites : ce script s'en charge.
 *
 * Stratégie : pour chaque groupe de doublons, on garde la ligne la plus
 * ancienne (`created_at` puis `id` pour départager) et on supprime les autres.
 * On ne touche qu'aux lignes SEMÉES automatiquement :
 *   - `categories` où `is_default = true` (les dossiers créés à la main sont
 *     hors périmètre : deux dossiers homonymes sous des parents différents sont
 *     légitimes) ;
 *   - `tags` où `owner_id is null` (catalogue système).
 * Les recettes ne sont PAS dédupliquées automatiquement : un doublon de recette
 * peut être une duplication volontaire de l'utilisateur (« … (copie) ») ou du
 * contenu édité depuis. Le script les signale, à toi de trancher.
 *
 * À blanc par défaut (n'écrit rien, se contente de lister) :
 *   npx ts-node --transpile-only scripts/dedupe-seeded-rows.ts
 * Pour appliquer réellement les suppressions :
 *   npx ts-node --transpile-only scripts/dedupe-seeded-rows.ts --apply
 *
 * Nécessite `DATABASE_URL`. À lancer une fois, après le déploiement du correctif
 * de verrou : sans lui, les doublons déjà en base restent affichés.
 */
import 'dotenv/config';
import { drizzle } from 'drizzle-orm/postgres-js';
import { sql } from 'drizzle-orm';
import postgres from 'postgres';

const APPLY = process.argv.includes('--apply');

type DupRow = { key: string; n: number };

async function main(): Promise<void> {
  const connectionString = process.env.DATABASE_URL;
  if (!connectionString) {
    throw new Error('DATABASE_URL manquant : impossible de dédupliquer.');
  }

  const client = postgres(connectionString, { prepare: false, ssl: 'require' });
  const db = drizzle(client);

  try {
    console.log(APPLY ? '=== MODE APPLIQUÉ (suppressions réelles) ===' : '=== À BLANC (aucune écriture) ===');

    // --- 1) Dossiers par défaut en double, par (owner_id, name) -------------
    const catDups = await db.execute<DupRow>(sql`
      select owner_id::text || ' / ' || name as key, count(*)::int as n
      from categories
      where is_default = true
      group by owner_id, name
      having count(*) > 1
      order by n desc
    `);
    report('Dossiers par défaut en double', catDups);

    if (APPLY && catDups.length > 0) {
      const deleted = await db.execute(sql`
        delete from categories c
        using (
          select id, row_number() over (
            partition by owner_id, name order by created_at asc, id asc
          ) as rn
          from categories
          where is_default = true
        ) d
        where c.id = d.id and d.rn > 1
      `);
      console.log(`  → ${deleted.count ?? 0} dossier(s) en trop supprimé(s).`);
    }

    // --- 2) Tags système en double, par name --------------------------------
    const tagDups = await db.execute<DupRow>(sql`
      select name as key, count(*)::int as n
      from tags
      where owner_id is null
      group by name
      having count(*) > 1
      order by n desc
    `);
    report('Tags système en double', tagDups);

    if (APPLY && tagDups.length > 0) {
      const deleted = await db.execute(sql`
        delete from tags t
        using (
          select id, row_number() over (
            partition by name order by created_at asc, id asc
          ) as rn
          from tags
          where owner_id is null
        ) d
        where t.id = d.id and d.rn > 1
      `);
      console.log(`  → ${deleted.count ?? 0} tag(s) système en trop supprimé(s).`);
    }

    // --- 3) Recettes homonymes : signalées, jamais supprimées ---------------
    const recipeDups = await db.execute<DupRow>(sql`
      select author_id::text || ' / ' || name as key, count(*)::int as n
      from recipes
      where deleted_at is null
      group by author_id, name
      having count(*) > 1
      order by n desc
    `);
    report('Recettes homonymes (NON supprimées, à trancher à la main)', recipeDups);

    if (!APPLY) {
      console.log('\nRelance avec `-- --apply` pour appliquer les suppressions.');
    }
  } finally {
    await client.end();
  }
}

function report(title: string, rows: readonly DupRow[]): void {
  console.log(`\n${title} : ${rows.length} groupe(s)`);
  for (const r of rows) {
    console.log(`  - ${r.key} → ${r.n} exemplaires`);
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
