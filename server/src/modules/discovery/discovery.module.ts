import { Module } from '@nestjs/common';

import { CategoriesModule } from '../categories/categories.module';
import { PeopleModule } from '../people/people.module';
import { RecipesModule } from '../recipes/recipes.module';
import { DiscoveryController } from './discovery.controller';
import { DiscoveryService } from './discovery.service';

@Module({
  // Domaine transverse (comme SearchModule) : importe les services propriétaires
  // et n'est importé par personne → pas de cycle.
  imports: [RecipesModule, CategoriesModule, PeopleModule],
  controllers: [DiscoveryController],
  providers: [DiscoveryService],
})
export class DiscoveryModule {}
