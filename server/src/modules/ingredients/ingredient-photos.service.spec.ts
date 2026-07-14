import { PremiumLimitException } from '../../common/errors/premium-limit.exception';
import { SupabaseStorageService } from '../../common/supabase/supabase-storage.service';
import { DrizzleDB } from '../../db/drizzle.provider';
import { PremiumService } from '../billing/premium.service';
import { IngredientPhotosService } from './ingredient-photos.service';
import { IngredientsService } from './ingredients.service';

/** Faux Drizzle chaînable/thenable (cf. recipe-gallery.service.spec). */
function makeDb(results: unknown[]): { db: DrizzleDB; calls: { op: string }[] } {
  let i = 0;
  const calls: { op: string }[] = [];
  const builder = (payload: unknown) => {
    const b: Record<string, unknown> = {};
    for (const m of ['from', 'where', 'orderBy', 'values', 'set']) {
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
const ING = 'ing-1';
const URL = 'https://x.supabase.co/storage/v1/object/public/images/products/u/1.jpg';

const ingredientsStub = () =>
  ({ assertVisible: jest.fn().mockResolvedValue(undefined) }) as unknown as IngredientsService;
const premiumStub = (isPremium = false) =>
  ({ isPremium: jest.fn().mockResolvedValue(isPremium) }) as unknown as PremiumService;
const storageStub = () =>
  ({ removeByPublicUrls: jest.fn().mockResolvedValue(undefined) }) as unknown as SupabaseStorageService;

describe('IngredientPhotosService', () => {
  describe('add — quota', () => {
    it('refuse une 2e photo en gratuit (limite 1, 403)', async () => {
      const { db } = makeDb([[{ n: 1 }]]); // count = 1 → limite gratuite atteinte
      const service = new IngredientPhotosService(
        db,
        ingredientsStub(),
        premiumStub(false),
        storageStub(),
      );
      await expect(service.add(USER, ING, URL)).rejects.toBeInstanceOf(
        PremiumLimitException,
      );
    });

    it('autorise jusqu’à 3 photos en Pro', async () => {
      const { db, calls } = makeDb([
        [{ n: 1 }], // count = 1 (< 3 en Pro)
        undefined, // insert
        [], // listPhotos
      ]);
      const service = new IngredientPhotosService(
        db,
        ingredientsStub(),
        premiumStub(true),
        storageStub(),
      );
      await service.add(USER, ING, URL);
      expect(calls.some((c) => c.op === 'insert')).toBe(true);
    });
  });
});
