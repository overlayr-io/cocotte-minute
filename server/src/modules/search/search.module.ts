import { Module } from '@nestjs/common';

import { BillingModule } from '../billing/billing.module';
import { CategoriesModule } from '../categories/categories.module';
import { PeopleModule } from '../people/people.module';
import { RecipesModule } from '../recipes/recipes.module';
import { SearchController } from './search.controller';
import { SearchService } from './search.service';

@Module({
  // Domaine transverse : importe les trois services propriétaires (Recipes,
  // Categories, People) et n'est importé par personne → pas de cycle (Tags /
  // Categories importent déjà Recipes pour leurs compteurs, sens unique).
  // Billing : plafond freemium de critères cumulés.
  imports: [RecipesModule, CategoriesModule, PeopleModule, BillingModule],
  controllers: [SearchController],
  providers: [SearchService],
})
export class SearchModule {}
