import { Injectable } from '@nestjs/common';

import { CategoriesService } from '../categories/categories.service';
import { PeopleService } from '../people/people.service';
import {
  RecipesService,
  type RecipeDiscoveryDto,
} from '../recipes/recipes.service';

/** Personne allégée pour composer une rangée « Pour {prénom} » côté client. */
export interface DiscoveryPersonDto {
  id: string;
  firstName: string;
  avatarUrl: string | null;
  /** Tags de la personne : une recette lui « correspond » si elle en porte un. */
  tagIds: string[];
}

/** Dossier allégé pour la rangée « Par dossier » (roots = depth 1). */
export interface DiscoveryCategoryDto {
  id: string;
  name: string;
  parentCategoryId: string | null;
  depth: number;
}

/**
 * Charge utile de la vue Découverte (Accueil). Le client compose toutes les
 * rangées à partir de ces données, sans requête par section.
 */
export interface DiscoveryHomeDto {
  /** Mois courant (1..12), pour le titre « De saison en {mois} ». */
  month: number;
  recipes: RecipeDiscoveryDto[];
  people: DiscoveryPersonDto[];
  categories: DiscoveryCategoryDto[];
}

/**
 * Orchestration de la vue Découverte. Domaine transverse (recettes × personnes ×
 * dossiers), isolé dans son module comme SearchService : il assemble les charges
 * utiles des services propriétaires, sans jamais toucher un schéma Drizzle.
 */
@Injectable()
export class DiscoveryService {
  constructor(
    private readonly recipesService: RecipesService,
    private readonly peopleService: PeopleService,
    private readonly categoriesService: CategoriesService,
  ) {}

  async getHome(userId: string): Promise<DiscoveryHomeDto> {
    const month = new Date().getMonth() + 1;

    const [recipes, people, categories] = await Promise.all([
      this.recipesService.listMineForDiscovery(userId, month),
      this.peopleService.listMine(userId),
      this.categoriesService.listMine(userId),
    ]);

    return {
      month,
      recipes,
      people: people.map((p) => ({
        id: p.id,
        firstName: p.firstName,
        avatarUrl: p.avatarUrl,
        tagIds: p.tags.map((t) => t.id),
      })),
      categories: categories.map((c) => ({
        id: c.id,
        name: c.name,
        parentCategoryId: c.parentCategoryId,
        depth: c.depth,
      })),
    };
  }
}
