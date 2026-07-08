import { Module } from '@nestjs/common';

import { RecipesModule } from '../recipes/recipes.module';
import { PublicSharesController } from './public-shares.controller';
import { SharesController } from './shares.controller';
import { SharesService } from './shares.service';

/**
 * Feature partage-recette : génération d'un lien (authentifié) + lecture publique
 * (page web, JSON, fichiers deep link). Dépend de RecipesService pour l'hydratation
 * de la fiche et le contrôle de propriété (isolation des domaines).
 */
@Module({
  imports: [RecipesModule],
  controllers: [SharesController, PublicSharesController],
  providers: [SharesService],
})
export class SharesModule {}
