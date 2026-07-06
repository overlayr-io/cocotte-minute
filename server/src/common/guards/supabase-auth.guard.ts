import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Request } from 'express';
import { jwtVerify } from 'jose';

import { AuthenticatedUser } from '../auth/authenticated-user';

/**
 * Guard unique de vérification d'authentification. Seul endroit du serveur qui
 * connaît le format du JWT Supabase : il vérifie la signature HS256 avec
 * SUPABASE_JWT_SECRET puis attache un AuthenticatedUser normalisé à la requête.
 *
 * NB : NestJS ne fait QUE vérifier le token — aucune logique d'auth custom, pas de
 * Passport. L'émission des tokens reste 100% côté Supabase.
 */
@Injectable()
export class SupabaseAuthGuard implements CanActivate {
  private readonly secret: Uint8Array;

  constructor(config: ConfigService) {
    this.secret = new TextEncoder().encode(config.getOrThrow<string>('SUPABASE_JWT_SECRET'));
  }

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<Request>();
    const token = this.extractBearerToken(request);
    if (!token) {
      throw new UnauthorizedException('Token Bearer manquant');
    }

    try {
      const { payload } = await jwtVerify(token, this.secret, {
        algorithms: ['HS256'],
      });

      if (!payload.sub) {
        throw new UnauthorizedException('Token sans identifiant utilisateur');
      }

      const user: AuthenticatedUser = {
        id: payload.sub,
        email: typeof payload.email === 'string' ? payload.email : undefined,
        role: typeof payload.role === 'string' ? payload.role : undefined,
        isAnonymous: payload.is_anonymous === true,
      };
      request.user = user;
      return true;
    } catch (err) {
      if (err instanceof UnauthorizedException) {
        throw err;
      }
      throw new UnauthorizedException('Token invalide ou expiré');
    }
  }

  private extractBearerToken(request: Request): string | null {
    const header = request.headers.authorization;
    if (!header) {
      return null;
    }
    const [scheme, value] = header.split(' ');
    return scheme?.toLowerCase() === 'bearer' && value ? value : null;
  }
}
