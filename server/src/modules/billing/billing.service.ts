import { Inject, Injectable, Logger } from '@nestjs/common';
import { eq } from 'drizzle-orm';

import { DRIZZLE, DrizzleDB } from '../../db/drizzle.provider';
import { accounts, type PremiumType } from '../../db/schema';
import {
  GRANTING_EVENT_TYPES,
  REVOKING_EVENT_TYPES,
  type RevenueCatEvent,
  type RevenueCatWebhookBody,
} from './revenuecat-webhook.types';

/**
 * Identifiant de l'entitlement RevenueCat (dashboard → Entitlements).
 * Décision actée 2026-07-09 : `pro`. Ne jamais renommer sans migrer le
 * dashboard ET le mobile en même temps.
 */
export const PRO_ENTITLEMENT_ID = 'pro';

/** Résultat d'application d'un webhook (journalisation / tests). */
export type WebhookOutcome =
  | 'applied'
  | 'ignored_event_type'
  | 'ignored_entitlement'
  | 'ignored_malformed'
  | 'skipped_stale'
  | 'no_supabase_user';

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/**
 * Applique les événements webhook RevenueCat à la projection premium de
 * `accounts`. RevenueCat reste la source de vérité : ici on ne fait que
 * refléter son état, en ne faisant JAMAIS confiance à un client.
 *
 * Idempotence/ordre : la livraison est at-least-once et potentiellement dans
 * le désordre → un événement plus ancien que `premium_updated_at` est ignoré ;
 * le rejeu du même événement réécrit le même état (inoffensif).
 */
@Injectable()
export class BillingService {
  private readonly logger = new Logger(BillingService.name);

  constructor(@Inject(DRIZZLE) private readonly db: DrizzleDB) {}

  async applyWebhook(body: RevenueCatWebhookBody | unknown): Promise<WebhookOutcome> {
    const event = (body as RevenueCatWebhookBody)?.event;
    if (!event || typeof event !== 'object' || typeof event.type !== 'string') {
      this.logger.warn('Webhook RevenueCat sans événement exploitable — ignoré');
      return 'ignored_malformed';
    }

    const grants = GRANTING_EVENT_TYPES.has(event.type);
    const revokes = REVOKING_EVENT_TYPES.has(event.type);
    if (!grants && !revokes) {
      // TEST, CANCELLATION, BILLING_ISSUE, TRANSFER, PAYWALL_*, etc. : aucun
      // changement d'accès. TRANSFER est loggé pour suivi manuel (rare).
      if (event.type === 'TRANSFER') {
        this.logger.warn(`Webhook TRANSFER reçu (non appliqué) : ${JSON.stringify(event)}`);
      } else {
        this.logger.log(`Webhook RevenueCat ${event.type} — sans effet sur l'accès`);
      }
      return 'ignored_event_type';
    }

    // Ne réagir qu'à notre entitlement. `entitlement_ids` peut être null si le
    // produit n'est pas mappé — l'app n'a qu'un entitlement, on l'accepte.
    const entitlementIds = event.entitlement_ids;
    if (Array.isArray(entitlementIds) && !entitlementIds.includes(PRO_ENTITLEMENT_ID)) {
      this.logger.warn(
        `Webhook ${event.type} pour entitlement(s) inconnu(s) [${entitlementIds.join(', ')}] — ignoré`,
      );
      return 'ignored_entitlement';
    }

    const userId = this.resolveSupabaseUserId(event);
    if (!userId) {
      this.logger.warn(
        `Webhook ${event.type} sans app user ID UUID (app_user_id=${event.app_user_id ?? '∅'}) — ignoré`,
      );
      return 'no_supabase_user';
    }

    const eventAt =
      typeof event.event_timestamp_ms === 'number' ? new Date(event.event_timestamp_ms) : new Date();

    // Garde anti-désordre : un événement plus ancien que le dernier appliqué
    // ne doit pas écraser un état plus récent.
    const [existing] = await this.db
      .select({ premiumUpdatedAt: accounts.premiumUpdatedAt })
      .from(accounts)
      .where(eq(accounts.userId, userId))
      .limit(1);
    if (existing?.premiumUpdatedAt && eventAt.getTime() < existing.premiumUpdatedAt.getTime()) {
      this.logger.log(
        `Webhook ${event.type} (${eventAt.toISOString()}) plus ancien que l'état projeté — ignoré`,
      );
      return 'skipped_stale';
    }

    const { premiumType, premiumUntil } = revokes
      ? { premiumType: 'none' as PremiumType, premiumUntil: null }
      : this.grantedState(event);

    await this.db
      .insert(accounts)
      .values({ userId, premiumType, premiumUntil, premiumUpdatedAt: eventAt })
      .onConflictDoUpdate({
        target: accounts.userId,
        set: { premiumType, premiumUntil, premiumUpdatedAt: eventAt, updatedAt: new Date() },
      });

    this.logger.log(
      `Webhook ${event.type} appliqué à ${userId} → ${premiumType}` +
        (premiumUntil ? ` (jusqu'au ${premiumUntil.toISOString()})` : '') +
        ` [${event.environment ?? '?'}/${event.store ?? '?'}]`,
    );
    return 'applied';
  }

  /** Échéance depuis l'événement : expiration présente ⇒ abonnement, absente ⇒ à vie. */
  private grantedState(event: RevenueCatEvent): {
    premiumType: PremiumType;
    premiumUntil: Date | null;
  } {
    if (typeof event.expiration_at_ms === 'number' && event.expiration_at_ms > 0) {
      return { premiumType: 'subscription', premiumUntil: new Date(event.expiration_at_ms) };
    }
    return { premiumType: 'lifetime', premiumUntil: null };
  }

  /**
   * Retrouve l'UUID Supabase du subscriber : `app_user_id` en priorité, sinon
   * parmi les aliases (un ID anonyme RevenueCat `$RCAnonymousID:` n'est jamais
   * un compte chez nous — les invités ne sont pas loggés dans RevenueCat).
   */
  private resolveSupabaseUserId(event: RevenueCatEvent): string | null {
    const candidates = [event.app_user_id, event.original_app_user_id, ...(event.aliases ?? [])];
    return candidates.find((c): c is string => typeof c === 'string' && UUID_RE.test(c)) ?? null;
  }
}
