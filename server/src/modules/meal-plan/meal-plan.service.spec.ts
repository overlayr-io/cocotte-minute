import { BadRequestException, NotFoundException } from '@nestjs/common';

import { PremiumLimitException } from '../../common/errors/premium-limit.exception';
import { DrizzleDB } from '../../db/drizzle.provider';
import { PremiumService } from '../billing/premium.service';
import { RecipesService } from '../recipes/recipes.service';
import { MealPlanService } from './meal-plan.service';

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

const summary = (id: string) => ({
  id,
  name: `Recette ${id}`,
  photoUrl: null,
  isBase: false,
  prepTime: 10,
  cookTime: 20,
  restTime: 0,
  servings: 2,
  createdAt: '2026-07-01T00:00:00.000Z',
});

const entryRow = (over: Partial<Record<string, unknown>> = {}) => ({
  id: 'entry-1',
  ownerId: USER,
  day: '2026-07-07',
  slot: 'midi',
  entryType: 'recipe',
  recipeId: 'rec-1',
  noteText: null,
  position: 0,
  createdAt: new Date('2026-07-07T00:00:00.000Z'),
  updatedAt: new Date('2026-07-07T00:00:00.000Z'),
  ...over,
});

const recipesStub = (summaries: unknown[] = []) =>
  ({ listByIds: jest.fn().mockResolvedValue(summaries) }) as unknown as RecipesService;

const premiumStub = (isPremium = false) =>
  ({ isPremium: jest.fn().mockResolvedValue(isPremium) }) as unknown as PremiumService;

const premiumCode = (e: unknown): string =>
  (
    (e as PremiumLimitException).getResponse() as {
      code: string;
    }
  ).code;

// Samedi 11 juillet 2026 → semaine courante T = lundi 6 juillet.
// Rétention : 2026-06-29 → 2026-07-27 (excl.) ; écriture gratuite : 06/07 → 20/07 (excl.).
beforeEach(() => {
  jest.useFakeTimers({ now: new Date('2026-07-11T10:00:00Z') });
});
afterEach(() => {
  jest.useRealTimers();
});

describe('MealPlanService.addEntry — gardes premium', () => {
  it('gratuit : refuse la 2e entrée d’un créneau (tous types confondus)', async () => {
    // purge (delete), count = 1 (select)
    const { db } = makeDb([undefined, [{ n: 1 }]]);
    const service = new MealPlanService(db, recipesStub(), premiumStub(false));
    const dto = { day: '2026-07-07', slot: 'midi', entryType: 'note', noteText: 'Pizza' };
    const err: unknown = await service.addEntry(USER, dto as never).then(
      () => null,
      (e: unknown) => e,
    );
    expect(err).toBeInstanceOf(PremiumLimitException);
    expect(premiumCode(err)).toBe('PREMIUM_LIMIT_MEAL_SLOT_ENTRIES');
  });

  it('gratuit : refuse l’écriture hors T/T+1 (semaine T+2) → upsell', async () => {
    const { db } = makeDb([undefined]);
    const service = new MealPlanService(db, recipesStub(), premiumStub(false));
    const dto = { day: '2026-07-21', slot: 'soir', entryType: 'eating_out' };
    const err: unknown = await service.addEntry(USER, dto as never).then(
      () => null,
      (e: unknown) => e,
    );
    expect(err).toBeInstanceOf(PremiumLimitException);
    expect(premiumCode(err)).toBe('PREMIUM_LIMIT_MEAL_PLAN_WEEK');
  });

  it('premium : écrit sur T+2 et empile une 2e entrée sur le créneau', async () => {
    const row = entryRow({ day: '2026-07-21', position: 1 });
    // purge, count = 1, insert returning
    const { db, calls } = makeDb([undefined, [{ n: 1 }], [row]]);
    const service = new MealPlanService(db, recipesStub([summary('rec-1')]), premiumStub(true));
    const dto = { day: '2026-07-21', slot: 'midi', entryType: 'recipe', recipeId: 'rec-1' };
    const result = await service.addEntry(USER, dto as never);
    expect(result.position).toBe(1);
    expect(result.recipe?.name).toBe('Recette rec-1');
    expect(calls.map((c) => c.op)).toEqual(['delete', 'select', 'insert']);
  });

  it('hors fenêtre de rétention → 400, même en premium', async () => {
    const { db } = makeDb([undefined]);
    const service = new MealPlanService(db, recipesStub(), premiumStub(true));
    const dto = { day: '2026-08-10', slot: 'midi', entryType: 'eating_out' };
    await expect(service.addEntry(USER, dto as never)).rejects.toBeInstanceOf(
      BadRequestException,
    );
  });

  it('entrée recette : recette introuvable → 404', async () => {
    const { db } = makeDb([undefined]);
    const service = new MealPlanService(db, recipesStub([]), premiumStub(false));
    const dto = { day: '2026-07-07', slot: 'midi', entryType: 'recipe', recipeId: 'rec-x' };
    await expect(service.addEntry(USER, dto as never)).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });
});

