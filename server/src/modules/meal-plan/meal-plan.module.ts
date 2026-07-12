import { Module } from '@nestjs/common';

import { BillingModule } from '../billing/billing.module';
import { RecipesModule } from '../recipes/recipes.module';
import { MealPlanController } from './meal-plan.controller';
import { MealPlanService } from './meal-plan.service';

@Module({
  // Recipes : hydratation des entrées (résumés) + ownership. Billing : gardes
  // premium (fenêtre T/T+1, 1 entrée/créneau). Toujours via services exportés.
  imports: [RecipesModule, BillingModule],
  controllers: [MealPlanController],
  providers: [MealPlanService],
  // Exporté pour la purge cascade d'AccountService (RGPD / repartir de zéro).
  exports: [MealPlanService],
})
export class MealPlanModule {}
