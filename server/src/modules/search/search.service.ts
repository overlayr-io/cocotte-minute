import { Injectable } from '@nestjs/common';

import { CategoriesService } from '../categories/categories.service';
import { PeopleService } from '../people/people.service';
import {
  RecipesService,
  type RecipeSummaryDto,
} from '../recipes/recipes.service';
import { SearchRecipesDto } from './dto/search-recipes.dto';

/**
 * Orchestration de la recherche avancée. Domaine transverse par nature (recettes
 * × dossiers × personnes × tags), isolé dans son propre module : il ne fait que
 * traduire les critères d'API en critères résolus, puis délègue la requête aux
 * services propriétaires. Il n'accède jamais à un schéma Drizzle directement.
 *
 * Résolution des critères transverses avant délégation à RecipesService :
 * - dossiers → dépliés en incluant leurs descendants (CategoriesService) ;
 * - personnes → associations directes + union de leurs tags + recettes sans
 *   aucune association (PeopleService) ;
 * - tags explicites → passés tels quels (logique ET) ;
 * - texte → passé tel quel (LIKE nom).
 */
@Injectable()
export class SearchService {
  constructor(
    private readonly recipesService: RecipesService,
    private readonly categoriesService: CategoriesService,
    private readonly peopleService: PeopleService,
  ) {}

  async searchRecipes(
    userId: string,
    dto: SearchRecipesDto,
  ): Promise<RecipeSummaryDto[]> {
    const categoryIds =
      dto.categoryIds && dto.categoryIds.length > 0
        ? await this.categoriesService.expandWithDescendants(
            userId,
            dto.categoryIds,
          )
        : undefined;

    // Filtre personnes : une recette correspond si elle est associée directement
    // à une des personnes, OU porte un de leurs tags, OU n'est associée à rien
    // (ni tag, ni personne) — « vide = compté dedans ».
    let person:
      | { recipeIds: string[]; tagIds: string[]; associatedRecipeIds: string[] }
      | undefined;
    if (dto.personIds && dto.personIds.length > 0) {
      const [tagIds, recipeIds, associatedRecipeIds] = await Promise.all([
        this.peopleService.tagIdsForPeople(userId, dto.personIds),
        this.peopleService.recipeIdsForPeople(userId, dto.personIds),
        this.peopleService.allAssociatedRecipeIds(userId),
      ]);
      person = { recipeIds, tagIds, associatedRecipeIds };
    }

    return this.recipesService.search(userId, {
      q: dto.q,
      categoryIds,
      allTagIds: dto.tagIds,
      person,
    });
  }
}
