import {
  BadRequestException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { and, asc, eq, gte, inArray, lt, sql } from 'drizzle-orm';

import { PremiumLimitException } from '../../common/errors/premium-limit.exception';
import { DRIZZLE, DrizzleDB } from '../../db/drizzle.provider';
import {
  MealEntryType,
  mealPlanEntries,
  MealPlanEntryRow,
  MealSlot,
} from '../../db/schema/meal-plan.schema';
import { PremiumService } from '../billing/premium.service';
import { RecipeSummaryDto, RecipesService } from '../recipes/recipes.service';
import { CreateMealPlanEntryDto } from './dto/create-meal-plan-entry.dto';
import { addDays, isMonday, mealPlanWindow } from './week-window';

/** Entrée de planning hydratée pour le mobile. `recipe` null hors type `recipe`. */
export interface MealPlanEntryDto {
  id: string;
  day: string;
  slot: MealSlot;
  entryType: MealEntryType;
  recipe: RecipeSummaryDto | null;
  noteText: string | null;
  position: number;
}

/**
 * Planning de repas (cf. features/planification-repas.md). Planning global au
 * compte, semaine calendaire lundi → dimanche, 3 créneaux/jour.
 *
 * Rétention T-1 → T+2 purgée en **lazy** à chaque lecture/écriture (pas de
 * cron : Render free tier s'endort). Gardes serveur (jamais uniquement UI) :
 * - gratuit : écriture bornée à T/T+1 (`PREMIUM_LIMIT_MEAL_PLAN_WEEK`) ;
 * - gratuit : 1 entrée max par créneau, tous types confondus
 *   (`PREMIUM_LIMIT_MEAL_SLOT_ENTRIES`).
 */
@Injectable()
export class MealPlanService {
  private static readonly FREE_SLOT_LIMIT = 1;
  private static readonly FREE_WEEKS_LIMIT = 2;

  constructor(
    @Inject(DRIZZLE) private readonly db: DrizzleDB,
    private readonly recipesService: RecipesService,
    private readonly premiumService: PremiumService,
  ) {}

  /**
   * Entrées de la semaine commençant à `weekStart` (un lundi). Hors fenêtre de
   * rétention → liste vide (le mobile borne déjà la navigation ; pas d'erreur
   * pour rester tolérant au changement de semaine pendant une session).
   *
   * Cascade lazy des recettes soft-supprimées : la FK ne joue que sur les hard
   * deletes, donc les entrées dont la recette n'est plus résoluble sont
   * supprimées ici et exclues de la réponse.
   */
  async listWeek(userId: string, weekStart: string): Promise<MealPlanEntryDto[]> {
    this.assertDayFormat(weekStart);
    if (!isMonday(weekStart)) {
      throw new BadRequestException('weekStart doit être un lundi (YYYY-MM-DD)');
    }
    await this.purgeExpired(userId);

    const w = mealPlanWindow();
    if (weekStart < w.retentionStart || weekStart >= w.retentionEndExclusive) {
      return [];
    }

    const rows = await this.db
      .select()
      .from(mealPlanEntries)
      .where(
        and(
          eq(mealPlanEntries.ownerId, userId),
          gte(mealPlanEntries.day, weekStart),
          lt(mealPlanEntries.day, addDays(weekStart, 7)),
        ),
      )
      .orderBy(asc(mealPlanEntries.day), asc(mealPlanEntries.position));

    const recipeIds = rows
      .map((r) => r.recipeId)
      .filter((id): id is string => id !== null);
    const summaries = await this.recipesService.listByIds(userId, recipeIds);
    const byId = new Map(summaries.map((s) => [s.id, s]));

    // Recette soft-supprimée depuis → l'entrée disparaît du planning (cascade).
    const orphans = rows.filter(
      (r) => r.entryType === 'recipe' && r.recipeId !== null && !byId.has(r.recipeId),
    );
    if (orphans.length > 0) {
      await this.db.delete(mealPlanEntries).where(
        inArray(
          mealPlanEntries.id,
          orphans.map((o) => o.id),
        ),
      );
    }
    const orphanIds = new Set(orphans.map((o) => o.id));

    return rows
      .filter((r) => !orphanIds.has(r.id))
      .map((r) => this.toDto(r, byId));
  }

  /** Ajoute une entrée sur un créneau (gardes fenêtre + quota créneau). */
  async addEntry(userId: string, dto: CreateMealPlanEntryDto): Promise<MealPlanEntryDto> {
    await this.purgeExpired(userId);
    const isPremium = await this.premiumService.isPremium(userId);
    this.assertWritableDay(dto.day, isPremium);

    let recipe: RecipeSummaryDto | null = null;
    if (dto.entryType === 'recipe') {
      const [summary] = await this.recipesService.listByIds(userId, [dto.recipeId!]);
      if (!summary) throw new NotFoundException('Recette introuvable');
      recipe = summary;
    }

    const [countRow] = await this.db
      .select({ n: sql<number>`count(*)::int` })
      .from(mealPlanEntries)
      .where(
        and(
          eq(mealPlanEntries.ownerId, userId),
          eq(mealPlanEntries.day, dto.day),
          eq(mealPlanEntries.slot, dto.slot),
        ),
      );
    const current = countRow?.n ?? 0;
    if (!isPremium && current >= MealPlanService.FREE_SLOT_LIMIT) {
      throw new PremiumLimitException(
        'PREMIUM_LIMIT_MEAL_SLOT_ENTRIES',
        MealPlanService.FREE_SLOT_LIMIT,
        current,
        'En gratuit, chaque créneau accueille une seule entrée.',
      );
    }

    const [row] = await this.db
      .insert(mealPlanEntries)
      .values({
        ownerId: userId,
        day: dto.day,
        slot: dto.slot,
        entryType: dto.entryType,
        recipeId: dto.entryType === 'recipe' ? dto.recipeId! : null,
        noteText: dto.entryType === 'note' ? dto.noteText! : null,
        position: current,
      })
      .returning();

    return this.toDto(row, recipe ? new Map([[recipe.id, recipe]]) : new Map());
  }

  /** Retire une entrée d'un créneau (même fenêtre d'écriture que l'ajout). */
  async removeEntry(userId: string, entryId: string): Promise<void> {
    const [row] = await this.db
      .select()
      .from(mealPlanEntries)
      .where(and(eq(mealPlanEntries.id, entryId), eq(mealPlanEntries.ownerId, userId)));
    if (!row) throw new NotFoundException('Entrée de planning introuvable');

    const isPremium = await this.premiumService.isPremium(userId);
    this.assertWritableDay(row.day, isPremium);

    await this.db.delete(mealPlanEntries).where(eq(mealPlanEntries.id, entryId));
  }

  /** Purge cascade RGPD / "repartir de zéro" (appelée par AccountService). */
  async deleteAllForUser(userId: string): Promise<void> {
    await this.db.delete(mealPlanEntries).where(eq(mealPlanEntries.ownerId, userId));
  }

  // --- privé ---------------------------------------------------------------

  /** Purge lazy : supprime les entrées de l'utilisateur sorties de la rétention. */
  private async purgeExpired(userId: string): Promise<void> {
    const w = mealPlanWindow();
    await this.db
      .delete(mealPlanEntries)
      .where(
        and(
          eq(mealPlanEntries.ownerId, userId),
          lt(mealPlanEntries.day, w.retentionStart),
        ),
      );
  }

  /**
   * Garde d'écriture : hors rétention → 400 ; dans la rétention mais hors
   * fenêtre gratuite (T/T+1) pour un compte gratuit → 403 upsell.
   */
  private assertWritableDay(day: string, isPremium: boolean): void {
    this.assertDayFormat(day);
    const w = mealPlanWindow();
    if (day < w.retentionStart || day >= w.retentionEndExclusive) {
      throw new BadRequestException('Jour hors de la fenêtre de planification');
    }
    if (isPremium) return;
    if (day < w.freeWriteStart || day >= w.freeWriteEndExclusive) {
      throw new PremiumLimitException(
        'PREMIUM_LIMIT_MEAL_PLAN_WEEK',
        MealPlanService.FREE_WEEKS_LIMIT,
        MealPlanService.FREE_WEEKS_LIMIT,
        'En gratuit, le planning s’édite sur la semaine en cours et la suivante.',
      );
    }
  }

  private assertDayFormat(day: string): void {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(day)) {
      throw new BadRequestException('Jour invalide (attendu YYYY-MM-DD)');
    }
  }

  private toDto(row: MealPlanEntryRow, byId: Map<string, RecipeSummaryDto>): MealPlanEntryDto {
    return {
      id: row.id,
      day: row.day,
      slot: row.slot,
      entryType: row.entryType,
      recipe: row.recipeId ? (byId.get(row.recipeId) ?? null) : null,
      noteText: row.noteText,
      position: row.position,
    };
  }
}
