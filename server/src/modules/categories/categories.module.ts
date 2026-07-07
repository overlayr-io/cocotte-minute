import { Module } from '@nestjs/common';

import { CategoriesController } from './categories.controller';
import { CategoriesService } from './categories.service';

@Module({
  controllers: [CategoriesController],
  providers: [CategoriesService],
  // Exporté pour qu'AccountService puisse purger les catégories lors du
  // "repartir de zéro" — via le service, jamais le schéma (isolation des domaines).
  exports: [CategoriesService],
})
export class CategoriesModule {}