describe('MealPlanService.listWeek', () => {
  it('refuse un weekStart qui n’est pas un lundi', async () => {
    const { db } = makeDb([]);
    const service = new MealPlanService(db, recipesStub(), premiumStub());
    await expect(service.listWeek(USER, '2026-07-07')).rejects.toBeInstanceOf(
      BadRequestException,
    );
  });

  it('hors rétention : purge quand même puis renvoie une liste vide', async () => {
    const { db, calls } = makeDb([undefined]);
    const service = new MealPlanService(db, recipesStub(), premiumStub());
    const result = await service.listWeek(USER, '2026-08-10');
    expect(result).toEqual([]);
    expect(calls.map((c) => c.op)).toEqual(['delete']);
  });

  it('cascade lazy : une entrée dont la recette est soft-supprimée est purgée et exclue', async () => {
    const alive = entryRow();
    const orphan = entryRow({ id: 'entry-2', recipeId: 'rec-gone', slot: 'soir' });
    // purge, select entries, delete orphans
    const { db, calls } = makeDb([undefined, [alive, orphan], undefined]);
    const service = new MealPlanService(db, recipesStub([summary('rec-1')]), premiumStub());
    const result = await service.listWeek(USER, '2026-07-06');
    expect(result).toHaveLength(1);
    expect(result[0].id).toBe('entry-1');
    expect(result[0].recipe?.id).toBe('rec-1');
    expect(calls.map((c) => c.op)).toEqual(['delete', 'select', 'delete']);
  });
});

describe('MealPlanService.removeEntry', () => {
  it('gratuit : refuse le retrait sur une semaine en lecture seule (T-1)', async () => {
    const row = entryRow({ day: '2026-07-01' }); // mercredi T-1
    const { db } = makeDb([[row]]);
    const service = new MealPlanService(db, recipesStub(), premiumStub(false));
    const err: unknown = await service.removeEntry(USER, 'entry-1').then(
      () => null,
      (e: unknown) => e,
    );
    expect(err).toBeInstanceOf(PremiumLimitException);
    expect(premiumCode(err)).toBe('PREMIUM_LIMIT_MEAL_PLAN_WEEK');
  });

  it('retire une entrée de la semaine courante', async () => {
    const row = entryRow();
    const { db, calls } = makeDb([[row], undefined]);
    const service = new MealPlanService(db, recipesStub(), premiumStub(false));
    await service.removeEntry(USER, 'entry-1');
    expect(calls.map((c) => c.op)).toEqual(['select', 'delete']);
  });

  it('entrée inconnue → 404', async () => {
    const { db } = makeDb([[]]);
    const service = new MealPlanService(db, recipesStub(), premiumStub(false));
    await expect(service.removeEntry(USER, 'entry-x')).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });
});
