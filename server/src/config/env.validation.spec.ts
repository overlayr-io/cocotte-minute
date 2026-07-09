import { validateEnv } from './env.validation';

const base = {
  DATABASE_URL: 'postgresql://postgres:pwd@db.abc.supabase.co:5432/postgres',
  SUPABASE_URL: 'https://abc.supabase.co',
  SUPABASE_SERVICE_ROLE_KEY: 'service-role-key',
  SUPABASE_JWT_SECRET: 'jwt-secret-with-at-least-32-characters!!',
  REVENUECAT_WEBHOOK_SECRET: 'webhook-secret-value',
};

describe('validateEnv', () => {
  it('valide une config complète et convertit PORT en nombre', () => {
    const result = validateEnv({ ...base, PORT: '4000' });
    expect(result.PORT).toBe(4000);
    expect(typeof result.PORT).toBe('number');
  });

  it('applique le PORT par défaut 3000 si absent', () => {
    const result = validateEnv({ ...base });
    expect(result.PORT).toBe(3000);
  });

  it('crash si une variable requise manque', () => {
    const { SUPABASE_JWT_SECRET: _omit, ...incomplete } = base;
    expect(() => validateEnv(incomplete)).toThrow(/SUPABASE_JWT_SECRET/);
  });

  it('crash si PORT est hors bornes', () => {
    expect(() => validateEnv({ ...base, PORT: '70000' })).toThrow(/PORT/);
  });
});
