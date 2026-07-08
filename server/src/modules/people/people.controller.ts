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
import type { RecipeSummaryDto } from '../recipes/recipes.service';
import { AddPersonRecipeDto } from './dto/add-person-recipe.dto';
import { AddPersonTagDto } from './dto/add-person-tag.dto';
import { CreatePersonDto } from './dto/create-person.dto';
import { UpdatePersonDto } from './dto/update-person.dto';
import { PeopleService, PersonDto } from './people.service';

@Controller('people')
@UseGuards(SupabaseAuthGuard)
export class PeopleController {
  constructor(private readonly peopleService: PeopleService) {}

  /** Mes personnes, tags associés inclus. */
  @Get()
  listMine(@CurrentUser() user: AuthenticatedUser): Promise<PersonDto[]> {
    return this.peopleService.listMine(user.id);
  }

  @Post()
  create(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreatePersonDto,
  ): Promise<PersonDto> {
    return this.peopleService.create(user.id, dto);
  }

  @Patch(':id')
  update(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdatePersonDto,
  ): Promise<PersonDto> {
    return this.peopleService.update(user.id, id, dto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  remove(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<void> {
    return this.peopleService.softDelete(user.id, id);
  }

  /** Associe un tag à la personne. Retourne la personne à jour. */
  @Post(':id/tags')
  addTag(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: AddPersonTagDto,
  ): Promise<PersonDto> {
    return this.peopleService.addTag(user.id, id, dto.tagId);
  }

  /** Retire l'association d'un tag. Retourne la personne à jour. */
  @Delete(':id/tags/:tagId')
  removeTag(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Param('tagId', ParseUUIDPipe) tagId: string,
  ): Promise<PersonDto> {
    return this.peopleService.removeTag(user.id, id, tagId);
  }

  /** « Ses recettes » : recettes associées directement à la personne. */
  @Get(':id/recipes')
  listRecipes(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<RecipeSummaryDto[]> {
    return this.peopleService.listRecipes(user.id, id);
  }

  /** Associe une recette à la personne. Retourne la personne à jour. */
  @Post(':id/recipes')
  addRecipe(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: AddPersonRecipeDto,
  ): Promise<PersonDto> {
    return this.peopleService.addRecipe(user.id, id, dto.recipeId);
  }

  /** Retire l'association d'une recette. Retourne la personne à jour. */
  @Delete(':id/recipes/:recipeId')
  removeRecipe(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Param('recipeId', ParseUUIDPipe) recipeId: string,
  ): Promise<PersonDto> {
    return this.peopleService.removeRecipe(user.id, id, recipeId);
  }
}
