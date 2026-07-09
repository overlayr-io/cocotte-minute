import { DrizzleDB } from '../../db/drizzle.provider';
import { PremiumService } from './premium.service';

/** Faux Drizzle chaînable/thenable (cf. categories.service.spec). */
function makeDb(results: unknown[]): DrizzleDB {
  let i = 0;
  const builder = (payload: unknown) => {
    const b: Record<string, unknown> = {};
    for (const m of ['from', 'where', 'limit']) {
      b[m] = () => b;
    }
    b.then = (res: (v: unknown) => unknown, rej: (e: unknown) => unknown) =>
      Promise.resolve(payload).then(res, rej);
    return b;
  };
  return {
    select: () => builder(results[i++]),
  } as unknown as DrizzleDB;
}

const USER = 'user-1';

describe('PremiumService.isPremium', () => {
  it('false sans ligne accounts (compte jamais provisionné)', async () => {
    const service = new PremiumService(makeDb([[]]));
    await expect(service.isPremium(USER)).resolves.toBe(false);
  });

  it('false pour premium_type=none', async () => {
    const service = new PremiumService(
      makeDb([[{ premiumType: 'none', premiumUntil: null }]]),
    );
    await expect(service.isPremium(USER)).resolves.toBe(false);
  });

  it('true pour lifetime, sans condition d’échéance', async () => {
    const service = new PremiumService(
      makeDb([[{ premiumType: 'lifetime', premiumUntil: null }]]),
    );
    await expect(service.isPremium(USER)).resolves.toBe(true);
  });

  it('true pour un abonnement dont l’échéance est future', async () => {
    const service = new PremiumService(
      makeDb([
        [{ premiumType: 'subscription', premiumUntil: new Date(Date.now() + 86_400_000) }],
      ]),
    );
    await expect(service.isPremium(USER)).resolves.toBe(true);
  });

  it('false pour un abonnement expiré (webhook EXPIRATION perdu)', async () => {
    const service = new PremiumService(
      makeDb([
        [{ premiumType: 'subscription', premiumUntil: new Date(Date.now() - 1000) }],
      ]),
    );
    await expect(service.isPremium(USER)).resolves.toBe(false);
  });

  it('false pour un abonnement sans échéance (état incohérent, refus par défaut)', async () => {
    const service = new PremiumService(
      makeDb([[{ premiumType: 'subscription', premiumUntil: null }]]),
    );
    await expect(service.isPremium(USER)).resolves.toBe(false);
  });
});
