/**
 * Typage DÉFENSIF du webhook RevenueCat (`{ api_version, event }`).
 *
 * La doc officielle (integrations/webhooks) prévient que de nouveaux champs et
 * types d'événements peuvent apparaître sans changement de version : tous les
 * champs sont donc optionnels et le parsing ne rejette jamais un payload
 * inconnu (on répond 200 et on ignore). Pas de DTO class-validator ici — le
 * ValidationPipe global (whitelist) supprimerait les champs non déclarés.
 */
export interface RevenueCatWebhookBody {
  api_version?: string;
  event?: RevenueCatEvent;
}

export interface RevenueCatEvent {
  /** Type d'événement (INITIAL_PURCHASE, RENEWAL, EXPIRATION, ...). */
  type?: string;
  /** Id unique — identique entre retries du même événement (idempotence). */
  id?: string;
  event_timestamp_ms?: number;
  app_id?: string;
  /** Dernier app user ID vu (notre UUID Supabase après logIn). */
  app_user_id?: string;
  /** Premier ID jamais vu (peut être un $RCAnonymousID). */
  original_app_user_id?: string;
  /** Tous les IDs connus du subscriber — on y cherche l'UUID Supabase. */
  aliases?: string[];
  /** Entitlements concernés — null si le produit n'est pas mappé. */
  entitlement_ids?: string[] | null;
  product_id?: string;
  /** TRIAL | INTRO | NORMAL | PROMOTIONAL | PREPAID */
  period_type?: string;
  purchased_at_ms?: number;
  /** Fin de période — null pour les achats non-abonnement (lifetime). */
  expiration_at_ms?: number | null;
  /** SANDBOX | PRODUCTION */
  environment?: string;
  store?: string;
  cancel_reason?: string;
  expiration_reason?: string;
  new_product_id?: string;
}

/**
 * Événements qui accordent/prolongent l'accès (cf. doc « grant/revoke ») :
 * l'échéance vient de `expiration_at_ms` ; null ⇒ achat à vie.
 */
export const GRANTING_EVENT_TYPES: ReadonlySet<string> = new Set([
  'INITIAL_PURCHASE',
  'RENEWAL',
  'UNCANCELLATION',
  'PRODUCT_CHANGE',
  'SUBSCRIPTION_EXTENDED',
  'NON_RENEWING_PURCHASE',
]);

/**
 * Seul EXPIRATION retire l'accès. CANCELLATION (auto-renew désactivé),
 * BILLING_ISSUE (période de grâce) et SUBSCRIPTION_PAUSED ne changent PAS
 * l'accès : l'EXPIRATION correspondante arrivera le moment venu, et
 * `premium_until` borne de toute façon l'accès côté PremiumService.
 */
export const REVOKING_EVENT_TYPES: ReadonlySet<string> = new Set(['EXPIRATION']);
