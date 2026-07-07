import {
  BadRequestException,
  ConflictException,
  NotFoundException,
} from '@nestjs/common';

import { DrizzleDB } from '../../db/drizzle.provider';
import { IngredientsService } from '../ingredients/ingredients.service';
import { RecipesService } from './recipes.service';

/** Faux Drizzle chaînable/thenable (cf. categories.service.spec). */
function makeDb(results: unknown[]): { db: DrizzleDB; calls: { op: string }[] } {
  let i = 0;
  const calls: { op: string }[] = [];
  const builder = (payload: unknown) => {
    const b: Record<string, unknown> = {};
    for (const m of [
      'from',
      'where',
      'orderBy',
      'groupBy',
      'innerJoin',
      'values',
      'set',
      'returning',
      'onConflictDoNothing',
      'onConflictDoUpdate',
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
const recipeRow = (over: Partial<Record<string, unknown>> = {}) => ({
  id: 'rec-1',
  authorId: USER,
  name: 'Pâtes à la sauce tomate',
  photoUrl: null,
  description: null,
  isBase: false,
  prepTime: 0,
  cookTime: 0,
  restTime: 0,
  servings: 1,
  deletedAt: null,
  createdAt: new Date('2026-01-01T00:00:00.000Z'),
  updatedAt: new Date('2026-01-01T00:00:00.000Z'),
  ...over,
});

const ingredientsStub = {} as IngredientsService;

const ingredientDto = (over: Partial<Record<string, unknown>> = {}) => ({
  id: 'ing-1',
  name: 'Tomate',
  unit: 'gramme',
  imageUrl: null,
  isSystem: false,
  importedFromId: null,
  createdAt: '2026-01-01T00:00:00.000Z',
  ...over,
});

describe('RecipesService', () => {
  describe('create', () => {
    it('insère et renvoie un résumé', async () => {
      const { db } = makeDb([[recipeRow()]]);
      const service = new RecipesService(db, ingredientsStub);
      const dto = await service.create(USER, { name: 'Pâtes à la sauce tomate' });
      expect(dto.id).toBe('rec-1');
      expect(dto.isBase).toBe(false);
      expect(dto.servings).toBe(1);
    });
  });

  describe('listByCategory', () => {
    it('mappe les lignes jointes du pivot en résumés', async () => {
      // select().from(recipeCategories).innerJoin(recipes) → [{ recipe }]
      const { db } = makeDb([[{ recipe: recipeRow() }]]);
      const service = new RecipesService(db, ingredientsStub);

      const result = await service.listByCategory(USER, 'cat-1');

      expect(result).toHaveLength(1);
      expect(result[0].id).toBe('rec-1');
    });
  });

  describe('softDelete', () => {
    it('lève NotFound si la recette n’appartient pas à l’utilisateur', async () => {
      const { db } = makeDb([[recipeRow({ authorId: 'someone-else' })]]);
      const service = new RecipesService(db, ingredientsStub);
      await expect(service.softDelete(USER, 'rec-1')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });
  });

  describe('update — verrou is_base', () => {
    it('refuse true→false si la recette est utilisée comme composant', async () => {
      // findOwnedOrFail → base ; isUsedAsComponent → une ligne parente.
      const { db } = makeDb([
        [recipeRow({ isBase: true })],
        [{ parentRecipeId: 'rec-2' }],
      ]);
      const service = new RecipesService(db, ingredientsStub);
      await expect(
        service.update(USER, 'rec-1', { isBase: false }),
      ).rejects.toBeInstanceOf(ConflictException);
    });

    it('autorise true→false si elle n’est utilisée nulle part', async () => {
      const { db } = makeDb([
        [recipeRow({ isBase: true })], // findOwnedOrFail
        [], // isUsedAsComponent → aucune
        [recipeRow({ isBase: false })], // update returning
      ]);
      const service = new RecipesService(db, ingredientsStub);
      const dto = await service.update(USER, 'rec-1', { isBase: false });
      expect(dto.isBase).toBe(false);
    });
  });

  describe('addComponent', () => {
    it('refuse l’auto-référence', async () => {
      const { db } = makeDb([]);
      const service = new RecipesService(db, ingredientsStub);
      await expect(
        service.addComponent(USER, 'rec-1', 'rec-1'),
      ).rejects.toBeInstanceOf(ConflictException);
    });

    it('refuse une recette normale comme composant', async () => {
      // findOwnedOrFail(parent) puis findOwnedOrFail(base is_base=false)
      const { db } = makeDb([
        [recipeRow()],
        [recipeRow({ id: 'rec-2', isBase: false })],
      ]);
      const service = new RecipesService(db, ingredientsStub);
      await expect(
        service.addComponent(USER, 'rec-1', 'rec-2'),
      ).rejects.toBeInstanceOf(ConflictException);
    });

    it('insère quand la base est bien une recette de base', async () => {
      const { db, calls } = makeDb([
        [recipeRow()], // parent
        [recipeRow({ id: 'rec-2', isBase: true })], // base
        undefined, // insert
      ]);
      const service = new RecipesService(db, ingredientsStub);
      await service.addComponent(USER, 'rec-1', 'rec-2');
      expect(calls.some((c) => c.op === 'insert')).toBe(true);
    });
  });

  describe('addIngredient', () => {
    it('lève NotFound si l’ingrédient n’est pas possédé', async () => {
      const { db } = makeDb([[recipeRow()]]); // findOwnedOrFail
      const ingredients = {
        listByIds: jest.fn().mockResolvedValue([]),
      } as unknown as IngredientsService;
      const service = new RecipesService(db, ingredients);
      await expect(
        service.addIngredient(USER, 'rec-1', 'ing-1', 120),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('upsert la ligne avec sa quantité', async () => {
      const { db, calls } = makeDb([
        [recipeRow()], // findOwnedOrFail
        undefined, // insert onConflictDoUpdate
      ]);
      const ingredients = {
        listByIds: jest.fn().mockResolvedValue([ingredientDto()]),
      } as unknown as IngredientsService;
      const service = new RecipesService(db, ingredients);
      await service.addIngredient(USER, 'rec-1', 'ing-1', 2.5);
      expect(calls.some((c) => c.op === 'insert')).toBe(true);
    });
  });

  describe('updateIngredientQuantity', () => {
    it('lève NotFound si l’ingrédient n’est pas sur la recette', async () => {
      const { db } = makeDb([
        [recipeRow()], // findOwnedOrFail
        [], // update returning → aucune ligne
      ]);
      const service = new RecipesService(db, ingredientsStub);
      await expect(
        service.updateIngredientQuantity(USER, 'rec-1', 'ing-1', 80),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('met à jour la quantité quand la ligne existe', async () => {
      const { db, calls } = makeDb([
        [recipeRow()], // findOwnedOrFail
        [{ ingredientId: 'ing-1' }], // update returning
      ]);
      const service = new RecipesService(db, ingredientsStub);
      await service.updateIngredientQuantity(USER, 'rec-1', 'ing-1', 80);
      expect(calls.some((c) => c.op === 'update')).toBe(true);
    });
  });

  describe('addStep', () => {
    it('refuse une référence de base avec une description', async () => {
      const { db } = makeDb([[recipeRow()]]); // findOwnedOrFail
      const service = new RecipesService(db, ingredientsStub);
      await expect(
        service.addStep(USER, 'rec-1', {
          baseRecipeRefId: 'rec-2',
          description: 'texte',
        }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('refuse l’auto-référence en étape', async () => {
      const { db } = makeDb([[recipeRow()]]); // findOwnedOrFail
      const service = new RecipesService(db, ingredientsStub);
      await expect(
        service.addStep(USER, 'rec-1', { baseRecipeRefId: 'rec-1' }),
      ).rejects.toBeInstanceOf(ConflictException);
    });

    it('refuse une étape texte sans description', async () => {
      const { db } = makeDb([[recipeRow()]]); // findOwnedOrFail
      const service = new RecipesService(db, ingredientsStub);
      await expect(
        service.addStep(USER, 'rec-1', { description: '   ' }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });
  });

  describe('updateStep', () => {
    it('refuse d’éditer une référence de base', async () => {
      const { db } = makeDb([
        [recipeRow()], // findOwnedOrFail
        [{ id: 'step-1', recipeId: 'rec-1', baseRecipeRefId: 'rec-2' }], // findStepOrFail
      ]);
      const service = new RecipesService(db, ingredientsStub);
      await expect(
        service.updateStep(USER, 'rec-1', 'step-1', { description: 'x' }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });
  });
});
