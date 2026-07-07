import { ConflictException, Inject, Injectable, Logger } from '@nestjs/common';
import { and, eq, lt } from 'drizzle-orm';

import { AuthenticatedUser } from '../../common/auth/authenticated-user';
import { SupabaseAdminService } from '../../common/supabase/supabase-admin.service';
import { DRIZZLE, DrizzleDB } from '../../db/drizzle.provider';
import { accounts, type AccountRow, type AccountStatus } from '../../db/schema/accounts.schema';
import { CategoriesService } from '../categories/categories.service';
import { IngredientsService } from '../ingredients/ingredients.service';
import { PeopleService } from '../people/people.service';
import { RecipesService } from '../recipes/recipes.service';
import { ShoppingListsService } from '../shopping-lists/shopping-lists.service';
import { TagsService } from '../tags/tags.service';

/** Délai de rollback avant suppression définitive (RGPD, cf. auth.md). */
export const DELETION_DELAY_DAYS = 30;

/** Réponse de `POST /account/request-deletion`. */
export interface RequestDeletionResult {
  /** Statut atteint : `deleted` (compte anonyme, immédiat) ou `pending_deletion`. */
  status: Extract<AccountStatus, 'deleted' | 'pending_deletion'>;
  /** true si le compte était anonyme (wipe immédiat, sans délai). */
  anonymous: boolean;
  /** Échéance ISO de la suppression définitive (null si déjà supprimé). */
  deletionScheduledAt: string | null;
}

/** Réponse de `POST /account/cancel-deletion`. */
export interface CancelDeletionResult {
  status: Extract<AccountStatus, 'active'>;
}

@Injectable()
export class AccountService {
  private readonly logger = new Logger(AccountService.name);

  constructor(
    @Inject(DRIZZLE) private readonly db: DrizzleDB,
    private readonly ingredientsService: IngredientsService,
    private readonly tagsService: TagsService,
    private readonly peopleService: PeopleService,
    private readonly categoriesService: CategoriesService,
    private readonly recipesService: RecipesService,
    private readonly shoppingListsService: ShoppingListsService,
    private readonly supabaseAdmin: SupabaseAdminService,
  ) {}

  /**
   * "Repartir de zéro" (cf. auth.md) : purge le contenu de l'utilisateur courant,
   * le compte Supabase Auth étant conservé (la conversion a déjà eu lieu côté mobile).
   * Réutilise la même cascade que la suppression RGPD (DRY).
   */
  async resetGuestData(userId: string): Promise<void> {
    await this.purgeAllUserData(userId);
    this.logger.log(`Données invité réinitialisées pour l'utilisateur ${userId}`);
  }

  /**
   * Demande de suppression de compte (RGPD).
   *
   * - Compte **anonyme** (jamais lié à email/OAuth) : aucune donnée identifiante,
   *   donc **suppression immédiate** — wipe cascade complet maintenant, statut
   *   `deleted`, et suppression de l'utilisateur Supabase Auth (best-effort).
   * - Compte **complet** (email/OAuth) : **anonymisation immédiate** des données
   *   identifiantes (côté Supabase Auth) + statut `pending_deletion` + horodatage,
   *   ouvrant le délai de 30 jours (rollback possible). Les données métier restent
   *   en base pour permettre l'annulation.
   */
  async requestDeletion(user: AuthenticatedUser): Promise<RequestDeletionResult> {
    const account = await this.ensureAccount(user.id);
    if (account.status !== 'active') {
      throw new ConflictException('Une suppression est déjà en cours ou effectuée');
    }

    if (user.isAnonymous) {
      // Compte anonyme → purge cascade complète immédiate.
      await this.purgeAllUserData(user.id);
      await this.markStatus(user.id, 'deleted', null);
      await this.supabaseAdmin.deleteAuthUser(user.id);
      this.logger.log(`Compte anonyme ${user.id} supprimé immédiatement (RGPD)`);
      return { status: 'deleted', anonymous: true, deletionScheduledAt: null };
    }

    // Compte complet → anonymisation + délai de 30 jours.
    const requestedAt = new Date();
    await this.supabaseAdmin.anonymizeAuthUser(user.id);
    await this.markStatus(user.id, 'pending_deletion', requestedAt);
    this.logger.log(
      `Compte ${user.id} anonymisé, suppression définitive planifiée à J+${DELETION_DELAY_DAYS} (RGPD)`,
    );
    return {
      status: 'pending_deletion',
      anonymous: false,
      deletionScheduledAt: this.deadlineFrom(requestedAt).toISOString(),
    };
  }

