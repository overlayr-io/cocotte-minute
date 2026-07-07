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
  const db = {
    select: op('select'),
    insert: op('insert'),
    update: op('update'),
    delete: op('delete'),
  } as unknown as DrizzleDB;
  return { db, calls };
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

describe('CategoriesService', () => {
  describe('listMine', () => {
    it('sème les dossiers par défaut au premier accès (compte vierge)', async () => {
      // ensureDefaults: select existant (vide) → insert seed ; puis select liste
      const { db, calls } = makeDb([[], undefined, [catRow({ isDefault: true })]]);
      const service = new CategoriesService(db);

      const result = await service.listMine(USER);

      expect(calls.map((c) => c.op)).toEqual(['select', 'insert', 'select']);
      expect(result).toHaveLength(1);
    });

    it('ne sème pas si au moins une catégorie existe déjà', async () => {
      const { db, calls } = makeDb([[{ id: 'cat-1' }], [catRow()]]);
      const service = new CategoriesService(db);

      await service.listMine(USER);

      expect(calls.map((c) => c.op)).toEqual(['select', 'select']);
    });
  });

  describe('create', () => {
    it('crée un dossier racine à la profondeur 1', async () => {
      // pas de parent → assertNameAvailable select (libre) → insert returning
      const { db } = makeDb([[], [catRow({ depth: 1 })]]);
      const service = new CategoriesService(db);

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
      const service = new CategoriesService(db);

      const result = await service.create(USER, {
        name: 'Italiennes',
        parentCategoryId: 'parent',
      });

      expect(result.depth).toBe(3);
    });

    it('refuse de dépasser la profondeur maximale (5)', async () => {
      const { db } = makeDb([[catRow({ id: 'parent', depth: 5 })]]);
      const service = new CategoriesService(db);

      await expect(
        service.create(USER, { name: 'Trop profond', parentCategoryId: 'parent' }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('refuse un nom déjà porté par un frère', async () => {
      const { db } = makeDb([[{ id: 'cat-existing' }]]);
      const service = new CategoriesService(db);

      await expect(service.create(USER, { name: 'Plat' })).rejects.toBeInstanceOf(
        ConflictException,
      );
    });
  });

  describe('update', () => {
    it('refuse de modifier un dossier par défaut', async () => {
      const { db } = makeDb([[catRow({ isDefault: true })]]);
      const service = new CategoriesService(db);

      await expect(
        service.update(USER, 'cat-1', { name: 'Autre' }),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });
  });

  describe('softDelete', () => {
    it('refuse de supprimer un dossier par défaut', async () => {
      const { db } = makeDb([[catRow({ isDefault: true })]]);
      const service = new CategoriesService(db);

      await expect(service.softDelete(USER, 'cat-1')).rejects.toBeInstanceOf(
        ForbiddenException,
      );
    });

    it('bloque la suppression si le dossier contient des sous-dossiers', async () => {
      // findOwnedOrFail → hasChildren select renvoie un enfant
      const { db } = makeDb([[catRow()], [{ id: 'child' }]]);
      const service = new CategoriesService(db);

      await expect(service.softDelete(USER, 'cat-1')).rejects.toBeInstanceOf(
        ConflictException,
      );
    });

    it('supprime (soft) un dossier vide non par défaut', async () => {
      const { db, calls } = makeDb([[catRow()], [], undefined]);
      const service = new CategoriesService(db);

      await service.softDelete(USER, 'cat-1');

      expect(calls.map((c) => c.op)).toEqual(['select', 'select', 'update']);
    });

    it('lève NotFound si le dossier appartient à un autre compte', async () => {
      const { db } = makeDb([[catRow({ ownerId: 'other' })]]);
      const service = new CategoriesService(db);

      await expect(service.softDelete(USER, 'cat-1')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });
  });
});
