import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_FILTER } from '@nestjs/core';
import { LoggerModule } from 'nestjs-pino';

import { AllExceptionsFilter } from './common/filters/all-exceptions.filter';
import { validateEnv } from './config/env.validation';
import { DbModule } from './db/db.module';
import { AccountModule } from './modules/account/account.module';
import { HealthModule } from './modules/health/health.module';
import { IngredientsModule } from './modules/ingredients/ingredients.module';
import { PeopleModule } from './modules/people/people.module';
import { TagsModule } from './modules/tags/tags.module';

const isProduction = process.env.NODE_ENV === 'production';

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
    // Journalisation HTTP (entrée/sortie de chaque requête) via nestjs-pino.
    // En dev : sortie lisible (pino-pretty). En prod : JSON structuré.
    LoggerModule.forRoot({
      pinoHttp: {
        level: process.env.LOG_LEVEL ?? (isProduction ? 'info' : 'debug'),
        transport: isProduction
          ? undefined
          : {
              target: 'pino-pretty',
              options: {
                singleLine: true,
                colorize: true,
                translateTime: 'SYS:HH:MM:ss',
                ignore: 'pid,hostname',
              },
            },
        autoLogging: true,
        customReceivedMessage: (req) => `→ ${req.method} ${req.url}`,
        customSuccessMessage: (req, res, responseTime) =>
          `← ${req.method} ${req.url} ${res.statusCode} (${responseTime}ms)`,
        customErrorMessage: (req, res) =>
          `✖ ${req.method} ${req.url} ${res.statusCode}`,
        // Ne jamais logger le JWT ni les cookies.
        redact: { paths: ['req.headers.authorization', 'req.headers.cookie'], remove: true },
        serializers: {
          req: (req: { method: string; url: string }) => ({
            method: req.method,
            url: req.url,
          }),
        },
      },
    }),
    DbModule,
    // Modules métier (un module = une feature) :
    HealthModule,
    IngredientsModule,
    TagsModule,
    PeopleModule,
    AccountModule,
  ],
  providers: [
    // Filtre global : journalise et normalise toutes les erreurs.
    { provide: APP_FILTER, useClass: AllExceptionsFilter },
  ],
})
export class AppModule {}
