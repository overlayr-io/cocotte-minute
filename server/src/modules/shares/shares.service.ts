import { randomBytes } from 'node:crypto';

import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { and, desc, eq, isNull } from 'drizzle-orm';

import { DRIZZLE, DrizzleDB } from '../../db/drizzle.provider';
import { recipeShares } from '../../db/schema/recipe-shares.schema';
import { RecipeDetailDto, RecipesService } from '../recipes/recipes.service';

/** Réponse de génération d'un lien de partage : jeton + URL publique prête à copier. */
export interface ShareLinkDto {
  token: string;
  url: string;
}

/**
 * Feature partage-recette : génération d'un lien public (token) et résolution de ce
 * token vers une fiche recette en lecture seule. Aucune règle de rendu ici — la
 * hydratation de la recette est déléguée à RecipesService (isolation des domaines :
 * ce module ne touche jamais au schéma recettes).
 */
@Injectable()
export class SharesService {
  constructor(
    @Inject(DRIZZLE) private readonly db: DrizzleDB,
    private readonly recipesService: RecipesService,
    private readonly config: ConfigService,
  ) {}

  /**
   * Crée (ou réutilise) un lien de partage pour une recette possédée par l'utilisateur.
   * Réutilise un token actif existant pour éviter d'en multiplier à chaque appel ;
   * n'autorise que le propriétaire (délégation à RecipesService pour le contrôle).
   */
  async createShareLink(userId: string, recipeId: string): Promise<ShareLinkDto> {
    await this.recipesService.assertOwnedRecipe(userId, recipeId);

    const [existing] = await this.db
      .select({ token: recipeShares.token })
      .from(recipeShares)
      .where(
        and(
          eq(recipeShares.recipeId, recipeId),
          isNull(recipeShares.revokedAt),
        ),
      )
      .orderBy(desc(recipeShares.createdAt))
      .limit(1);

    const token = existing?.token ?? (await this.mintToken(userId, recipeId));
    return { token, url: this.buildShareUrl(token) };
  }

  /** Résout un token de partage actif vers la fiche détail publique (lecture seule). */
  async getSharedRecipe(token: string): Promise<RecipeDetailDto> {
    const recipeId = await this.resolveToken(token);
    return this.recipesService.getPublicDetail(recipeId);
  }

  /** URL publique d'un token (page web + universal/app link). */
  buildShareUrl(token: string): string {
    const base = this.config.get<string>('PUBLIC_BASE_URL', 'http://localhost:3000');
    return `${base.replace(/\/+$/, '')}/r/${token}`;
  }

  private async resolveToken(token: string): Promise<string> {
    const [row] = await this.db
      .select({ recipeId: recipeShares.recipeId })
      .from(recipeShares)
      .where(and(eq(recipeShares.token, token), isNull(recipeShares.revokedAt)))
      .limit(1);
    if (!row) throw new NotFoundException('Lien de partage introuvable ou expiré');
    return row.recipeId;
  }

  private async mintToken(authorId: string, recipeId: string): Promise<string> {
    // 18 octets → 24 caractères base64url (URL-safe, tient dans varchar(32)).
    const token = randomBytes(18).toString('base64url');
    await this.db.insert(recipeShares).values({ authorId, recipeId, token });
    return token;
  }
}
