import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';

import { DrizzleDB } from '../../db/drizzle.provider';
import { CategoriesService } from './categories.service';

/** Faux Drizzle chaînable/thenable (cf. people.service.spec). */
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
      'limit',
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
  const db: Record<string, unknown> = {
    select: op('select'),
    insert: op('insert'),
    update: op('update'),
    delete: op('delete'),
    // `execute` ne sert qu'aux verrous consultatifs : il ne consomme PAS la file
    // de résultats, sinon toutes les attentes des tests seraient décalées.
    execute: () => {
      calls.push({ op: 'execute' });
      return builder(undefined);
    },
  };
  // Transaction transparente : le `tx` passé au callback est le mock lui-même.
  db.transaction = async (fn: (tx: unknown) => Promise<unknown>) => fn(db);
  return { db: db as unknown as DrizzleDB, calls };
}

const USER = 'user-1';
const catRow = (over: Partial<Record<string, unknown>> = {}) => ({
  id: 'cat-1',
  ownerId: USER,
  name: 'Plat',
  icon: '🍽️',
  parentCategoryId: null,
  depth: 1,
  isDefault: false,
  deletedAt: null,
  createdAt: new Date('2026-01-01T00:00:00.000Z'),
  updatedAt: new Date('2026-01-01T00:00:00.000Z'),
  ...over,
});

const recipesStub = {
  countByCategoryIds: async () => new Map<string, number>(),
  countByTagIds: async () => new Map<string, number>(),
} as unknown as import('../recipes/recipes.service').RecipesService;

describe('CategoriesService', () => {
  describe('listMine', () => {
    it('sème les dossiers par défaut au premier accès (compte vierge)', async () => {
      // ensureDefaults: verrou consultatif → select existant (vide) → insert
      // seed ; puis select liste. Le `execute` en tête est le verrou : il DOIT
      // précéder le select, sinon deux requêtes concurrentes sèment chacune.
      const { db, calls } = makeDb([[], undefined, [catRow({ isDefault: true })]]);
      const service = new CategoriesService(db, recipesStub);

      const result = await service.listMine(USER);

      expect(calls.map((c) => c.op)).toEqual([
        'execute',
        'select',
        'insert',
        'select',
      ]);
      expect(result).toHaveLength(1);
    });

    it('ne sème pas si au moins une catégorie existe déjà', async () => {
      const { db, calls } = makeDb([[{ id: 'cat-1' }], [catRow()]]);
      const service = new CategoriesService(db, recipesStub);

      await service.listMine(USER);

      expect(calls.map((c) => c.op)).toEqual(['execute', 'select', 'select']);
    });
  });

  describe('create', () => {
    it('crée un dossier racine à la profondeur 1', async () => {
      // pas de parent → assertNameAvailable select (libre) → insert returning
      const { db } = makeDb([[], [catRow({ depth: 1 })]]);
      const service = new CategoriesService(db, recipesStub);

      const result = await service.create(USER, { name: 'Fêtes' });

      expect(result.depth).toBe(1);
    });

    it('hérite de la profondeur du parent + 1', async () => {
      // findOwnedOrFail parent(depth 2) → assertNameAvailable libre → insert
      const { db } = makeDb([
        [catRow({ id: 'parent', depth: 2 })],
        [],
        [catRow({ id: 'child', depth: 3, parentCategoryId: 'parent' })],
      ]);
      const service = new CategoriesService(db, recipesStub);

      const result = await service.create(USER, {
        name: 'Italiennes',
        parentCategoryId: 'parent',
      });

      expect(result.depth).toBe(3);
    });

    it('refuse de dépasser la profondeur maximale (5)', async () => {
      const { db } = makeDb([[catRow({ id: 'parent', depth: 5 })]]);
      const service = new CategoriesService(db, recipesStub);

      await expect(
        service.create(USER, { name: 'Trop profond', parentCategoryId: 'parent' }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('refuse un nom déjà porté par un frère', async () => {
      const { db } = makeDb([[{ id: 'cat-existing' }]]);
      const service = new CategoriesService(db, recipesStub);

      await expect(service.create(USER, { name: 'Plat' })).rejects.toBeInstanceOf(
        ConflictException,
      );
    });
  });

  describe('listRecipes', () => {
    it("délègue au service Recipes quand le dossier m'appartient", async () => {
      const { db } = makeDb([[catRow()]]); // findOwnedOrFail → trouvé
      const summaries = [{ id: 'r1' }];
      const recipes = {
        countByCategoryIds: async () => new Map<string, number>(),
        countByTagIds: async () => new Map<string, number>(),
        listByCategory: jest.fn(async () => summaries),
      } as unknown as import('../recipes/recipes.service').RecipesService;
      const service = new CategoriesService(db, recipes);

      const result = await service.listRecipes(USER, 'cat-1');

      expect(result).toBe(summaries);
      expect(recipes.listByCategory as jest.Mock).toHaveBeenCalledWith(
        USER,
        'cat-1',
      );
    });

    it("lève NotFound si le dossier ne m'appartient pas", async () => {
      const { db } = makeDb([[catRow({ ownerId: 'other' })]]);
      const service = new CategoriesService(db, recipesStub);

      await expect(service.listRecipes(USER, 'cat-1')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });
  });

  describe('update', () => {
    it('refuse de modifier un dossier par défaut', async () => {
      const { db } = makeDb([[catRow({ isDefault: true })]]);
      const service = new CategoriesService(db, recipesStub);

      await expect(
        service.update(USER, 'cat-1', { name: 'Autre' }),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });
  });

  describe('softDelete', () => {
    it('refuse de supprimer un dossier par défaut', async () => {
      const { db } = makeDb([[catRow({ isDefault: true })]]);
      const service = new CategoriesService(db, recipesStub);

      await expect(service.softDelete(USER, 'cat-1')).rejects.toBeInstanceOf(
        ForbiddenException,
      );
    });

    it('bloque la suppression si le dossier contient des sous-dossiers', async () => {
      // findOwnedOrFail → hasChildren select renvoie un enfant
      const { db } = makeDb([[catRow()], [{ id: 'child' }]]);
      const service = new CategoriesService(db, recipesStub);

      await expect(service.softDelete(USER, 'cat-1')).rejects.toBeInstanceOf(
        ConflictException,
      );
    });

    it('supprime (soft) un dossier vide non par défaut', async () => {
      const { db, calls } = makeDb([[catRow()], [], undefined]);
      const service = new CategoriesService(db, recipesStub);

      await service.softDelete(USER, 'cat-1');

      expect(calls.map((c) => c.op)).toEqual(['select', 'select', 'update']);
    });

    it('lève NotFound si le dossier appartient à un autre compte', async () => {
      const { db } = makeDb([[catRow({ ownerId: 'other' })]]);
      const service = new CategoriesService(db, recipesStub);

      await expect(service.softDelete(USER, 'cat-1')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });
  });
});
