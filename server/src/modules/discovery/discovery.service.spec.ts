import { DiscoveryService } from './discovery.service';

describe('DiscoveryService', () => {
  const recipesService = { listMineForDiscovery: jest.fn() };
  const peopleService = { listMine: jest.fn() };
  const categoriesService = { listMine: jest.fn() };

  const service = new DiscoveryService(
    recipesService as never,
    peopleService as never,
    categoriesService as never,
  );

  beforeEach(() => jest.clearAllMocks());

  it('assembles recipes, mapped people and categories with the current month', async () => {
    recipesService.listMineForDiscovery.mockResolvedValue([
      { id: 'r1', name: 'Soupe', seasonal: true, tagIds: ['t1'], categoryIds: [] },
    ]);
    peopleService.listMine.mockResolvedValue([
      {
        id: 'p1',
        firstName: 'Emma',
        lastName: null,
        avatarUrl: 'a.png',
        tags: [{ id: 't1' }, { id: 't2' }],
        createdAt: '',
      },
    ]);
    categoriesService.listMine.mockResolvedValue([
      { id: 'c1', name: 'Plats', parentCategoryId: null, depth: 1 },
      { id: 'c2', name: 'Pâtes', parentCategoryId: 'c1', depth: 2 },
    ]);

    const result = await service.getHome('user-1');

    expect(result.month).toBeGreaterThanOrEqual(1);
    expect(result.month).toBeLessThanOrEqual(12);
    expect(recipesService.listMineForDiscovery).toHaveBeenCalledWith(
      'user-1',
      result.month,
    );
    expect(result.recipes).toHaveLength(1);
    // Personnes réduites à ce dont le client a besoin (tags → ids).
    expect(result.people).toEqual([
      { id: 'p1', firstName: 'Emma', avatarUrl: 'a.png', tagIds: ['t1', 't2'] },
    ]);
    expect(result.categories).toEqual([
      { id: 'c1', name: 'Plats', parentCategoryId: null, depth: 1 },
      { id: 'c2', name: 'Pâtes', parentCategoryId: 'c1', depth: 2 },
    ]);
  });
});
