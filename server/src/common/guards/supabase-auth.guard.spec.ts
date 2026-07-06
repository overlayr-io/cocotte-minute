import { ExecutionContext, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Request } from 'express';
import { SignJWT } from 'jose';

import { SupabaseAuthGuard } from './supabase-auth.guard';

const JWT_SECRET = 'test-secret-with-at-least-32-characters-long';

function makeContext(request: Partial<Request>): ExecutionContext {
  return {
    switchToHttp: () => ({
      getRequest: () => request as Request,
    }),
  } as ExecutionContext;
}

async function signToken(
  claims: Record<string, unknown>,
  { expired = false }: { expired?: boolean } = {},
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  return new SignJWT(claims)
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt(now)
    .setExpirationTime(expired ? now - 60 : now + 3600)
    .sign(new TextEncoder().encode(JWT_SECRET));
}

describe('SupabaseAuthGuard', () => {
  let guard: SupabaseAuthGuard;

  beforeEach(() => {
    const config = { getOrThrow: () => JWT_SECRET } as unknown as ConfigService;
    guard = new SupabaseAuthGuard(config);
  });

  it('accepte un JWT valide et attache un AuthenticatedUser normalisé', async () => {
    const token = await signToken({
      sub: 'user-uuid-123',
      email: 'chef@cocotte.fr',
      role: 'authenticated',
    });
    const request = { headers: { authorization: `Bearer ${token}` } } as Request;

    await expect(guard.canActivate(makeContext(request))).resolves.toBe(true);
    expect(request.user).toEqual({
      id: 'user-uuid-123',
      email: 'chef@cocotte.fr',
      role: 'authenticated',
      isAnonymous: false,
    });
  });

  it('marque isAnonymous à partir du claim is_anonymous', async () => {
    const token = await signToken({ sub: 'anon-1', is_anonymous: true, role: 'anon' });
    const request = { headers: { authorization: `Bearer ${token}` } } as Request;

    await guard.canActivate(makeContext(request));
    expect(request.user?.isAnonymous).toBe(true);
  });

  it('rejette une requête sans header Authorization', async () => {
    const request = { headers: {} } as Request;
    await expect(guard.canActivate(makeContext(request))).rejects.toThrow(UnauthorizedException);
  });

  it('rejette un schéma non-Bearer', async () => {
    const request = { headers: { authorization: 'Basic abc' } } as Request;
    await expect(guard.canActivate(makeContext(request))).rejects.toThrow(UnauthorizedException);
  });

  it('rejette un token signé avec un mauvais secret', async () => {
    const token = await new SignJWT({ sub: 'x' })
      .setProtectedHeader({ alg: 'HS256' })
      .sign(new TextEncoder().encode('un-autre-secret-totalement-different-32c'));
    const request = { headers: { authorization: `Bearer ${token}` } } as Request;

    await expect(guard.canActivate(makeContext(request))).rejects.toThrow(UnauthorizedException);
  });

  it('rejette un token expiré', async () => {
    const token = await signToken({ sub: 'x' }, { expired: true });
    const request = { headers: { authorization: `Bearer ${token}` } } as Request;

    await expect(guard.canActivate(makeContext(request))).rejects.toThrow(UnauthorizedException);
  });

  it('rejette un token sans claim sub', async () => {
    const token = await signToken({ email: 'no-sub@cocotte.fr' });
    const request = { headers: { authorization: `Bearer ${token}` } } as Request;

    await expect(guard.canActivate(makeContext(request))).rejects.toThrow(UnauthorizedException);
  });
});
