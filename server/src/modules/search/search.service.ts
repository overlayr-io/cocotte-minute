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
 * - personnes → traduites en l'union de leurs tags (PeopleService) ;
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

    let anyTagIds: string[] | undefined;
    if (dto.personIds && dto.personIds.length > 0) {
      anyTagIds = await this.peopleService.tagIdsForPeople(userId, dto.personIds);
      // Personnes sélectionnées mais sans aucun tag : aucune recette ne peut être
      // « compatible » → résultat vide sans interroger les recettes.
      if (anyTagIds.length === 0) return [];
    }

    return this.recipesService.search(userId, {
      q: dto.q,
      categoryIds,
      allTagIds: dto.tagIds,
      anyTagIds,
    });
  }
}
