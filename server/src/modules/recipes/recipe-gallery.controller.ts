import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  UseGuards,
} from '@nestjs/common';

import { AuthenticatedUser } from '../../common/auth/authenticated-user';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { SupabaseAuthGuard } from '../../common/guards/supabase-auth.guard';
import { AddGalleryImageDto } from './dto/add-gallery-image.dto';
import { AddGalleryResult, RecipeGalleryService } from './recipe-gallery.service';
import type { RecipeGalleryPhotoDto } from './recipes.service';

/**
 * Photos de galerie d'une recette (feature galerie-recette), en sous-ressource
 * de la recette — cohérent avec les ingrédients/étapes/composants montés sous
 * `/recipes/:id/…`. Toutes les routes sont réservées au propriétaire (vérifié
 * dans le service via `assertOwnedRecipe`).
 */
@Controller('recipes/:recipeId/gallery')
@UseGuards(SupabaseAuthGuard)
export class RecipeGalleryController {
  constructor(private readonly galleryService: RecipeGalleryService) {}

  @Get()
  list(
    @CurrentUser() user: AuthenticatedUser,
    @Param('recipeId', ParseUUIDPipe) recipeId: string,
  ): Promise<RecipeGalleryPhotoDto[]> {
    return this.galleryService.list(user.id, recipeId);
  }

  @Post()
  add(
    @CurrentUser() user: AuthenticatedUser,
    @Param('recipeId', ParseUUIDPipe) recipeId: string,
    @Body() dto: AddGalleryImageDto,
  ): Promise<AddGalleryResult> {
    return this.galleryService.add(user.id, recipeId, dto.imageUrl);
  }

  @Delete(':imageId')
  remove(
    @CurrentUser() user: AuthenticatedUser,
    @Param('recipeId', ParseUUIDPipe) recipeId: string,
    @Param('imageId', ParseUUIDPipe) imageId: string,
  ): Promise<{ photos: RecipeGalleryPhotoDto[] }> {
    return this.galleryService.remove(user.id, recipeId, imageId);
  }
}
