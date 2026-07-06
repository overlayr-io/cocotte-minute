import 'dotenv/config';
import { defineConfig } from 'drizzle-kit';

// Config drizzle-kit (generate / push / studio). Le schéma unique est le barrel
// src/db/schema — source de vérité, jamais de SQL brut hors cas de perf justifié.
export default defineConfig({
  dialect: 'postgresql',
  schema: './src/db/schema/index.ts',
  out: './drizzle',
  dbCredentials: {
    url: process.env.DATABASE_URL!,
  },
  strict: true,
  verbose: true,
});
