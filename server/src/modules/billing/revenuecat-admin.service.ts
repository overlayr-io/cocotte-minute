import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

/**
 * Encapsule l'API REST v1 de RevenueCat (miroir de SupabaseAdminService) :
 * seule classe du serveur qui parle à api.revenuecat.com.
 *
 * Utilisée uniquement pour la suppression RGPD du subscriber
 * (DELETE /v1/subscribers/{app_user_id} — exige une clé secrète `sk_`).
 * Best-effort : erreur journalisée, jamais propagée — la purge RGPD côté DB
 * doit aboutir même si RevenueCat est indisponible ou la clé absente.
 */
@Injectable()
export class RevenueCatAdminService {
  private readonly logger = new Logger(RevenueCatAdminService.name);
  private readonly apiKey: string | undefined;

  constructor(config: ConfigService) {
    this.apiKey = config.get<string>('REVENUECAT_API_KEY');
  }

  async deleteSubscriber(userId: string): Promise<void> {
    if (!this.apiKey) {
      this.logger.warn(
        `REVENUECAT_API_KEY absente : suppression RevenueCat du subscriber ${userId} ignorée (à faire manuellement si le compte était abonné)`,
      );
      return;
    }
    const url = `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(userId)}`;
    try {
      const res = await fetch(url, {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${this.apiKey}` },
      });
      if (res.ok) {
        this.logger.log(`Subscriber RevenueCat ${userId} supprimé (RGPD)`);
      } else if (res.status === 404) {
        // Jamais loggé dans RevenueCat (compte invité, jamais abonné) : rien à faire.
        this.logger.log(`Subscriber RevenueCat ${userId} inexistant — rien à supprimer`);
      } else {
        const detail = await res.text().catch(() => '');
        this.logger.warn(
          `Suppression RevenueCat du subscriber ${userId} échouée (${res.status}) : ${detail}`,
        );
      }
    } catch (err) {
      this.logger.warn(`API RevenueCat injoignable pour ${userId} : ${String(err)}`);
    }
  }
}
