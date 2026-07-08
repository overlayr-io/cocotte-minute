import { Module } from '@nestjs/common';

import { RecipesModule } from '../recipes/recipes.module';
import { TagsModule } from '../tags/tags.module';
import { PeopleController } from './people.controller';
import { PeopleService } from './people.service';

@Module({
  // Importe TagsModule / RecipesModule pour hydrater et valider les tags et
  // recettes associés via leurs services exportés (jamais leurs schémas) —
  // isolation des domaines. Pas de cycle : RecipesModule n'importe pas People.
  imports: [TagsModule, RecipesModule],
  controllers: [PeopleController],
  providers: [PeopleService],
  // Exporté pour qu'AccountService puisse purger les personnes lors du
  // "repartir de zéro".
  exports: [PeopleService],
})
export class PeopleModule {}
