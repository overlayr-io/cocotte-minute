import { Injectable } from '@nestjs/common';

import { PremiumLimitException } from '../../common/errors/premium-limit.exception';
import { PremiumService } from '../billing/premium.service';
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
    private readonly premiumService: PremiumService,
  ) {}

  /** Limite du plan gratuit : critères cumulés max, tous types confondus. */
  private static readonly FREE_CRITERIA_LIMIT = 6;

  async searchRecipes(
    userId: string,
    dto: SearchRecipesDto,
  ): Promise<RecipeSummaryDto[]> {
    // Garde freemium : total de critères cumulés (texte + dossiers + tags +
    // personnes) plafonné en gratuit. Comptage AVANT le check premium pour ne
    // payer la lecture DB que dans le cas rare où le plafond est dépassé.
    const criteriaCount =
      (dto.q?.trim() ? 1 : 0) +
      (dto.categoryIds?.length ?? 0) +
      (dto.tagIds?.length ?? 0) +
      (dto.personIds?.length ?? 0);
    if (
      criteriaCount > SearchService.FREE_CRITERIA_LIMIT &&
      !(await this.premiumService.isPremium(userId))
    ) {
      throw new PremiumLimitException(
        'PREMIUM_LIMIT_SEARCH_CRITERIA',
        SearchService.FREE_CRITERIA_LIMIT,
        criteriaCount,
        `Limite gratuite atteinte : ${SearchService.FREE_CRITERIA_LIMIT} critères de recherche maximum. Passe en Pro pour combiner sans limite.`,
      );
    }
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
