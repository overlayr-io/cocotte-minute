import { pgEnum, pgTable, timestamp, uuid } from 'drizzle-orm/pg-core';

/**
 * Statut RGPD d'un compte (cf. features/auth.md — « Suppression de compte »).
 * - `active`           : compte normal.
 * - `pending_deletion` : anonymisé, en attente du délai de 30 jours (rollback possible).
 * - `deleted`          : suppression cascade définitive effectuée (état terminal).
 * Valeurs stockées = identifiants stables (jamais un libellé i18n).
 */
export const ACCOUNT_STATUSES = ['active', 'pending_deletion', 'deleted'] as const;

export type AccountStatus = (typeof ACCOUNT_STATUSES)[number];

export const accountStatusEnum = pgEnum('account_status', ACCOUNT_STATUSES);

/**
 * Type d'accès premium (cf. features/premium-version.md).
 * - `none`         : compte gratuit (défaut).
 * - `subscription` : abonnement Pro actif (mensuel ou annuel), borné par `premiumUntil`.
 * - `lifetime`     : achat à vie (prévu, produit store non créé dans ce v1) — sans échéance.
 * Projection de l'état RevenueCat (source de vérité), mise à jour par webhook.
 */
export const PREMIUM_TYPES = ['none', 'subscription', 'lifetime'] as const;

export type PremiumType = (typeof PREMIUM_TYPES)[number];

export const premiumTypeEnum = pgEnum('premium_type', PREMIUM_TYPES);

/**
 * Table minimale de gestion de cycle de vie du compte.
 *
 * L'authentification reste 100 % gérée par Supabase Auth (aucune table d'auth
 * custom, cf. auth.md). Cette table ne porte QUE l'état RGPD nécessaire au
 * server : le statut de suppression et l'horodatage de la demande, indexés sur
 * le `userId` Supabase (claim `sub`). La ligne est créée à la volée à la
 * première opération qui en a besoin (demande de suppression) — pas de trigger
 * de provisioning au signup.
 */
export const accounts = pgTable('accounts', {
  /** UUID Supabase (claim `sub`) — clé de rattachement de tout le contenu utilisateur. */
  userId: uuid('user_id').primaryKey(),
  status: accountStatusEnum('account_status').notNull().default('active'),
  /** Horodatage de la demande de suppression, sert au calcul de l'échéance 30 j. */
  deletionRequestedAt: timestamp('deletion_requested_at', { withTimezone: true }),
  /** Projection du statut premium RevenueCat (jamais modifiée par le client). */
  premiumType: premiumTypeEnum('premium_type').notNull().default('none'),
  /**
   * Fin de la période courante (null pour `lifetime` et `none`). Permet
   * d'appliquer l'expiration côté server même si un webhook EXPIRATION se perd.
   */
  premiumUntil: timestamp('premium_until', { withTimezone: true }),
  /** Horodatage du dernier événement RevenueCat appliqué (idempotence webhook). */
  premiumUpdatedAt: timestamp('premium_updated_at', { withTimezone: true }),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
});

export type AccountRow = typeof accounts.$inferSelect;
export type NewAccountRow = typeof accounts.$inferInsert;
