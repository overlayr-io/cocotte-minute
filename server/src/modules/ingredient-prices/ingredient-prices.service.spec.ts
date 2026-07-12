import { ForbiddenException, NotFoundException } from '@nestjs/common';

import { DrizzleDB } from '../../db/drizzle.provider';
import { PremiumService } from '../billing/premium.service';
import { IngredientsService } from '../ingredients/ingredients.service';
import { IngredientPricesService } from './ingredient-prices.service';

/** Faux Drizzle chaînable/thenable (cf. recipes.service.spec), + capture des `.set`/`.values`. */
function makeDb(results: unknown[]): { db: DrizzleDB; patches: Record<string, unknown>[] } {
  let i = 0;
  const patches: Record<string, unknown>[] = [];
  const builder = (payload: unknown) => {
    const b: Record<string, unknown> = {};
    for (const m of ['from', 'where', 'returning']) {
      b[m] = () => b;
    }
    b.set = (v: Record<string, unknown>) => {
      patches.push(v);
      return b;
    };
    b.values = (v: Record<string, unknown>) => {
      patches.push(v);
      return b;
    };
    b.then = (res: (v: unknown) => unknown, rej: (e: unknown) => unknown) =>
      Promise.resolve(payload).then(res, rej);
    return b;
  };
  const op = () => () => builder(results[i++]);
  const db = {
    select: op(),
    insert: op(),
    update: op(),
  } as unknown as DrizzleDB;
  return { db, patches };
}

const USER = 'user-1';
const INGREDIENT = 'ing-1';

const priceRow = (over: Partial<Record<string, unknown>> = {}) => ({
  id: 'price-1',
  userId: USER,
  ingredientId: INGREDIENT,
  priceReferenceUnit: 'kilogram',
  lowPrice: null,
  highPrice: null,
  averagePrice: 3.5,
  updatedAt: new Date('2026-01-01T00:00:00.000Z'),
  ...over,
});

const ingredientsStub = {
  assertVisible: jest.fn().mockResolvedValue(undefined),
} as unknown as IngredientsService;

const premiumStub = (isPremium = false) =>
  ({ isPremium: jest.fn().mockResolvedValue(isPremium) }) as unknown as PremiumService;

describe('IngredientPricesService.upsert', () => {
  it("rejette (403) l'écriture de bas/haut par un utilisateur non premium", async () => {
    const { db } = makeDb([]);
    const service = new IngredientPricesService(db, ingredientsStub, premiumStub(false));

    await expect(
      service.upsert(USER, INGREDIENT, {
        priceReferenceUnit: 'kilogram',
        lowPrice: 1,
        highPrice: 2,
      }),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('autorise bas/haut pour un utilisateur premium', async () => {
    const { db } = makeDb([[], [priceRow({ lowPrice: 1, highPrice: 2, averagePrice: 1.5 })]]);
    const service = new IngredientPricesService(db, ingredientsStub, premiumStub(true));

    const dto = await service.upsert(USER, INGREDIENT, {
      priceReferenceUnit: 'kilogram',
      lowPrice: 1,
      highPrice: 2,
      averagePrice: 1.5,
    });

    expect(dto.lowPrice).toBe(1);
    expect(dto.highPrice).toBe(2);
  });

  it("n'appelle pas la vérification premium pour une saisie moyenne seule (gratuit)", async () => {
    const { db } = makeDb([[], [priceRow({ averagePrice: 0.4 })]]);
    const premium = premiumStub(false);
    const service = new IngredientPricesService(db, ingredientsStub, premium);

    await service.upsert(USER, INGREDIENT, {
      priceReferenceUnit: 'kilogram',
      averagePrice: 0.4,
    });

    expect(premium.isPremium).not.toHaveBeenCalled();
  });

  it('ne touche pas bas/haut déjà enregistrés quand seule la moyenne est renvoyée (désabonnement)', async () => {
    const { db, patches } = makeDb([[{ id: 'price-1' }], [priceRow({ averagePrice: 0.9 })]]);
    const service = new IngredientPricesService(db, ingredientsStub, premiumStub(false));

    await service.upsert(USER, INGREDIENT, {
      priceReferenceUnit: 'kilogram',
      averagePrice: 0.9,
    });

    const updatePatch = patches[0];
    expect(updatePatch).not.toHaveProperty('lowPrice');
    expect(updatePatch).not.toHaveProperty('highPrice');
    expect(updatePatch.averagePrice).toBe(0.9);
  });

  it("propage le rejet si l'ingrédient n'est pas visible pour l'utilisateur", async () => {
    const ingredients = {
      assertVisible: jest.fn().mockRejectedValue(new NotFoundException('Ingrédient introuvable')),
    } as unknown as IngredientsService;
    const { db } = makeDb([]);
    const service = new IngredientPricesService(db, ingredients, premiumStub());

    await expect(
      service.upsert(USER, INGREDIENT, { priceReferenceUnit: 'kilogram', averagePrice: 1 }),
    ).rejects.toBeInstanceOf(NotFoundException);
  });
});

describe('IngredientPricesService.listMine', () => {
  it('mappe les lignes en DTO camelCase', async () => {
    const { db } = makeDb([[priceRow()]]);
    const service = new IngredientPricesService(db, ingredientsStub, premiumStub());

    const result = await service.listMine(USER);

    expect(result).toHaveLength(1);
    expect(result[0].ingredientId).toBe(INGREDIENT);
    expect(result[0].averagePrice).toBe(3.5);
  });
});
