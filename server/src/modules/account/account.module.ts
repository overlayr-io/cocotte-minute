import { Module } from '@nestjs/common';

import { IngredientsModule } from '../ingredients/ingredients.module';
import { PeopleModule } from '../people/people.module';
import { TagsModule } from '../tags/tags.module';
import { AccountController } from './account.controller';
import { AccountService } from './account.service';

@Module({
  // Importe Ingredients/Tags/PeopleModule pour purger ces domaines via leurs
  // services exportés (jamais leur schéma) lors du "repartir de zéro".
  imports: [IngredientsModule, TagsModule, PeopleModule],
  controllers: [AccountController],
  providers: [AccountService],
})
export class AccountModule {}
