import { CategoriesService } from '../categories/categories.service';
import { PeopleService } from '../people/people.service';
import { RecipesService, type RecipeSummaryDto } from '../recipes/recipes.service';
import { SearchService } from './search.service';

const USER = 'user-1';

const summary = (id: string): RecipeSummaryDto => ({
  id,
  name: `Recette ${id}`,
  photoUrl: null,
  isBase: false,
  prepTime: 0,
  cookTime: 0,
  restTime: 0,
  servings: 1,
  createdAt: '2026-01-01T00:00:00.000Z',
});

function make() {
  const recipes = { search: jest.fn() } as unknown as jest.Mocked<
    Pick<RecipesService, 'search'>
  >;
  const categories = { expandWithDescendants: jest.fn() } as unknown as jest.Mocked<
    Pick<CategoriesService, 'expandWithDescendants'>
  >;
  const people = { tagIdsForPeople: jest.fn() } as unknown as jest.Mocked<
    Pick<PeopleService, 'tagIdsForPeople'>
  >;
  const service = new SearchService(
    recipes as unknown as RecipesService,
    categories as unknown as CategoriesService,
    people as unknown as PeopleService,
  );
  return { service, recipes, categories, people };
}

describe('SearchService', () => {
  it('délègue directement une recherche texte seule (aucun critère transverse résolu)', async () => {
    const { service, recipes, categories, people } = make();
    recipes.search.mockResolvedValue([summary('a')]);

    const res = await service.searchRecipes(USER, { q: 'poulet' });

    expect(res).toEqual([summary('a')]);
    expect(categories.expandWithDescendants).not.toHaveBeenCalled();
    expect(people.tagIdsForPeople).not.toHaveBeenCalled();
    expect(recipes.search).toHaveBeenCalledWith(USER, {
      q: 'poulet',
      categoryIds: undefined,
      allTagIds: undefined,
      anyTagIds: undefined,
    });
  });

  it('déplie les dossiers en descendants avant la requête', async () => {
    const { service, recipes, categories } = make();
    categories.expandWithDescendants.mockResolvedValue(['c1', 'c1a', 'c1b']);
    recipes.search.mockResolvedValue([]);

    await service.searchRecipes(USER, { categoryIds: ['c1'] });

    expect(categories.expandWithDescendants).toHaveBeenCalledWith(USER, ['c1']);
    expect(recipes.search).toHaveBeenCalledWith(
      USER,
      expect.objectContaining({ categoryIds: ['c1', 'c1a', 'c1b'] }),
    );
  });

  it('traduit les personnes en union de leurs tags (anyTagIds, logique OU)', async () => {
    const { service, recipes, people } = make();
    people.tagIdsForPeople.mockResolvedValue(['t1', 't2']);
    recipes.search.mockResolvedValue([summary('x')]);

    await service.searchRecipes(USER, { personIds: ['p1', 'p2'] });

    expect(people.tagIdsForPeople).toHaveBeenCalledWith(USER, ['p1', 'p2']);
    expect(recipes.search).toHaveBeenCalledWith(
      USER,
      expect.objectContaining({ anyTagIds: ['t1', 't2'] }),
    );
  });

  it('court-circuite en résultat vide si une personne sélectionnée n’a aucun tag', async () => {
    const { service, recipes, people } = make();
    people.tagIdsForPeople.mockResolvedValue([]);

    const res = await service.searchRecipes(USER, { personIds: ['p1'] });

    expect(res).toEqual([]);
    expect(recipes.search).not.toHaveBeenCalled();
  });

  it('passe les tags explicites en allTagIds (logique ET)', async () => {
    const { service, recipes } = make();
    recipes.search.mockResolvedValue([]);

    await service.searchRecipes(USER, { tagIds: ['t1', 't2'] });

    expect(recipes.search).toHaveBeenCalledWith(
      USER,
      expect.objectContaining({ allTagIds: ['t1', 't2'] }),
    );
  });
});
