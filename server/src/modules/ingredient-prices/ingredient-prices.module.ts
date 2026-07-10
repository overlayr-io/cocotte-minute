import { Module } from '@nestjs/common';

import { BillingModule } from '../billing/billing.module';
import { IngredientsModule } from '../ingredients/ingredients.module';
import { IngredientPricesController } from './ingredient-prices.controller';
import { IngredientPricesService } from './ingredient-prices.service';

/**
 * Prix estimé des ingrédients (feature prix-estime) : prix propre à chaque
 * utilisateur, y compris sur un ingrédient système partagé. Aucun calcul ici
 * (moyenne/scaling/agrégation) — tout est côté client, le serveur ne fait que
 * stocker/retourner les valeurs saisies.
 */
@Module({
  imports: [IngredientsModule, BillingModule],
  controllers: [IngredientPricesController],
  providers: [IngredientPricesService],
  exports: [IngredientPricesService],
})
export class IngredientPricesModule {}
