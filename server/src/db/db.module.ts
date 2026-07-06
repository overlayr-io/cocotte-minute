import { Global, Module } from '@nestjs/common';

import { DRIZZLE, drizzleProvider } from './drizzle.provider';

/**
 * Module global d'accès DB. Rendu @Global pour que le token DRIZZLE soit injectable
 * dans tous les modules métier sans réimporter DbModule partout — l'accès Drizzle est
 * une infrastructure transverse, pas un domaine métier.
 */
@Global()
@Module({
  providers: [drizzleProvider],
  exports: [DRIZZLE],
})
export class DbModule {}
