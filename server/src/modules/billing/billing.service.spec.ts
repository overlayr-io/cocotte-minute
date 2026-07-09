import { DrizzleDB } from '../../db/drizzle.provider';
import { BillingService } from './billing.service';

/** Faux Drizzle chaînable/thenable (cf. categories.service.spec). */
function makeDb(results: unknown[]): {
  db: DrizzleDB;
  calls: { op: string; args?: unknown }[];
} {
  let i = 0;
  const calls: { op: string; args?: unknown }[] = [];
  const builder = (payload: unknown) => {
    const b: Record<string, unknown> = {};
    for (const m of ['from', 'where', 'limit', 'values', 'onConflictDoUpdate']) {
      b[m] = (args?: unknown) => {
        if (m === 'values' || m === 'onConflictDoUpdate') calls.push({ op: m, args });
        return b;
      };
    }
    b.then = (res: (v: unknown) => unknown, rej: (e: unknown) => unknown) =>
      Promise.resolve(payload).then(res, rej);
    return b;
  };
  const op = (name: string) => () => {
    calls.push({ op: name });
    return builder(results[i++]);
  };
  const db = { select: op('select'), insert: op('insert') } as unknown as DrizzleDB;
  return { db, calls };
}

const USER_UUID = 'a1b2c3d4-e5f6-4890-abcd-ef1234567890';
const FUTURE_MS = Date.now() + 30 * 24 * 3600 * 1000;

const event = (over: Record<string, unknown> = {}) => ({
  api_version: '1.0',
  event: {
    type: 'INITIAL_PURCHASE',
    id: 'evt-1',
    event_timestamp_ms: Date.now(),
    app_user_id: USER_UUID,
    aliases: [USER_UUID],
    entitlement_ids: ['pro'],
    product_id: 'pro_monthly',
    expiration_at_ms: FUTURE_MS,
    environment: 'SANDBOX',
    store: 'TEST_STORE',
    ...over,
  },
});

describe('BillingService.applyWebhook', () => {
  it('applique un INITIAL_PURCHASE : abonnement borné par expiration_at_ms', async () => {
    const { db, calls } = makeDb([[], undefined]); // select (pas de ligne) puis insert
    const outcome = await new BillingService(db).applyWebhook(event());

    expect(outcome).toBe('applied');
    const values = calls.find((c) => c.op === 'values')?.args as Record<string, unknown>;
    expect(values.userId).toBe(USER_UUID);
    expect(values.premiumType).toBe('subscription');
    expect((values.premiumUntil as Date).getTime()).toBe(FUTURE_MS);
  });

  it('applique un achat sans échéance comme lifetime (NON_RENEWING_PURCHASE)', async () => {
    const { db, calls } = makeDb([[], undefined]);
    const outcome = await new BillingService(db).applyWebhook(
      event({ type: 'NON_RENEWING_PURCHASE', expiration_at_ms: null }),
    );

    expect(outcome).toBe('applied');
    const values = calls.find((c) => c.op === 'values')?.args as Record<string, unknown>;
    expect(values.premiumType).toBe('lifetime');
    expect(values.premiumUntil).toBeNull();
  });

  it('révoque UNIQUEMENT sur EXPIRATION', async () => {
    const { db, calls } = makeDb([[{ premiumUpdatedAt: null }], undefined]);
    const outcome = await new BillingService(db).applyWebhook(event({ type: 'EXPIRATION' }));

    expect(outcome).toBe('applied');
    const values = calls.find((c) => c.op === 'values')?.args as Record<string, unknown>;
    expect(values.premiumType).toBe('none');
    expect(values.premiumUntil).toBeNull();
  });

  it("ne touche pas à l'accès sur CANCELLATION (auto-renew off, accès jusqu'à l'échéance)", async () => {
    const { db, calls } = makeDb([]);
    const outcome = await new BillingService(db).applyWebhook(event({ type: 'CANCELLATION' }));

    expect(outcome).toBe('ignored_event_type');
    expect(calls).toHaveLength(0); // aucune lecture/écriture DB
  });

  it("ne touche pas à l'accès sur BILLING_ISSUE (période de grâce store)", async () => {
    const { db, calls } = makeDb([]);
    const outcome = await new BillingService(db).applyWebhook(event({ type: 'BILLING_ISSUE' }));

    expect(outcome).toBe('ignored_event_type');
    expect(calls).toHaveLength(0);
  });

  it('ignore un événement pour un autre entitlement', async () => {
    const { db, calls } = makeDb([]);
    const outcome = await new BillingService(db).applyWebhook(
      event({ entitlement_ids: ['autre'] }),
    );

    expect(outcome).toBe('ignored_entitlement');
    expect(calls).toHaveLength(0);
  });

  it("résout l'UUID Supabase depuis les aliases quand app_user_id est anonyme", async () => {
    const { db, calls } = makeDb([[], undefined]);
    const outcome = await new BillingService(db).applyWebhook(
      event({
        app_user_id: '$RCAnonymousID:abc123',
        original_app_user_id: '$RCAnonymousID:abc123',
        aliases: ['$RCAnonymousID:abc123', USER_UUID],
      }),
    );

    expect(outcome).toBe('applied');
    const values = calls.find((c) => c.op === 'values')?.args as Record<string, unknown>;
    expect(values.userId).toBe(USER_UUID);
  });

  it('ignore un subscriber sans aucun UUID Supabase', async () => {
    const { db, calls } = makeDb([]);
    const outcome = await new BillingService(db).applyWebhook(
      event({
        app_user_id: '$RCAnonymousID:abc123',
        original_app_user_id: '$RCAnonymousID:abc123',
        aliases: ['$RCAnonymousID:abc123'],
      }),
    );

    expect(outcome).toBe('no_supabase_user');
    expect(calls).toHaveLength(0);
  });

  it('ignore un événement plus ancien que la projection (livraison désordonnée)', async () => {
    const now = Date.now();
    const { db, calls } = makeDb([[{ premiumUpdatedAt: new Date(now) }]]);
    const outcome = await new BillingService(db).applyWebhook(
      event({ event_timestamp_ms: now - 60_000 }),
    );

    expect(outcome).toBe('skipped_stale');
    expect(calls.filter((c) => c.op === 'insert')).toHaveLength(0);
  });

  it('ignore un payload sans événement exploitable', async () => {
    const { db, calls } = makeDb([]);
    const outcome = await new BillingService(db).applyWebhook({ foo: 'bar' });

    expect(outcome).toBe('ignored_malformed');
    expect(calls).toHaveLength(0);
  });
});
