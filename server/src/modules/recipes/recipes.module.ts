import { Module } from '@nestjs/common';

import { IngredientsModule } from '../ingredients/ingredients.module';
import { RecipesController } from './recipes.controller';
import { RecipesService } from './recipes.service';

@Module({
  // Recipes hydrate/valide les ingrédients via IngredientsService (isolation).
  imports: [IngredientsModule],
  controllers: [RecipesController],
  providers: [RecipesService],
  // Exporté pour : AccountService (purge "repartir de zéro") et les compteurs
  // recipeCount de TagsService / CategoriesService (dépendance à sens unique).
  exports: [RecipesService],
})
export class RecipesModule {}
