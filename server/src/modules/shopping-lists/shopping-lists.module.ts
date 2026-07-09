import { Module } from '@nestjs/common';

import { BillingModule } from '../billing/billing.module';
import { IngredientsModule } from '../ingredients/ingredients.module';
import { RecipesModule } from '../recipes/recipes.module';
import { ShoppingListsController } from './shopping-lists.controller';
import { ShoppingListsService } from './shopping-lists.service';

@Module({
  // Recipes : agrégation des ingrédients d'une recette. Ingredients : résolution
  // des alternatives. Toujours via leur service exporté, jamais leur schéma.
  // Billing : levée de la garde « 1 liste active » pour les comptes premium.
  imports: [RecipesModule, IngredientsModule, BillingModule],
  controllers: [ShoppingListsController],
  providers: [ShoppingListsService],
  // Exporté pour qu'AccountService purge les listes lors du "repartir de zéro".
  exports: [ShoppingListsService],
})
export class ShoppingListsModule {}
