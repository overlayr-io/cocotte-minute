import { Module } from '@nestjs/common';

import { IngredientsController } from './ingredients.controller';
import { IngredientsService } from './ingredients.service';

@Module({
  controllers: [IngredientsController],
  providers: [IngredientsService],
  // Exporté pour qu'AccountService puisse purger les ingrédients lors du
  // "repartir de zéro" — via le service, jamais le schéma (isolation des domaines).
  exports: [IngredientsService],
})
export class IngredientsModule {}
