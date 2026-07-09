import { NotFoundException } from '@nestjs/common';

import { DrizzleDB } from '../../db/drizzle.provider';
import { RecipesService } from '../recipes/recipes.service';
import { TagDto, TagsService } from '../tags/tags.service';
import { PeopleService } from './people.service';

/** Faux Drizzle chaînable/thenable (cf. tags.service.spec). */
function makeDb(results: unknown[]): { db: DrizzleDB; calls: { op: string }[] } {
  let i = 0;
  const calls: { op: string }[] = [];
  const builder = (payload: unknown) => {
    const b: Record<string, unknown> = {};
    for (const m of [
      'from',
      'where',
      'orderBy',
      'values',
      'set',
      'returning',
      'onConflictDoNothing',
    ]) {
      b[m] = () => b;
    }
    b.then = (res: (v: unknown) => unknown, rej: (e: unknown) => unknown) =>
      Promise.resolve(payload).then(res, rej);
    return b;
  };
  const op = (name: string) => () => {
    calls.push({ op: name });
    return builder(results[i++]);
  };
  const db = {
    select: op('select'),
    insert: op('insert'),
    update: op('update'),
    delete: op('delete'),
  } as unknown as DrizzleDB;
  return { db, calls };
}

const USER = 'user-1';
const personRow = (over: Partial<Record<string, unknown>> = {}) => ({
  id: 'person-1',
  ownerId: USER,
  firstName: 'Emma',
  lastName: 'Martin',
  avatarUrl: null,
  deletedAt: null,
  createdAt: new Date('2026-01-01T00:00:00.000Z'),
  updatedAt: new Date('2026-01-01T00:00:00.000Z'),
  ...over,
});

const tag = (id: string, name: string): TagDto => ({
  id,
  name,
  color: '#3F7D3A',
  isSystem: false,
  importedFromId: null,
  recipeCount: 0,
  createdAt: '2026-01-01T00:00:00.000Z',
});

function fakeTagsService(byIds: TagDto[]): TagsService {
  return {
    listByIds: jest.fn().mockResolvedValue(byIds),
  } as unknown as TagsService;
}

function fakeRecipesService(): RecipesService {
  return {
    listByIds: jest.fn().mockResolvedValue([]),
    assertOwnedRecipe: jest.fn().mockResolvedValue(undefined),
  } as unknown as RecipesService;
}

describe('PeopleService', () => {
  describe('listMine', () => {
    it('assemble chaque personne avec ses tags associés (sans N+1)', async () => {
      // 1) select people, 2) select person_tags, 3) select person_recipes
      const { db, calls } = makeDb([
        [personRow()],
        [{ personId: 'person-1', tagId: 'tag-a' }],
        [{ personId: 'person-1', recipeId: 'recipe-1' }],
      ]);
      const tags = fakeTagsService([tag('tag-a', 'Végétarien')]);
      const service = new PeopleService(db, tags, fakeRecipesService());

      const result = await service.listMine(USER);

      expect(result).toHaveLength(1);
      expect(result[0].firstName).toBe('Emma');
      expect(result[0].tags.map((t) => t.name)).toEqual(['Végétarien']);
      // people + person_tags + person_recipes = 3 requêtes, hydratation groupée.
      expect(calls.map((c) => c.op)).toEqual(['select', 'select', 'select']);
      expect(result[0].recipeIds).toEqual(['recipe-1']);
      expect(tags.listByIds).toHaveBeenCalledWith(USER, ['tag-a']);
    });

    it('retourne une liste vide sans toucher les tags si aucune personne', async () => {
      const { db } = makeDb([[]]);
      const tags = fakeTagsService([]);
      const service = new PeopleService(db, tags, fakeRecipesService());

      expect(await service.listMine(USER)).toEqual([]);
      expect(tags.listByIds).not.toHaveBeenCalled();
    });
  });

  describe('addTag', () => {
    it('lève NotFound si la personne appartient à un autre compte', async () => {
      const { db } = makeDb([[personRow({ ownerId: 'other' })]]);
      const service = new PeopleService(db, fakeTagsService([]), fakeRecipesService());

      await expect(service.addTag(USER, 'person-1', 'tag-a')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });

    it('lève NotFound si le tag n’appartient pas à l’utilisateur', async () => {
      // findOwnedOrFail → personne OK ; puis assertTagOwned → listByIds vide
      const { db } = makeDb([[personRow()]]);
      const tags = fakeTagsService([]); // aucun tag possédé
      const service = new PeopleService(db, tags, fakeRecipesService());

      await expect(service.addTag(USER, 'person-1', 'tag-x')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });

    it('associe le tag et retourne la personne hydratée', async () => {
      // 1) findOwnedOrFail select, 2) insert pivot, 3+4) hydrate (tags + recettes)
      const { db, calls } = makeDb([
        [personRow()],
        undefined,
        [{ tagId: 'tag-a' }],
        [],
      ]);
      const tags = fakeTagsService([tag('tag-a', 'Végétarien')]);
      const service = new PeopleService(db, tags, fakeRecipesService());

      const result = await service.addTag(USER, 'person-1', 'tag-a');

      expect(result.tags.map((t) => t.id)).toEqual(['tag-a']);
      expect(calls.map((c) => c.op)).toEqual(['select', 'insert', 'select', 'select']);
    });
  });

  describe('softDelete', () => {
    it('lève NotFound si la personne n’existe pas', async () => {
      const { db } = makeDb([[]]);
      const service = new PeopleService(db, fakeTagsService([]), fakeRecipesService());

      await expect(service.softDelete(USER, 'nope')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });
  });
});
