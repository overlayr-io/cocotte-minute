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
  Put,
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
  CreateRecipeStepDto,
  ImportRecipeStepsDto,
  ReorderRecipeStepsDto,
  SetStepIngredientsDto,
  UpdateRecipeIngredientQuantityDto,
  UpdateRecipeStepDto,
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
    return this.recipesService.addIngredient(
      user.id,
      id,
      dto.ingredientId,
      dto.quantity,
    );
  }

  @Patch(':id/ingredients/:ingredientId')
  @HttpCode(HttpStatus.NO_CONTENT)
  updateIngredientQuantity(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Param('ingredientId', ParseUUIDPipe) ingredientId: string,
    @Body() dto: UpdateRecipeIngredientQuantityDto,
  ): Promise<void> {
    return this.recipesService.updateIngredientQuantity(
      user.id,
      id,
      ingredientId,
      dto.quantity,
    );
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

  // --- étapes ------------------------------------------------------------

  @Post(':id/steps')
  @HttpCode(HttpStatus.NO_CONTENT)
  addStep(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: CreateRecipeStepDto,
  ): Promise<void> {
    return this.recipesService.addStep(user.id, id, dto);
  }

  @Post(':id/steps/import')
  @HttpCode(HttpStatus.NO_CONTENT)
  importSteps(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ImportRecipeStepsDto,
  ): Promise<void> {
    return this.recipesService.importSteps(user.id, id, dto.descriptions);
  }

  @Put(':id/steps/order')
  @HttpCode(HttpStatus.NO_CONTENT)
  reorderSteps(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ReorderRecipeStepsDto,
  ): Promise<void> {
    return this.recipesService.reorderSteps(user.id, id, dto.stepIds);
  }

  @Patch(':id/steps/:stepId')
  @HttpCode(HttpStatus.NO_CONTENT)
  updateStep(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Param('stepId', ParseUUIDPipe) stepId: string,
    @Body() dto: UpdateRecipeStepDto,
  ): Promise<void> {
    return this.recipesService.updateStep(user.id, id, stepId, dto);
  }

  @Delete(':id/steps/:stepId')
  @HttpCode(HttpStatus.NO_CONTENT)
  removeStep(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Param('stepId', ParseUUIDPipe) stepId: string,
  ): Promise<void> {
    return this.recipesService.removeStep(user.id, id, stepId);
  }

  @Put(':id/steps/:stepId/ingredients')
  @HttpCode(HttpStatus.NO_CONTENT)
  setStepIngredients(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Param('stepId', ParseUUIDPipe) stepId: string,
    @Body() dto: SetStepIngredientsDto,
  ): Promise<void> {
    return this.recipesService.setStepIngredients(user.id, id, stepId, dto.ingredientIds);
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
