import { Module } from '@nestjs/common';

import { SupabaseStorageService } from '../../common/supabase/supabase-storage.service';
import { BillingModule } from '../billing/billing.module';
import { IngredientsModule } from '../ingredients/ingredients.module';
import { RecipeGalleryController } from './recipe-gallery.controller';
import { RecipeGalleryService } from './recipe-gallery.service';
import { RecipesController } from './recipes.controller';
import { RecipesService } from './recipes.service';

@Module({
  // Recipes hydrate/valide les ingrédients via IngredientsService (isolation).
  // Billing : lecture du statut premium pour la garde « 5 recettes de base »
  // et le quota galerie (3/6 par recette).
  imports: [IngredientsModule, BillingModule],
  controllers: [RecipesController, RecipeGalleryController],
  // La galerie (feature galerie-recette) est un sous-domaine des recettes, comme
  // les étapes/composants : même module, pas de module séparé.
  providers: [RecipesService, RecipeGalleryService, SupabaseStorageService],
  // Exporté pour : AccountService (purge "repartir de zéro") et les compteurs
  // recipeCount de TagsService / CategoriesService (dépendance à sens unique).
  exports: [RecipesService],
})
export class RecipesModule {}
