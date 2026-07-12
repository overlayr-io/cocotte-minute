import { Module } from '@nestjs/common';

import { SupabaseAdminService } from '../../common/supabase/supabase-admin.service';
import { BillingModule } from '../billing/billing.module';
import { CategoriesModule } from '../categories/categories.module';
import { IngredientsModule } from '../ingredients/ingredients.module';
import { PeopleModule } from '../people/people.module';
import { MealPlanModule } from '../meal-plan/meal-plan.module';
import { RecipesModule } from '../recipes/recipes.module';
import { ShoppingListsModule } from '../shopping-lists/shopping-lists.module';
import { TagsModule } from '../tags/tags.module';
import { AccountDeletionCron } from './account-deletion.cron';
import { AccountController } from './account.controller';
import { AccountService } from './account.service';

@Module({
  // Importe les modules métier pour purger chaque domaine via leur service
  // exporté (jamais leur schéma) lors du "repartir de zéro" et de la suppression RGPD.
  // Billing : suppression du subscriber RevenueCat dans la cascade RGPD.
  imports: [
    IngredientsModule,
    TagsModule,
    PeopleModule,
    CategoriesModule,
    RecipesModule,
    ShoppingListsModule,
    MealPlanModule,
    BillingModule,
  ],
  controllers: [AccountController],
  providers: [AccountService, AccountDeletionCron, SupabaseAdminService],
})
export class AccountModule {}
