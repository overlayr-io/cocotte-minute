import { PremiumLimitException } from '../../common/errors/premium-limit.exception';
import { PremiumService } from '../billing/premium.service';
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
  const people = {
    tagIdsForPeople: jest.fn(),
    recipeIdsForPeople: jest.fn(),
    allAssociatedRecipeIds: jest.fn(),
  } as unknown as jest.Mocked<
    Pick<
      PeopleService,
      'tagIdsForPeople' | 'recipeIdsForPeople' | 'allAssociatedRecipeIds'
    >
  >;
  const premium = { isPremium: jest.fn().mockResolvedValue(false) } as unknown as jest.Mocked<
    Pick<PremiumService, 'isPremium'>
  >;
  const service = new SearchService(
    recipes as unknown as RecipesService,
    categories as unknown as CategoriesService,
    people as unknown as PeopleService,
    premium as unknown as PremiumService,
  );
  return { service, recipes, categories, people, premium };
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
      person: undefined,
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

  it('traduit les personnes en filtre résolu (recettes directes + tags + associées)', async () => {
    const { service, recipes, people } = make();
    people.tagIdsForPeople.mockResolvedValue(['t1', 't2']);
    people.recipeIdsForPeople.mockResolvedValue(['r1']);
    people.allAssociatedRecipeIds.mockResolvedValue(['r1', 'r9']);
    recipes.search.mockResolvedValue([summary('x')]);

    await service.searchRecipes(USER, { personIds: ['p1', 'p2'] });

    expect(people.tagIdsForPeople).toHaveBeenCalledWith(USER, ['p1', 'p2']);
    expect(people.recipeIdsForPeople).toHaveBeenCalledWith(USER, ['p1', 'p2']);
    expect(recipes.search).toHaveBeenCalledWith(
      USER,
      expect.objectContaining({
        person: {
          recipeIds: ['r1'],
          tagIds: ['t1', 't2'],
          associatedRecipeIds: ['r1', 'r9'],
        },
      }),
    );
  });

  it('interroge quand même les recettes si la personne n’a ni tag ni recette (orphelines incluses)', async () => {
    const { service, recipes, people } = make();
    people.tagIdsForPeople.mockResolvedValue([]);
    people.recipeIdsForPeople.mockResolvedValue([]);
    people.allAssociatedRecipeIds.mockResolvedValue([]);
    recipes.search.mockResolvedValue([]);

    await service.searchRecipes(USER, { personIds: ['p1'] });

    expect(recipes.search).toHaveBeenCalledWith(
      USER,
      expect.objectContaining({
        person: { recipeIds: [], tagIds: [], associatedRecipeIds: [] },
      }),
    );
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

  describe('plafond freemium de critères cumulés (6)', () => {
    it('refuse 7 critères cumulés en gratuit (403 PREMIUM_LIMIT_SEARCH_CRITERIA)', async () => {
      const { service, recipes } = make();

      // 1 texte + 2 dossiers + 2 tags + 2 personnes = 7 critères.
      await expect(
        service.searchRecipes(USER, {
          q: 'poulet',
          categoryIds: ['c1', 'c2'],
          tagIds: ['t1', 't2'],
          personIds: ['p1', 'p2'],
        }),
      ).rejects.toThrow(PremiumLimitException);
      expect(recipes.search).not.toHaveBeenCalled();
    });

    it('expose code/limit/current dans la réponse structurée', async () => {
      const { service } = make();

      const err = await service
        .searchRecipes(USER, {
          q: 'poulet',
          categoryIds: ['c1', 'c2'],
          tagIds: ['t1', 't2'],
          personIds: ['p1', 'p2'],
        })
        .catch((e: PremiumLimitException) => e);

      expect((err as PremiumLimitException).getResponse()).toMatchObject({
        code: 'PREMIUM_LIMIT_SEARCH_CRITERIA',
        limit: 6,
        current: 7,
      });
    });

    it('accepte exactement 6 critères en gratuit (limite inclusive)', async () => {
      const { service, recipes, premium } = make();
      recipes.search.mockResolvedValue([]);

      // 2 personnes + 3 tags + 1 texte = 6 (exemple du doc limite-freemium).
      await service.searchRecipes(USER, {
        q: 'poulet',
        tagIds: ['t1', 't2', 't3'],
        personIds: ['p1', 'p2'],
      });

      expect(recipes.search).toHaveBeenCalled();
      // Sous le plafond : aucune lecture du statut premium (économie DB).
      expect(premium.isPremium).not.toHaveBeenCalled();
    });

    it('laisse passer au-delà de 6 critères en premium', async () => {
      const { service, recipes, premium } = make();
      premium.isPremium.mockResolvedValue(true);
      recipes.search.mockResolvedValue([]);

      await service.searchRecipes(USER, {
        q: 'poulet',
        categoryIds: ['c1', 'c2'],
        tagIds: ['t1', 't2'],
        personIds: ['p1', 'p2'],
      });

      expect(premium.isPremium).toHaveBeenCalledWith(USER);
      expect(recipes.search).toHaveBeenCalled();
    });
  });
});
