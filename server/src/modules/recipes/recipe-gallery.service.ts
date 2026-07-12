import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { and, asc, eq, sql } from 'drizzle-orm';

import { PremiumLimitException } from '../../common/errors/premium-limit.exception';
import { SupabaseStorageService } from '../../common/supabase/supabase-storage.service';
import { DRIZZLE, DrizzleDB } from '../../db/drizzle.provider';
import { recipeGalleryImages } from '../../db/schema/recipe-gallery.schema';
import { PremiumService } from '../billing/premium.service';
import type { RecipeGalleryPhotoDto } from './recipes.service';
import { RecipesService } from './recipes.service';

/**
 * Résultat d'un ajout de photo. Si [becameCover] est vrai, la photo n'a PAS été
 * insérée en galerie : elle est devenue la couverture de la recette (mécanisme
 * « 1er upload = couverture » quand la recette n'avait pas de photo), et sort
 * donc du quota galerie. [coverUrl] n'est renseignée que dans ce cas.
 */
export interface AddGalleryResult {
  becameCover: boolean;
  coverUrl: string | null;
  photos: RecipeGalleryPhotoDto[];
}

/**
 * Photos de galerie d'une recette (feature galerie-recette). Sous-domaine des
 * recettes (au même titre que les étapes/composants) : délègue l'ownership et le
 * mécanisme de couverture à `RecipesService`, ne touche que son propre pivot.
 * Aucun calcul métier lourd — stockage + quota + nettoyage Storage.
 */
@Injectable()
export class RecipeGalleryService {
  /** Quota par recette (indépendant du nombre total de recettes de l'utilisateur). */
  private static readonly FREE_LIMIT = 3;
  private static readonly PRO_LIMIT = 6;

  constructor(
    @Inject(DRIZZLE) private readonly db: DrizzleDB,
    private readonly recipesService: RecipesService,
    private readonly premiumService: PremiumService,
    private readonly storage: SupabaseStorageService,
  ) {}

  /** Photos de la recette (propriétaire uniquement), les plus anciennes d'abord. */
  async list(userId: string, recipeId: string): Promise<RecipeGalleryPhotoDto[]> {
    await this.recipesService.assertOwnedRecipe(userId, recipeId);
    return this.listPhotos(recipeId);
  }

  /**
   * Ajoute une photo. Si la recette n'a aucune couverture, la photo la devient
   * (hors quota) au lieu d'entrer en galerie. Sinon, insertion soumise au quota
   * (3 gratuit / 6 Pro par recette — plafond réel même en Pro).
   */
  async add(userId: string, recipeId: string, imageUrl: string): Promise<AddGalleryResult> {
    await this.recipesService.assertOwnedRecipe(userId, recipeId);

    const becameCover = await this.recipesService.setPhotoIfEmpty(recipeId, imageUrl);
    if (becameCover) {
      return { becameCover: true, coverUrl: imageUrl, photos: await this.listPhotos(recipeId) };
    }

    await this.assertQuota(userId, recipeId);
    await this.db.insert(recipeGalleryImages).values({ recipeId, imageUrl });
    return { becameCover: false, coverUrl: null, photos: await this.listPhotos(recipeId) };
  }

  /**
   * Supprime une photo de galerie et son fichier Storage. Ne touche jamais la
   * couverture (le remplacement de couverture passe par `PATCH /recipes/:id`).
   */
  async remove(
    userId: string,
    recipeId: string,
    imageId: string,
  ): Promise<{ photos: RecipeGalleryPhotoDto[] }> {
    await this.recipesService.assertOwnedRecipe(userId, recipeId);
    const [row] = await this.db
      .select({ imageUrl: recipeGalleryImages.imageUrl })
      .from(recipeGalleryImages)
      .where(and(eq(recipeGalleryImages.id, imageId), eq(recipeGalleryImages.recipeId, recipeId)));
    if (!row) throw new NotFoundException('Photo introuvable');

    await this.db.delete(recipeGalleryImages).where(eq(recipeGalleryImages.id, imageId));
    await this.storage.removeByPublicUrls([row.imageUrl]);
    return { photos: await this.listPhotos(recipeId) };
  }

  private async listPhotos(recipeId: string): Promise<RecipeGalleryPhotoDto[]> {
    const rows = await this.db
      .select({
        id: recipeGalleryImages.id,
        imageUrl: recipeGalleryImages.imageUrl,
        createdAt: recipeGalleryImages.createdAt,
      })
      .from(recipeGalleryImages)
      .where(eq(recipeGalleryImages.recipeId, recipeId))
      .orderBy(asc(recipeGalleryImages.createdAt));
    return rows.map((r) => ({
      id: r.id,
      imageUrl: r.imageUrl,
      createdAt: r.createdAt.toISOString(),
    }));
  }

  /** Garde de quota (vérifiée serveur, jamais uniquement UI). */
  private async assertQuota(userId: string, recipeId: string): Promise<void> {
    const [row] = await this.db
      .select({ n: sql<number>`count(*)::int` })
      .from(recipeGalleryImages)
      .where(eq(recipeGalleryImages.recipeId, recipeId));
    const current = row?.n ?? 0;
    const isPremium = await this.premiumService.isPremium(userId);
    const limit = isPremium
      ? RecipeGalleryService.PRO_LIMIT
      : RecipeGalleryService.FREE_LIMIT;
    if (current < limit) return;
    throw new PremiumLimitException(
      'PREMIUM_LIMIT_GALLERY_PHOTOS',
      limit,
      current,
      `Limite de ${limit} photos de galerie atteinte pour cette recette.`,
    );
  }
}
