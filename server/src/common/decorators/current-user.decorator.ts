import { createParamDecorator, ExecutionContext, UnauthorizedException } from '@nestjs/common';
import { Request } from 'express';

import { AuthenticatedUser } from '../auth/authenticated-user';

/**
 * Injecte l'utilisateur authentifié (posé par SupabaseAuthGuard) dans un handler.
 * À n'utiliser que sur une route protégée par @UseGuards(SupabaseAuthGuard) —
 * sinon lève UnauthorizedException plutôt que de renvoyer undefined silencieusement.
 */
export const CurrentUser = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): AuthenticatedUser => {
    const request = ctx.switchToHttp().getRequest<Request>();
    if (!request.user) {
      throw new UnauthorizedException('Aucun utilisateur authentifié sur la requête');
    }
    return request.user;
  },
);
