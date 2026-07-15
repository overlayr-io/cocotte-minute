import {
  BadRequestException,
  ConflictException,
  NotFoundException,
} from '@nestjs/common';

import { PremiumLimitException } from '../../common/errors/premium-limit.exception';
import { SupabaseStorageService } from '../../common/supabase/supabase-storage.service';
import { DrizzleDB } from '../../db/drizzle.provider';
import { PremiumService } from '../billing/premium.service';
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

/** Stub Storage : capture les URLs supprimées, no-op réseau. */
const storageStub = {
  removeByPublicUrls: jest.fn().mockResolvedValue(undefined),
} as unknown as SupabaseStorageService;

/** Stub premium : gratuit par défaut (les gardes freemium s'appliquent). */
const premiumStub = (isPremium = false) =>
  ({ isPremium: jest.fn().mockResolvedValue(isPremium) }) as unknown as PremiumService;

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
      const service = new RecipesService(db, ingredientsStub, premiumStub(), storageStub);
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
      const service = new RecipesService(db, ingredientsStub, premiumStub(), storageStub);

      const result = await service.listByCategory(USER, 'cat-1');

      expect(result).toHaveLength(1);
      expect(result[0].id).toBe('rec-1');
    });
  });

  describe('softDelete', () => {
    it('lève NotFound si la recette n’appartient pas à l’utilisateur', async () => {
      const { db } = makeDb([[recipeRow({ authorId: 'someone-else' })]]);
      const service = new RecipesService(db, ingredientsStub, premiumStub(), storageStub);
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
      const service = new RecipesService(db, ingredientsStub, premiumStub(), storageStub);
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
      const service = new RecipesService(db, ingredientsStub, premiumStub(), storageStub);
      const dto = await service.update(USER, 'rec-1', { isBase: false });
      expect(dto.isBase).toBe(false);
    });
  });

  describe('addComponent', () => {
    it('refuse l’auto-référence', async () => {
      const { db } = makeDb([]);
      const service = new RecipesService(db, ingredientsStub, premiumStub(), storageStub);
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
      const service = new RecipesService(db, ingredientsStub, premiumStub(), storageStub);
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
      const service = new RecipesService(db, ingredientsStub, premiumStub(), storageStub);
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
      const service = new RecipesService(db, ingredients, premiumStub(), storageStub);
      await expect(
        service.addIngredient(USER, 'rec-1', 'ing-1', 120),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('upsert la ligne avec sa quantité', async () => {
      const { db, calls } = makeDb([
        [recipeRow()], // findOwnedOrFail
        [], // select max(position) → liste vide, nextPosition = 0
        undefined, // insert onConflictDoUpdate
      ]);
      const ingredients = {
        listByIds: jest.fn().mockResolvedValue([ingredientDto()]),
      } as unknown as IngredientsService;
      const service = new RecipesService(db, ingredients, premiumStub(), storageStub);
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
      const service = new RecipesService(db, ingredientsStub, premiumStub(), storageStub);
      await expect(
        service.updateIngredientQuantity(USER, 'rec-1', 'ing-1', 80),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('met à jour la quantité quand la ligne existe', async () => {
      const { db, calls } = makeDb([
        [recipeRow()], // findOwnedOrFail
        [{ ingredientId: 'ing-1' }], // update returning
      ]);
      const service = new RecipesService(db, ingredientsStub, premiumStub(), storageStub);
      await service.updateIngredientQuantity(USER, 'rec-1', 'ing-1', 80);
      expect(calls.some((c) => c.op === 'update')).toBe(true);
    });
  });

  describe('reorderIngredients', () => {
    it('renumérote quand la liste est une permutation exacte', async () => {
      const { db, calls } = makeDb([
        [recipeRow()], // findOwnedOrFail
        [{ ingredientId: 'ing-1' }, { ingredientId: 'ing-2' }], // ingrédients de la recette
        undefined, // update position 0
        undefined, // update position 1
      ]);
      const service = new RecipesService(db, ingredientsStub, premiumStub(), storageStub);
      await service.reorderIngredients(USER, 'rec-1', ['ing-2', 'ing-1']);
      expect(calls.filter((c) => c.op === 'update').length).toBe(2);
    });

    it('lève BadRequest si la liste n’est pas une permutation exacte', async () => {
      const { db } = makeDb([
        [recipeRow()], // findOwnedOrFail
        [{ ingredientId: 'ing-1' }, { ingredientId: 'ing-2' }],
      ]);
      const service = new RecipesService(db, ingredientsStub, premiumStub(), storageStub);
      await expect(
        service.reorderIngredients(USER, 'rec-1', ['ing-1']),
      ).rejects.toBeInstanceOf(BadRequestException);
    });
  });

  describe('duplicateRecipe', () => {
    it('refuse la duplication d’une recette de base au-delà du quota gratuit (403)', async () => {
      const { db } = makeDb([
        [recipeRow({ isBase: true })], // findOwnedOrFail
        [{ n: 5 }], // count(is_base) = 5 → quota gratuit atteint
      ]);
      const service = new RecipesService(db, ingredientsStub, premiumStub(false), storageStub);
      await expect(service.duplicateRecipe(USER, 'rec-1')).rejects.toBeInstanceOf(
        PremiumLimitException,
      );
    });
  });

  describe('seedSamples (#12)', () => {
    it('prend le verrou avant de vérifier, et ne sème rien si le compte a déjà une recette',
      async () => {
        // Le `execute` (verrou consultatif) doit précéder le count : sans lui,
        // deux appels concurrents voient count=0 et sèment chacun leur jeu.
        const { db, calls } = makeDb([[{ n: 1 }]]);
        const service = new RecipesService(db, ingredientsStub, premiumStub(false), storageStub);

        await service.seedSamples(USER);

        expect(calls.map((c) => c.op)).toEqual(['execute', 'select']);
        expect(calls.some((c) => c.op === 'insert')).toBe(false);
      });
  });

  describe('favoris (#15)', () => {
    it('illimité même en gratuit : aucun quota ne bloque un nouveau favori', async () => {
      const { db, calls } = makeDb([
        [recipeRow()], // findOwnedOrFail
        [], // favori existant : aucun
      ]);
      const service = new RecipesService(db, ingredientsStub, premiumStub(false), storageStub);
      await expect(service.addFavorite(USER, 'rec-1')).resolves.toBeUndefined();
      expect(calls.filter((c) => c.op === 'insert')).toHaveLength(1);
    });

    it('idempotent : un doublon ne compte pas et n’insère pas', async () => {
      const { db, calls } = makeDb([
        [recipeRow()], // findOwnedOrFail
        [{ recipeId: 'rec-1' }], // déjà favori
      ]);
      const service = new RecipesService(db, ingredientsStub, premiumStub(false), storageStub);
      await service.addFavorite(USER, 'rec-1');
      expect(calls.some((c) => c.op === 'insert')).toBe(false);
    });
  });

  describe('collectIngredientQuantities (agrégation récursive)', () => {
    // Accès à la méthode privée (logique métier critique pour la liste de courses).
    type WithCollect = {
      collectIngredientQuantities(id: string): Promise<Map<string, number>>;
    };

    it('cumule les ingrédients directs et ceux d’une sous-recette de base (1×)', async () => {
      const { db } = makeDb([
        [{ ingredientId: 'ing1', quantity: 2 }], // directs du parent
        [{ baseRecipeId: 'base1' }], // composants du parent
        [], // réfs d'étape du parent
        [{ ingredientId: 'ing1', quantity: 3 }, { ingredientId: 'ing2', quantity: 5 }], // directs de base1
        [], // composants de base1
        [], // réfs d'étape de base1
      ]);
      const service = new RecipesService(db, ingredientsStub, premiumStub(), storageStub);
      const totals = await (service as unknown as WithCollect)
        .collectIngredientQuantities('parent');
      // ing1 cumulé (2 direct + 3 hérité), ing2 hérité seul.
      expect(Object.fromEntries(totals)).toEqual({ ing1: 5, ing2: 5 });
    });

    it('anti-cycle : une sous-recette qui se référence en boucle ne fait pas exploser', async () => {
      const { db } = makeDb([
        [{ ingredientId: 'ing1', quantity: 1 }], // directs parent
        [{ baseRecipeId: 'base1' }], // composants parent
        [], // réfs d'étape parent
        [{ ingredientId: 'ing2', quantity: 1 }], // directs base1
        [{ baseRecipeId: 'parent' }], // composants base1 → cycle vers parent
        [], // réfs d'étape base1
      ]);
      const service = new RecipesService(db, ingredientsStub, premiumStub(), storageStub);
      const totals = await (service as unknown as WithCollect)
        .collectIngredientQuantities('parent');
      expect(Object.fromEntries(totals)).toEqual({ ing1: 1, ing2: 1 });
    });
  });

  describe('garde freemium — 5 recettes de base max', () => {
    it('refuse la 6e recette de base en gratuit (403 structuré)', async () => {
      const { db } = makeDb([[{ n: 5 }]]); // count(is_base) = 5
      const service = new RecipesService(db, ingredientsStub, premiumStub(false), storageStub);

      const err = await service
        .create(USER, { name: 'Fond de veau', isBase: true })
        .catch((e: PremiumLimitException) => e);

      expect(err).toBeInstanceOf(PremiumLimitException);
      expect((err as PremiumLimitException).getResponse()).toMatchObject({
        code: 'PREMIUM_LIMIT_BASE_RECIPES',
        limit: 5,
        current: 5,
      });
    });

    it('autorise la création de base sous la limite sans lire le statut premium', async () => {
      const { db } = makeDb([
        [{ n: 4 }], // count
        [recipeRow({ isBase: true })], // insert returning
      ]);
      const premium = premiumStub(false);
      const service = new RecipesService(db, ingredientsStub, premium, storageStub);

      const dto = await service.create(USER, { name: 'Fond de veau', isBase: true });

      expect(dto.isBase).toBe(true);
      expect((premium as unknown as { isPremium: jest.Mock }).isPremium).not.toHaveBeenCalled();
    });

    it('ne compte pas les recettes normales (pas de garde sans isBase)', async () => {
      const { db, calls } = makeDb([[recipeRow()]]); // insert direct
      const service = new RecipesService(db, ingredientsStub, premiumStub(false), storageStub);

      await service.create(USER, { name: 'Pâtes' });

      // Aucun select de comptage : premier appel = insert.
      expect(calls[0]).toEqual({ op: 'insert' });
    });

    it('laisse passer au-delà de la limite en premium', async () => {
      const { db } = makeDb([
        [{ n: 12 }], // count
        [recipeRow({ isBase: true })], // insert returning
      ]);
      const service = new RecipesService(db, ingredientsStub, premiumStub(true), storageStub);

      const dto = await service.create(USER, { name: 'Fond de veau', isBase: true });
      expect(dto.isBase).toBe(true);
    });

    it('applique la garde sur la bascule normale→base (update)', async () => {
      const { db } = makeDb([
        [recipeRow({ isBase: false })], // findOwnedOrFail
        [{ n: 5 }], // count
      ]);
      const service = new RecipesService(db, ingredientsStub, premiumStub(false), storageStub);

      await expect(service.update(USER, 'rec-1', { isBase: true })).rejects.toBeInstanceOf(
        PremiumLimitException,
      );
    });

    it('ignore la garde quand la recette est déjà de base (update sans bascule)', async () => {
      const { db } = makeDb([
        [recipeRow({ isBase: true })], // findOwnedOrFail
        [recipeRow({ isBase: true, name: 'Renommée' })], // update returning
      ]);
      const service = new RecipesService(db, ingredientsStub, premiumStub(false), storageStub);

      const dto = await service.update(USER, 'rec-1', { isBase: true, name: 'Renommée' });
      expect(dto.isBase).toBe(true);
    });
  });

  describe('addStep', () => {
    it('refuse une référence de base avec une description', async () => {
      const { db } = makeDb([[recipeRow()]]); // findOwnedOrFail
      const service = new RecipesService(db, ingredientsStub, premiumStub(), storageStub);
      await expect(
        service.addStep(USER, 'rec-1', {
          baseRecipeRefId: 'rec-2',
          description: 'texte',
        }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('refuse l’auto-référence en étape', async () => {
      const { db } = makeDb([[recipeRow()]]); // findOwnedOrFail
      const service = new RecipesService(db, ingredientsStub, premiumStub(), storageStub);
      await expect(
        service.addStep(USER, 'rec-1', { baseRecipeRefId: 'rec-1' }),
      ).rejects.toBeInstanceOf(ConflictException);
    });

    it('refuse une étape texte sans description', async () => {
      const { db } = makeDb([[recipeRow()]]); // findOwnedOrFail
      const service = new RecipesService(db, ingredientsStub, premiumStub(), storageStub);
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
      const service = new RecipesService(db, ingredientsStub, premiumStub(), storageStub);
      await expect(
        service.updateStep(USER, 'rec-1', 'step-1', { description: 'x' }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });
  });
});
