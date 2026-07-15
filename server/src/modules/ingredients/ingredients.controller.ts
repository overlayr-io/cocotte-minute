import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';

import { AuthenticatedUser } from '../../common/auth/authenticated-user';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { SupabaseAuthGuard } from '../../common/guards/supabase-auth.guard';
import {
  IngredientPhotoDto,
  IngredientPhotosService,
} from './ingredient-photos.service';
import { AddAlternativeDto } from './dto/add-alternative.dto';
import { AddIngredientPhotoDto } from './dto/add-ingredient-photo.dto';
import { CreateIngredientDto } from './dto/create-ingredient.dto';
import { UpdateIngredientDto } from './dto/update-ingredient.dto';
import {
  IngredientDetailDto,
  IngredientDto,
  IngredientsService,
  SystemIngredientDto,
} from './ingredients.service';

@Controller('ingredients')
@UseGuards(SupabaseAuthGuard)
export class IngredientsController {
  constructor(
    private readonly ingredientsService: IngredientsService,
    private readonly ingredientPhotosService: IngredientPhotosService,
  ) {}

  /** Mes ingrédients (copies importées + customs). */
  @Get()
  listMine(@CurrentUser() user: AuthenticatedUser): Promise<IngredientDto[]> {
    return this.ingredientsService.listMine(user.id);
  }

  /** Catalogue système, annoté "déjà importé". */
  @Get('system')
  listSystem(@CurrentUser() user: AuthenticatedUser): Promise<SystemIngredientDto[]> {
    return this.ingredientsService.listSystem(user.id);
  }

  @Get(':id')
  getOne(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<IngredientDetailDto> {
    return this.ingredientsService.getDetail(user.id, id);
  }

  @Post()
  create(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateIngredientDto,
  ): Promise<IngredientDto> {
    return this.ingredientsService.create(user.id, dto);
  }

  /** Importe un ingrédient système → copie indépendante appartenant à l'utilisateur. */
  @Post(':id/import')
  import(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<IngredientDto> {
    return this.ingredientsService.importSystem(user.id, id);
  }

  @Patch(':id')
  update(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateIngredientDto,
  ): Promise<IngredientDto> {
    return this.ingredientsService.update(user.id, id, dto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  remove(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<void> {
    return this.ingredientsService.softDelete(user.id, id);
  }

  @Post(':id/alternatives')
  @HttpCode(HttpStatus.NO_CONTENT)
  addAlternative(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: AddAlternativeDto,
  ): Promise<void> {
    return this.ingredientsService.addAlternative(user.id, id, dto.alternativeId);
  }

  @Delete(':id/alternatives/:alternativeId')
  @HttpCode(HttpStatus.NO_CONTENT)
  removeAlternative(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Param('alternativeId', ParseUUIDPipe) alternativeId: string,
  ): Promise<void> {
    return this.ingredientsService.removeAlternative(user.id, id, alternativeId);
  }

  // --- photos « Mes produits » (#14) -------------------------------------

  @Get(':id/photos')
  listPhotos(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<IngredientPhotoDto[]> {
    return this.ingredientPhotosService.list(user.id, id);
  }

  @Post(':id/photos')
  addPhoto(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: AddIngredientPhotoDto,
  ): Promise<IngredientPhotoDto[]> {
    return this.ingredientPhotosService.add(user.id, id, dto.imageUrl);
  }

  @Delete(':id/photos/:photoId')
  @HttpCode(HttpStatus.NO_CONTENT)
  removePhoto(
    @CurrentUser() user: AuthenticatedUser,
    @Param('photoId', ParseUUIDPipe) photoId: string,
  ): Promise<void> {
    return this.ingredientPhotosService.remove(user.id, photoId);
  }
}
