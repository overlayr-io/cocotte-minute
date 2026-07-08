import { Provider } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { drizzle, PostgresJsDatabase } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';

import * as schema from './schema';

/**
 * Token d'injection unique pour l'accès DB. Les services métier injectent CE token
 * (via @Inject(DRIZZLE)) — jamais `drizzle`/`postgres` directement, conformément au
 * principe d'inversion de dépendance : la brique Drizzle reste remplaçable.
 */
export const DRIZZLE = Symbol('DRIZZLE');

export type DrizzleDB = PostgresJsDatabase<typeof schema>;

export const drizzleProvider: Provider = {
  provide: DRIZZLE,
  inject: [ConfigService],
  useFactory: (config: ConfigService): DrizzleDB => {
    const connectionString = config.getOrThrow<string>('DATABASE_URL');
    // prepare:false requis avec les poolers Supabase en mode transaction.
    // ssl:'require' nécessaire pour les connexions sortantes depuis Render vers Supabase.
    const client = postgres(connectionString, { prepare: false, ssl: 'require' });
    return drizzle(client, { schema });
  },
};
