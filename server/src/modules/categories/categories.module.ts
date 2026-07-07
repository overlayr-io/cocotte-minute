import { Module } from '@nestjs/common';

import { RecipesModule } from '../recipes/recipes.module';
import { CategoriesController } from './categories.controller';
import { CategoriesService } from './categories.service';

@Module({
  // Importe RecipesModule pour le compteur recipeCount (dépendance à sens unique).
  imports: [RecipesModule],
  controllers: [CategoriesController],
  providers: [CategoriesService],
  // Exporté pour qu'AccountService puisse purger les catégories lors du
  // "repartir de zéro" — via le service, jamais le schéma (isolation des domaines).
  exports: [CategoriesService],
})
export class CategoriesModule {}
