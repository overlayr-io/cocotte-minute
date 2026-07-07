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
  AddRecipeComponentDto,
  AddRecipeIngredientDto,
  AssignRecipeCategoryDto,
  AssignRecipeTagDto,
} from './dto/recipe-relations.dto';
import { CreateRecipeDto } from './dto/create-recipe.dto';
import { UpdateRecipeDto } from './dto/update-recipe.dto';
import {
  RecipeDetailDto,
  RecipeSummaryDto,
  RecipesService,
} from './recipes.service';

@Controller('recipes')
@UseGuards(SupabaseAuthGuard)
export class RecipesController {
  constructor(private readonly recipesService: RecipesService) {}

  @Get()
  listMine(@CurrentUser() user: AuthenticatedUser): Promise<RecipeSummaryDto[]> {
    return this.recipesService.listMine(user.id);
  }

  @Post()
  create(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateRecipeDto,
  ): Promise<RecipeSummaryDto> {
    return this.recipesService.create(user.id, dto);
  }

  @Get(':id')
  detail(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<RecipeDetailDto> {
    return this.recipesService.getDetail(user.id, id);
  }

  @Patch(':id')
  update(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateRecipeDto,
  ): Promise<RecipeSummaryDto> {
    return this.recipesService.update(user.id, id, dto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  remove(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<void> {
    return this.recipesService.softDelete(user.id, id);
  }

  // --- ingrédients -------------------------------------------------------

  @Post(':id/ingredients')
  @HttpCode(HttpStatus.NO_CONTENT)
  addIngredient(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: AddRecipeIngredientDto,
  ): Promise<void> {
    return this.recipesService.addIngredient(user.id, id, dto.ingredientId);
  }

  @Delete(':id/ingredients/:ingredientId')
  @HttpCode(HttpStatus.NO_CONTENT)
  removeIngredient(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Param('ingredientId', ParseUUIDPipe) ingredientId: string,
  ): Promise<void> {
    return this.recipesService.removeIngredient(user.id, id, ingredientId);
  }

  // --- composants (sous-recettes) ---------------------------------------

  @Post(':id/components')
  @HttpCode(HttpStatus.NO_CONTENT)
  addComponent(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: AddRecipeComponentDto,
  ): Promise<void> {
    return this.recipesService.addComponent(user.id, id, dto.baseRecipeId);
  }

  @Delete(':id/components/:baseRecipeId')
  @HttpCode(HttpStatus.NO_CONTENT)
  removeComponent(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Param('baseRecipeId', ParseUUIDPipe) baseRecipeId: string,
  ): Promise<void> {
    return this.recipesService.removeComponent(user.id, id, baseRecipeId);
  }

  // --- rangement & étiquetage -------------------------------------------

  @Post(':id/categories')
  @HttpCode(HttpStatus.NO_CONTENT)
  assignCategory(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: AssignRecipeCategoryDto,
  ): Promise<void> {
    return this.recipesService.assignCategory(user.id, id, dto.categoryId);
  }

  @Delete(':id/categories/:categoryId')
  @HttpCode(HttpStatus.NO_CONTENT)
  unassignCategory(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Param('categoryId', ParseUUIDPipe) categoryId: string,
  ): Promise<void> {
    return this.recipesService.unassignCategory(user.id, id, categoryId);
  }

  @Post(':id/tags')
  @HttpCode(HttpStatus.NO_CONTENT)
  assignTag(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: AssignRecipeTagDto,
  ): Promise<void> {
    return this.recipesService.assignTag(user.id, id, dto.tagId);
  }

  @Delete(':id/tags/:tagId')
  @HttpCode(HttpStatus.NO_CONTENT)
  unassignTag(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Param('tagId', ParseUUIDPipe) tagId: string,
  ): Promise<void> {
    return this.recipesService.unassignTag(user.id, id, tagId);
  }
}
