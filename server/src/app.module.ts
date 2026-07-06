import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { validateEnv } from './config/env.validation';
import { DbModule } from './db/db.module';
import { AccountModule } from './modules/account/account.module';
import { HealthModule } from './modules/health/health.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      validate: validateEnv,
      // Sélection du fichier d'env selon NODE_ENV (défaut = development, local).
      // Les fichiers sont chargés dans l'ordre : le premier trouvé a priorité,
      // `.env` restant un ultime fallback. Voir README « Lancer en local ».
      envFilePath: [
        `.env.${process.env.NODE_ENV ?? 'development'}`,
        '.env',
      ],
    }),
    DbModule,
    // Modules métier (un module = une feature) :
    HealthModule,
    AccountModule,
  ],
})
export class AppModule {}
