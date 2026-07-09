import { createHash, timingSafeEqual } from 'node:crypto';

import {
  Body,
  Controller,
  Headers,
  HttpCode,
  Post,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import { BillingService } from './billing.service';

/**
 * Endpoint serveur-à-serveur des webhooks RevenueCat. PAS de SupabaseAuthGuard :
 * l'appelant n'est pas un utilisateur mais RevenueCat, authentifié par le header
 * `Authorization` statique configuré à l'identique dans le dashboard (doc
 * integrations/webhooks). Répond 200 rapidement (timeout RevenueCat : 60 s,
 * retries : 5/10/20/40/80 min sur tout code ≠ 200).
 */
@Controller('billing')
export class BillingController {
  private readonly webhookSecret: string;

  constructor(
    private readonly billingService: BillingService,
    config: ConfigService,
  ) {
    this.webhookSecret = config.getOrThrow<string>('REVENUECAT_WEBHOOK_SECRET');
  }

  @Post('revenuecat')
  @HttpCode(200)
  async revenueCatWebhook(
    @Headers('authorization') authorization: string | undefined,
    // Pas de DTO class-validator : RevenueCat ajoute des champs sans préavis,
    // le whitelist global rejetterait des payloads légitimes (parsing défensif
    // dans BillingService).
    @Body() body: Record<string, unknown>,
  ): Promise<{ received: true }> {
    if (!authorization || !this.safeEquals(authorization, this.webhookSecret)) {
      throw new UnauthorizedException('Webhook RevenueCat : Authorization invalide');
    }
    await this.billingService.applyWebhook(body);
    return { received: true };
  }

  /** Comparaison en temps constant (hash préalable : longueurs inégales). */
  private safeEquals(a: string, b: string): boolean {
    const ha = createHash('sha256').update(a).digest();
    const hb = createHash('sha256').update(b).digest();
    return timingSafeEqual(ha, hb);
  }
}