  /**
   * Annule une suppression en attente tant que le compte est `pending_deletion`
   * ET que le délai de 30 jours n'est pas dépassé → repasse `active`.
   */
  async cancelDeletion(userId: string): Promise<CancelDeletionResult> {
    const account = await this.ensureAccount(userId);
    if (account.status !== 'pending_deletion' || !account.deletionRequestedAt) {
      throw new ConflictException("Aucune suppression en attente d'annulation");
    }
    if (this.deadlineFrom(account.deletionRequestedAt).getTime() <= Date.now()) {
      throw new ConflictException('Le délai de 30 jours est dépassé, suppression irréversible');
    }
    await this.markStatus(userId, 'active', null);
    this.logger.log(`Suppression du compte ${userId} annulée (RGPD)`);
    return { status: 'active' };
  }

  /**
   * Suppression définitive des comptes `pending_deletion` dont le délai de 30 jours
   * est dépassé. Appelé quotidiennement par le CRON. Retourne le nombre de comptes
   * traités (utile pour les logs / tests).
   */
  async purgeExpiredDeletions(): Promise<number> {
    const deadline = new Date(Date.now() - DELETION_DELAY_DAYS * 24 * 60 * 60 * 1000);
    const expired = await this.db
      .select()
      .from(accounts)
      .where(
        and(eq(accounts.status, 'pending_deletion'), lt(accounts.deletionRequestedAt, deadline)),
      );

    for (const account of expired) {
      await this.purgeAllUserData(account.userId);
      await this.markStatus(account.userId, 'deleted', null);
      await this.supabaseAdmin.deleteAuthUser(account.userId);
      this.logger.log(`Compte ${account.userId} supprimé définitivement (CRON RGPD)`);
    }
    if (expired.length > 0) {
      this.logger.log(`${expired.length} compte(s) supprimé(s) définitivement (CRON RGPD)`);
    }
    return expired.length;
  }

  // --- privé ---------------------------------------------------------------

  /**
   * Purge cascade COMPLÈTE de toutes les données métier d'un utilisateur, chaque
   * domaine étant délégué à son service exporté (jamais son schéma). Point unique
   * réutilisé par : "repartir de zéro", wipe anonyme immédiat, et CRON J+30 (DRY).
   *
   * Ordre important : les domaines qui référencent d'autres (listes de courses →
   * recettes/ingrédients ; recettes → ingrédients/tags/catégories ; personnes →
   * tags) sont purgés d'abord pour que leurs pivots partent en cascade avant les
   * domaines référencés.
   */
  private async purgeAllUserData(userId: string): Promise<void> {
    await this.shoppingListsService.deleteAllForUser(userId);
    await this.recipesService.deleteAllForUser(userId);
    await this.peopleService.deleteAllForUser(userId);
    await this.ingredientsService.deleteAllForUser(userId);
    await this.tagsService.deleteAllForUser(userId);
    await this.categoriesService.deleteAllForUser(userId);
  }

  /** Charge la ligne `accounts` du user, la créant `active` si absente. */
  private async ensureAccount(userId: string): Promise<AccountRow> {
    await this.db.insert(accounts).values({ userId }).onConflictDoNothing();
    const [row] = await this.db.select().from(accounts).where(eq(accounts.userId, userId));
    return row;
  }

  private async markStatus(
    userId: string,
    status: AccountStatus,
    deletionRequestedAt: Date | null,
  ): Promise<void> {
    await this.db
      .update(accounts)
      .set({ status, deletionRequestedAt, updatedAt: new Date() })
      .where(eq(accounts.userId, userId));
  }

  private deadlineFrom(requestedAt: Date): Date {
    return new Date(requestedAt.getTime() + DELETION_DELAY_DAYS * 24 * 60 * 60 * 1000);
  }
}
