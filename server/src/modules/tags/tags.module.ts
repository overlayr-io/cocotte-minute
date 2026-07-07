import { Module } from '@nestjs/common';

import { RecipesModule } from '../recipes/recipes.module';
import { TagsController } from './tags.controller';
import { TagsService } from './tags.service';

@Module({
  // Importe RecipesModule pour le compteur recipeCount (dépendance à sens unique).
  imports: [RecipesModule],
  controllers: [TagsController],
  providers: [TagsService],
  // Exporté pour qu'AccountService puisse purger les tags lors du
  // "repartir de zéro" — via le service, jamais le schéma (isolation des domaines).
  exports: [TagsService],
})
export class TagsModule {}
