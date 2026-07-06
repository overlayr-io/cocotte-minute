import { AuthenticatedUser } from './authenticated-user';

// Étend le type Request d'Express pour porter l'utilisateur authentifié par
// SupabaseAuthGuard, consommé ensuite par le décorateur @CurrentUser().
declare global {
  namespace Express {
    interface Request {
      user?: AuthenticatedUser;
    }
  }
}

export {};
