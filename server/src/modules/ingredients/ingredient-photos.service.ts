import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { and, asc, eq, sql } from 'drizzle-orm';

import { PremiumLimitException } from '../../common/errors/premium-limit.exception';
import { SupabaseStorageService } from '../../common/supabase/supabase-storage.service';
import { DRIZZLE, DrizzleDB } from '../../db/drizzle.provider';
import { ingredientPhotos } from '../../db/schema/ingredient-photos.schema';
import { PremiumService } from '../billing/premium.service';
import { IngredientsService } from './ingredients.service';

/** Représentation d'API d'une photo « Mes produits ». */
export interface IngredientPhotoDto {
  id: string;
  imageUrl: string;
  createdAt: string;
}

/**
 * Photos « Mes produits » (feature #14) : galerie personnelle par ingrédient,
 * distincte de l'icône (emoji/image). Sous-domaine des ingrédients, comme les
 * alternatives. Délègue la visibilité de l'ingrédient à `IngredientsService`,
 * ne touche que son propre pivot. Stockage + quota + nettoyage Storage.
 */
@Injectable()
export class IngredientPhotosService {
  /** Quota par (utilisateur, ingrédient) — plafond réel même en Pro. */
  private static readonly FREE_LIMIT = 1;
  private static readonly PRO_LIMIT = 3;

  constructor(
    @Inject(DRIZZLE) private readonly db: DrizzleDB,
    private readonly ingredientsService: IngredientsService,
    private readonly premiumService: PremiumService,
    private readonly storage: SupabaseStorageService,
  ) {}

  /** Mes photos pour cet ingrédient, les plus anciennes d'abord. */
  async list(userId: string, ingredientId: string): Promise<IngredientPhotoDto[]> {
    await this.ingredientsService.assertVisible(userId, ingredientId);
    return this.listPhotos(userId, ingredientId);
  }

  /**
   * Ajoute une photo à cet ingrédient (soumise au quota 1 gratuit / 3 Pro par
   * ingrédient). L'ingrédient doit être visible (système ou possédé).
   */
  async add(
    userId: string,
    ingredientId: string,
    imageUrl: string,
  ): Promise<IngredientPhotoDto[]> {
    await this.ingredientsService.assertVisible(userId, ingredientId);
    await this.assertQuota(userId, ingredientId);
    await this.db.insert(ingredientPhotos).values({ userId, ingredientId, imageUrl });
    return this.listPhotos(userId, ingredientId);
  }

  /** Supprime une de mes photos (+ son fichier Storage). */
  async remove(userId: string, photoId: string): Promise<void> {
    const [row] = await this.db
      .select({
        imageUrl: ingredientPhotos.imageUrl,
      })
      .from(ingredientPhotos)
      .where(
        and(eq(ingredientPhotos.id, photoId), eq(ingredientPhotos.userId, userId)),
      );
    if (!row) throw new NotFoundException('Photo introuvable');

    await this.db.delete(ingredientPhotos).where(eq(ingredientPhotos.id, photoId));
    await this.storage.removeByPublicUrls([row.imageUrl]);
  }

  private async listPhotos(
    userId: string,
    ingredientId: string,
  ): Promise<IngredientPhotoDto[]> {
    const rows = await this.db
      .select({
        id: ingredientPhotos.id,
        imageUrl: ingredientPhotos.imageUrl,
        createdAt: ingredientPhotos.createdAt,
      })
      .from(ingredientPhotos)
      .where(
        and(
          eq(ingredientPhotos.userId, userId),
          eq(ingredientPhotos.ingredientId, ingredientId),
        ),
      )
      .orderBy(asc(ingredientPhotos.createdAt));
    return rows.map((r) => ({
      id: r.id,
      imageUrl: r.imageUrl,
      createdAt: r.createdAt.toISOString(),
    }));
  }

  /** Garde de quota (vérifiée serveur, jamais uniquement UI). */
  private async assertQuota(userId: string, ingredientId: string): Promise<void> {
    const [row] = await this.db
      .select({ n: sql<number>`count(*)::int` })
      .from(ingredientPhotos)
      .where(
        and(
          eq(ingredientPhotos.userId, userId),
          eq(ingredientPhotos.ingredientId, ingredientId),
        ),
      );
    const current = row?.n ?? 0;
    const isPremium = await this.premiumService.isPremium(userId);
    const limit = isPremium
      ? IngredientPhotosService.PRO_LIMIT
      : IngredientPhotosService.FREE_LIMIT;
    if (current < limit) return;
    throw new PremiumLimitException(
      'PREMIUM_LIMIT_INGREDIENT_PHOTOS',
      limit,
      current,
      `Limite de ${limit} photo(s) de produit atteinte pour cet ingrédient. Passe en Pro pour en ajouter plus.`,
    );
  }
}
