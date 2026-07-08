import { setDefaultResultOrder } from 'node:dns';

import { ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NestFactory } from '@nestjs/core';
import { Logger } from 'nestjs-pino';

import { AppModule } from './app.module';

setDefaultResultOrder('ipv4first');

async function bootstrap(): Promise<void> {
  // bufferLogs: on retient les logs de bootstrap jusqu'à ce que pino prenne le relais.
  const app = await NestFactory.create(AppModule, { bufferLogs: true });

  // Toute la journalisation (Nest inclus) passe désormais par pino.
  app.useLogger(app.get(Logger));

  // Validation globale des DTO via class-validator (règle projet).
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  const config = app.get(ConfigService);
  const port = config.get<number>('PORT', 3000);
  await app.listen(port);

  app.get(Logger).log(`Cocotte Minute server prêt sur http://localhost:${port}`);
}

void bootstrap();
