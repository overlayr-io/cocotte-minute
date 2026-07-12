import { NotFoundException } from '@nestjs/common';

import { PremiumLimitException } from '../../common/errors/premium-limit.exception';
import { SupabaseStorageService } from '../../common/supabase/supabase-storage.service';
import { DrizzleDB } from '../../db/drizzle.provider';
import { PremiumService } from '../billing/premium.service';
import { RecipeGalleryService } from './recipe-gallery.service';
import { RecipesService } from './recipes.service';

/** Faux Drizzle chaînable/thenable (cf. recipes.service.spec), + capture des ops. */
function makeDb(results: unknown[]): { db: DrizzleDB; calls: { op: string }[] } {
  let i = 0;
  const calls: { op: string }[] = [];
  const builder = (payload: unknown) => {
    const b: Record<string, unknown> = {};
    for (const m of ['from', 'where', 'orderBy', 'values', 'set', 'returning']) {
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
    delete: op('delete'),
  } as unknown as DrizzleDB;
  return { db, calls };
}

const USER = 'user-1';
const RECIPE = 'rec-1';

const photoRow = (over: Partial<Record<string, unknown>> = {}) => ({
  id: 'photo-1',
  imageUrl: 'https://x.supabase.co/storage/v1/object/public/images/recipe-gallery/u/1.jpg',
  createdAt: new Date('2026-01-01T00:00:00.000Z'),
  ...over,
});

/** Recettes : assertOwnedRecipe no-op ; setPhotoIfEmpty paramétrable. */
const recipesStub = (becameCover = false) =>
  ({
    assertOwnedRecipe: jest.fn().mockResolvedValue(undefined),
    setPhotoIfEmpty: jest.fn().mockResolvedValue(becameCover),
  }) as unknown as RecipesService;

const premiumStub = (isPremium = false) =>
  ({ isPremium: jest.fn().mockResolvedValue(isPremium) }) as unknown as PremiumService;

const storageStub = () =>
  ({ removeByPublicUrls: jest.fn().mockResolvedValue(undefined) }) as unknown as SupabaseStorageService;

describe('RecipeGalleryService', () => {
  describe('add — mécanisme couverture', () => {
    it('devient couverture (hors galerie) si la recette n’a pas de photo', async () => {
      // setPhotoIfEmpty → true ; puis listPhotos (select) → []
      const { db, calls } = makeDb([[]]);
      const service = new RecipeGalleryService(db, recipesStub(true), premiumStub(), storageStub());

      const res = await service.add(USER, RECIPE, 'https://cdn/x.jpg');

      expect(res.becameCover).toBe(true);
      expect(res.coverUrl).toBe('https://cdn/x.jpg');
      // Aucun INSERT galerie quand la photo devient la couverture.
      expect(calls.some((c) => c.op === 'insert')).toBe(false);
    });

    it('insère en galerie si une couverture existe déjà', async () => {
      // setPhotoIfEmpty → false ; assertQuota select(count) ; insert ; listPhotos
      const { db, calls } = makeDb([[{ n: 1 }], undefined, [photoRow()]]);
      const service = new RecipeGalleryService(db, recipesStub(false), premiumStub(), storageStub());

      const res = await service.add(USER, RECIPE, 'https://cdn/x.jpg');

      expect(res.becameCover).toBe(false);
      expect(calls.some((c) => c.op === 'insert')).toBe(true);
      expect(res.photos).toHaveLength(1);
    });
  });

  describe('add — quota', () => {
    it('bloque au-delà de 3 photos en gratuit', async () => {
      const { db } = makeDb([[{ n: 3 }]]); // assertQuota → déjà 3
      const service = new RecipeGalleryService(db, recipesStub(false), premiumStub(false), storageStub());

      await expect(service.add(USER, RECIPE, 'https://cdn/x.jpg')).rejects.toBeInstanceOf(
        PremiumLimitException,
      );
    });

    it('autorise jusqu’à 6 photos en Pro', async () => {
      // 3 photos existantes < 6 → insert autorisé
      const { db, calls } = makeDb([[{ n: 3 }], undefined, [photoRow()]]);
      const premium = premiumStub(true);
      const service = new RecipeGalleryService(db, recipesStub(false), premium, storageStub());

      await service.add(USER, RECIPE, 'https://cdn/x.jpg');

      expect(calls.some((c) => c.op === 'insert')).toBe(true);
      expect(premium.isPremium).toHaveBeenCalledWith(USER);
    });

    it('bloque au-delà de 6 photos même en Pro (plafond réel)', async () => {
      const { db } = makeDb([[{ n: 6 }]]);
      const service = new RecipeGalleryService(db, recipesStub(false), premiumStub(true), storageStub());

      await expect(service.add(USER, RECIPE, 'https://cdn/x.jpg')).rejects.toBeInstanceOf(
        PremiumLimitException,
      );
    });
  });

  describe('remove', () => {
    it('lève NotFound si la photo n’existe pas pour cette recette', async () => {
      const { db } = makeDb([[]]); // select → aucune ligne
      const service = new RecipeGalleryService(db, recipesStub(false), premiumStub(), storageStub());

      await expect(service.remove(USER, RECIPE, 'photo-x')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });

    it('supprime la ligne et le fichier Storage', async () => {
      // select(row) ; delete ; listPhotos → []
      const { db, calls } = makeDb([[photoRow()], undefined, []]);
      const storage = storageStub();
      const service = new RecipeGalleryService(db, recipesStub(false), premiumStub(), storage);

      const res = await service.remove(USER, RECIPE, 'photo-1');

      expect(calls.some((c) => c.op === 'delete')).toBe(true);
      expect(storage.removeByPublicUrls).toHaveBeenCalledWith([photoRow().imageUrl]);
      expect(res.photos).toHaveLength(0);
    });
  });
});
