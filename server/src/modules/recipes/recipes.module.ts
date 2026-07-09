import { Module } from '@nestjs/common';

import { BillingModule } from '../billing/billing.module';
import { IngredientsModule } from '../ingredients/ingredients.module';
import { RecipesController } from './recipes.controller';
import { RecipesService } from './recipes.service';

@Module({
  // Recipes hydrate/valide les ingrédients via IngredientsService (isolation).
  // Billing : lecture du statut premium pour la garde « 5 recettes de base ».
  imports: [IngredientsModule, BillingModule],
  controllers: [RecipesController],
  providers: [RecipesService],
  // Exporté pour : AccountService (purge "repartir de zéro") et les compteurs
  // recipeCount de TagsService / CategoriesService (dépendance à sens unique).
  exports: [RecipesService],
})
export class RecipesModule {}
