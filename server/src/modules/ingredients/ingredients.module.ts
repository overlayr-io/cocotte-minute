import { Module } from '@nestjs/common';

import { SupabaseStorageService } from '../../common/supabase/supabase-storage.service';
import { BillingModule } from '../billing/billing.module';
import { IngredientPhotosService } from './ingredient-photos.service';
import { IngredientsController } from './ingredients.controller';
import { IngredientsService } from './ingredients.service';

@Module({
  // Billing : statut premium pour le quota des photos « Mes produits » (1/3).
  imports: [BillingModule],
  controllers: [IngredientsController],
  // Les photos « Mes produits » (#14) sont un sous-domaine des ingrédients,
  // comme les alternatives : même module, service dédié.
  providers: [IngredientsService, IngredientPhotosService, SupabaseStorageService],
  // Exporté pour qu'AccountService puisse purger les ingrédients lors du
  // "repartir de zéro" — via le service, jamais le schéma (isolation des domaines).
  exports: [IngredientsService],
})
export class IngredientsModule {}
