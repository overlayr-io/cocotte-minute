import { Inject, Injectable } from '@nestjs/common';
import { eq } from 'drizzle-orm';

import { DRIZZLE, DrizzleDB } from '../../db/drizzle.provider';
import { accounts } from '../../db/schema';

/**
 * Lecture du statut premium (projection locale de RevenueCat, cf.
 * features/premium-version.md). Ne fait QUE lire : l'écriture passe
 * exclusivement par le webhook RevenueCat (BillingService), jamais par
 * une valeur envoyée par le client.
 */
@Injectable()
export class PremiumService {
  constructor(@Inject(DRIZZLE) private readonly db: DrizzleDB) {}

  /**
   * `true` si le compte a un accès premium actif :
   * `lifetime` sans échéance, ou `subscription` dont `premiumUntil` est dans
   * le futur — la borne temporelle est vérifiée ici même si un webhook
   * EXPIRATION s'est perdu.
   */
  async isPremium(userId: string): Promise<boolean> {
    const [row] = await this.db
      .select({
        premiumType: accounts.premiumType,
        premiumUntil: accounts.premiumUntil,
      })
      .from(accounts)
      .where(eq(accounts.userId, userId))
      .limit(1);

    if (!row || row.premiumType === 'none') return false;
    if (row.premiumType === 'lifetime') return true;
    return row.premiumUntil !== null && row.premiumUntil.getTime() > Date.now();
  }
}
