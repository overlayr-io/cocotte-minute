import { Module } from '@nestjs/common';

import { CategoriesModule } from '../categories/categories.module';
import { IngredientsModule } from '../ingredients/ingredients.module';
import { PeopleModule } from '../people/people.module';
import { RecipesModule } from '../recipes/recipes.module';
import { ShoppingListsModule } from '../shopping-lists/shopping-lists.module';
import { TagsModule } from '../tags/tags.module';
import { AccountController } from './account.controller';
import { AccountService } from './account.service';

@Module({
  // Importe les modules métier pour purger chaque domaine via leur service
  // exporté (jamais leur schéma) lors du "repartir de zéro".
  imports: [
    IngredientsModule,
    TagsModule,
    PeopleModule,
    CategoriesModule,
    RecipesModule,
    ShoppingListsModule,
  ],
  controllers: [AccountController],
  providers: [AccountService],
})
export class AccountModule {}
