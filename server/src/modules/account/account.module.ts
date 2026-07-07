import { Module } from '@nestjs/common';

import { CategoriesModule } from '../categories/categories.module';
import { IngredientsModule } from '../ingredients/ingredients.module';
import { PeopleModule } from '../people/people.module';
import { TagsModule } from '../tags/tags.module';
import { AccountController } from './account.controller';
import { AccountService } from './account.service';

@Module({
  // Importe Ingredients/Tags/People/CategoriesModule pour purger ces domaines via
  // leurs services exportés (jamais leur schéma) lors du "repartir de zéro".
  imports: [IngredientsModule, TagsModule, PeopleModule, CategoriesModule],
  controllers: [AccountController],
  providers: [AccountService],
})
export class AccountModule {}
