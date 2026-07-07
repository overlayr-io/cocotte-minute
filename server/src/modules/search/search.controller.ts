import { Controller, Get, Query, UseGuards } from '@nestjs/common';

import { AuthenticatedUser } from '../../common/auth/authenticated-user';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { SupabaseAuthGuard } from '../../common/guards/supabase-auth.guard';
import { type RecipeSummaryDto } from '../recipes/recipes.service';
import { SearchRecipesDto } from './dto/search-recipes.dto';
import { SearchService } from './search.service';

@Controller('search')
@UseGuards(SupabaseAuthGuard)
export class SearchController {
  constructor(private readonly searchService: SearchService) {}

  /** Recherche avancée de mes recettes (dossiers + tags + personnes + texte). */
  @Get('recipes')
  searchRecipes(
    @CurrentUser() user: AuthenticatedUser,
    @Query() dto: SearchRecipesDto,
  ): Promise<RecipeSummaryDto[]> {
    return this.searchService.searchRecipes(user.id, dto);
  }
}
