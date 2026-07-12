import { ConflictException } from '@nestjs/common';

import { AuthenticatedUser } from '../../common/auth/authenticated-user';
import { SupabaseAdminService } from '../../common/supabase/supabase-admin.service';
import { DrizzleDB } from '../../db/drizzle.provider';
import type { AccountRow, AccountStatus } from '../../db/schema/accounts.schema';
import { RevenueCatAdminService } from '../billing/revenuecat-admin.service';
import { CategoriesService } from '../categories/categories.service';
import { IngredientsService } from '../ingredients/ingredients.service';
import { PeopleService } from '../people/people.service';
import { RecipesService } from '../recipes/recipes.service';
import { MealPlanService } from '../meal-plan/meal-plan.service';
import { ShoppingListsService } from '../shopping-lists/shopping-lists.service';
import { TagsService } from '../tags/tags.service';
import { AccountService, DELETION_DELAY_DAYS } from './account.service';

/** Faux Drizzle chaînable/thenable (cf. people.service.spec). */
function makeDb(results: unknown[]): { db: DrizzleDB; calls: { op: string }[] } {
  let i = 0;
  const calls: { op: string }[] = [];
  const builder = (payload: unknown) => {
    const b: Record<string, unknown> = {};
    for (const m of ['from', 'where', 'values', 'set', 'returning', 'onConflictDoNothing']) {
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

const accountRow = (over: Partial<AccountRow> = {}): AccountRow => ({
  userId: USER,
  status: 'active',
  deletionRequestedAt: null,
  premiumType: 'none',
  premiumUntil: null,
  premiumUpdatedAt: null,
  createdAt: new Date('2026-01-01T00:00:00.000Z'),
  updatedAt: new Date('2026-01-01T00:00:00.000Z'),
  ...over,
});

const authUser = (isAnonymous: boolean): AuthenticatedUser => ({
  id: USER,
  isAnonymous,
  email: isAnonymous ? undefined : 'a@b.c',
});

function domainMocks() {
  const mk = () => ({ deleteAllForUser: jest.fn().mockResolvedValue(undefined) });
  return {
    ingredients: mk() as unknown as IngredientsService,
    tags: mk() as unknown as TagsService,
    people: mk() as unknown as PeopleService,
    categories: mk() as unknown as CategoriesService,
    recipes: mk() as unknown as RecipesService,
    shopping: mk() as unknown as ShoppingListsService,
    mealPlan: mk() as unknown as MealPlanService,
  };
}

function adminMock(): SupabaseAdminService {
  return {
    anonymizeAuthUser: jest.fn().mockResolvedValue(undefined),
    deleteAuthUser: jest.fn().mockResolvedValue(undefined),
  } as unknown as SupabaseAdminService;
}

function revenueCatMock(): RevenueCatAdminService {
  return {
    deleteSubscriber: jest.fn().mockResolvedValue(undefined),
  } as unknown as RevenueCatAdminService;
}

function build(
  db: DrizzleDB,
  admin: SupabaseAdminService,
  d = domainMocks(),
  revenueCat = revenueCatMock(),
) {
  const service = new AccountService(
    db,
    d.ingredients,
    d.tags,
    d.people,
    d.categories,
    d.recipes,
    d.shopping,
    d.mealPlan,
    admin,
    revenueCat,
  );
  return { service, d, revenueCat };
}

describe('AccountService', () => {
  describe('requestDeletion — compte anonyme', () => {
    it('purge tous les domaines, marque `deleted`, supprime le user Auth, sans délai', async () => {
      // ensure: insert + select(active), puis update(markStatus)
      const { db } = makeDb([null, [accountRow()], null]);
      const admin = adminMock();
      const { service, d } = build(db, admin);

      const res = await service.requestDeletion(authUser(true));

      expect(res).toEqual({ status: 'deleted', anonymous: true, deletionScheduledAt: null });
      for (const svc of Object.values(d)) {
        expect(svc.deleteAllForUser).toHaveBeenCalledWith(USER);
      }
      expect(admin.deleteAuthUser).toHaveBeenCalledWith(USER);
      expect(admin.anonymizeAuthUser).not.toHaveBeenCalled();
    });
  });

  describe('requestDeletion — compte complet', () => {
    it('anonymise le user Auth, passe `pending_deletion`, planifie à J+30, sans purge métier', async () => {
      const { db } = makeDb([null, [accountRow()], null]);
      const admin = adminMock();
      const { service, d } = build(db, admin);

      const before = Date.now();
      const res = await service.requestDeletion(authUser(false));

      expect(res.status).toBe('pending_deletion');
      expect(res.anonymous).toBe(false);
      const scheduled = new Date(res.deletionScheduledAt as string).getTime();
      const expected = before + DELETION_DELAY_DAYS * 24 * 60 * 60 * 1000;
      expect(Math.abs(scheduled - expected)).toBeLessThan(5000);
      expect(admin.anonymizeAuthUser).toHaveBeenCalledWith(USER);
      expect(admin.deleteAuthUser).not.toHaveBeenCalled();
      // données métier conservées pour rollback
      for (const svc of Object.values(d)) {
        expect(svc.deleteAllForUser).not.toHaveBeenCalled();
      }
    });

    it('refuse si une suppression est déjà en cours', async () => {
      const { db } = makeDb([null, [accountRow({ status: 'pending_deletion' })]]);
      const { service } = build(db, adminMock());
      await expect(service.requestDeletion(authUser(false))).rejects.toBeInstanceOf(
        ConflictException,
      );
    });
  });

  describe('getStatus', () => {
    it('renvoie `active` sans échéance quand aucune ligne compte n\'existe', async () => {
      const { db } = makeDb([[]]); // select → aucune ligne
      const { service } = build(db, adminMock());
      await expect(service.getStatus(USER)).resolves.toEqual({
        status: 'active',
        deletionScheduledAt: null,
      });
    });

    it('renvoie `active` sans échéance pour un compte actif', async () => {
      const { db } = makeDb([[accountRow({ status: 'active' })]]);
      const { service } = build(db, adminMock());
      await expect(service.getStatus(USER)).resolves.toEqual({
        status: 'active',
        deletionScheduledAt: null,
      });
    });

    it('renvoie `pending_deletion` avec l\'échéance J+30 calculée', async () => {
      const requestedAt = new Date('2026-06-01T00:00:00.000Z');
      const { db } = makeDb([
        [accountRow({ status: 'pending_deletion', deletionRequestedAt: requestedAt })],
      ]);
      const { service } = build(db, adminMock());

      const res = await service.getStatus(USER);

      expect(res.status).toBe('pending_deletion');
      const expected = new Date(
        requestedAt.getTime() + DELETION_DELAY_DAYS * 24 * 60 * 60 * 1000,
      ).toISOString();
      expect(res.deletionScheduledAt).toBe(expected);
    });
  });

  describe('cancelDeletion', () => {
    it('repasse `active` si dans le délai', async () => {
      const requestedAt = new Date(Date.now() - 5 * 24 * 60 * 60 * 1000); // J+5
      const { db } = makeDb([
        null,
        [accountRow({ status: 'pending_deletion', deletionRequestedAt: requestedAt })],
        null,
      ]);
      const { service } = build(db, adminMock());
      await expect(service.cancelDeletion(USER)).resolves.toEqual({ status: 'active' });
    });

    it('refuse si le délai de 30 jours est dépassé', async () => {
      const requestedAt = new Date(Date.now() - 31 * 24 * 60 * 60 * 1000);
      const { db } = makeDb([
        null,
        [accountRow({ status: 'pending_deletion', deletionRequestedAt: requestedAt })],
      ]);
      const { service } = build(db, adminMock());
      await expect(service.cancelDeletion(USER)).rejects.toBeInstanceOf(ConflictException);
    });

    it('refuse si aucune suppression en attente', async () => {
      const { db } = makeDb([null, [accountRow({ status: 'active' })]]);
      const { service } = build(db, adminMock());
      await expect(service.cancelDeletion(USER)).rejects.toBeInstanceOf(ConflictException);
    });
  });

  describe('purgeExpiredDeletions (CRON)', () => {
    it('supprime en cascade chaque compte expiré et retourne leur nombre', async () => {
      const expired: AccountStatus = 'pending_deletion';
      const { db } = makeDb([
        [accountRow({ status: expired, deletionRequestedAt: new Date('2026-01-01') })],
        null, // markStatus deleted
      ]);
      const admin = adminMock();
      const { service, d } = build(db, admin);

      const count = await service.purgeExpiredDeletions();

      expect(count).toBe(1);
      for (const svc of Object.values(d)) {
        expect(svc.deleteAllForUser).toHaveBeenCalledWith(USER);
      }
      expect(admin.deleteAuthUser).toHaveBeenCalledWith(USER);
    });
  });
});
