import { ConflictException, NotFoundException } from '@nestjs/common';

import { DrizzleDB } from '../../db/drizzle.provider';
import { TagsService } from './tags.service';

/**
 * Faux Drizzle : chaque appel `db.select/insert/update/delete()` renvoie un
 * builder chaînable *thenable* qui résout la prochaine valeur de la file
 * `results`, dans l'ordre où les requêtes sont émises. Suffisant pour tester la
 * logique métier (branches ownership / unicité) sans base réelle.
 */
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
const row = (over: Partial<Record<string, unknown>> = {}) => ({
  id: 'tag-1',
  ownerId: USER,
  name: 'Végétarien',
  color: '#3F7D3A',
  deletedAt: null,
  createdAt: new Date('2026-01-01T00:00:00.000Z'),
  updatedAt: new Date('2026-01-01T00:00:00.000Z'),
  ...over,
});

describe('TagsService', () => {
  describe('listMine', () => {
    it('mappe les lignes en DTO avec recipeCount = 0', async () => {
      const { db } = makeDb([[row()]]);
      const service = new TagsService(db);

      const result = await service.listMine(USER);

      expect(result).toEqual([
        {
          id: 'tag-1',
          name: 'Végétarien',
          color: '#3F7D3A',
          recipeCount: 0,
          createdAt: '2026-01-01T00:00:00.000Z',
        },
      ]);
    });
  });

  describe('create', () => {
    it('insère quand le nom est libre', async () => {
      // 1) vérif unicité → aucun tag existant, 2) insert → ligne créée
      const { db, calls } = makeDb([[], [row({ name: 'Épicé', color: '#B14A3F' })]]);
      const service = new TagsService(db);

      const result = await service.create(USER, { name: 'Épicé', color: '#B14A3F' });

      expect(result.name).toBe('Épicé');
      expect(result.recipeCount).toBe(0);
      expect(calls.map((c) => c.op)).toEqual(['select', 'insert']);
    });

    it('refuse un nom déjà utilisé (409) sans insérer', async () => {
      const { db, calls } = makeDb([[{ id: 'other' }]]);
      const service = new TagsService(db);

      await expect(service.create(USER, { name: 'Végétarien', color: '#3F7D3A' })).rejects.toBeInstanceOf(
        ConflictException,
      );
      expect(calls.map((c) => c.op)).toEqual(['select']); // pas d'insert
    });
  });

  describe('update', () => {
    it('lève NotFound si le tag n’existe pas', async () => {
      const { db } = makeDb([[]]); // findOwnedOrFail → rien
      const service = new TagsService(db);

      await expect(service.update(USER, 'tag-x', { name: 'X' })).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });

    it('lève NotFound si le tag appartient à un autre compte', async () => {
      const { db } = makeDb([[row({ ownerId: 'someone-else' })]]);
      const service = new TagsService(db);

      await expect(service.update(USER, 'tag-1', { color: '#3D6DA8' })).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });
  });

  describe('softDelete', () => {
    it('lève NotFound si le tag appartient à un autre compte', async () => {
      const { db } = makeDb([[row({ ownerId: 'someone-else' })]]);
      const service = new TagsService(db);

      await expect(service.softDelete(USER, 'tag-1')).rejects.toBeInstanceOf(NotFoundException);
    });

    it('marque supprimé quand le tag est possédé', async () => {
      const { db, calls } = makeDb([[row()], undefined]);
      const service = new TagsService(db);

      await service.softDelete(USER, 'tag-1');

      expect(calls.map((c) => c.op)).toEqual(['select', 'update']);
    });
  });
});
