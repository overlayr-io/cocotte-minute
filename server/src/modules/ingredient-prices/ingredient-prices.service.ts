import { ForbiddenException, Inject, Injectable } from '@nestjs/common';
import { and, eq } from 'drizzle-orm';

import { DRIZZLE, DrizzleDB } from '../../db/drizzle.provider';
import {
  ingredientPrices,
  type IngredientPriceRow,
  type NewIngredientPriceRow,
  type PriceReferenceUnit,
} from '../../db/schema/ingredient-prices.schema';
import { PremiumService } from '../billing/premium.service';
import { IngredientsService } from '../ingredients/ingredients.service';
import { UpsertIngredientPriceDto } from './dto/upsert-ingredient-price.dto';

/** Représentation d'API (camelCase) — jamais la ligne Drizzle brute. */
export interface IngredientPriceDto {
  ingredientId: string;
  priceReferenceUnit: PriceReferenceUnit;
  lowPrice: number | null;
  highPrice: number | null;
  averagePrice: number | null;
  updatedAt: string;
}

function toDto(row: IngredientPriceRow): IngredientPriceDto {
  return {
    ingredientId: row.ingredientId,
    priceReferenceUnit: row.priceReferenceUnit,
    lowPrice: row.lowPrice,
    highPrice: row.highPrice,
    averagePrice: row.averagePrice,
    updatedAt: row.updatedAt.toISOString(),
  };
}

/**
 * Prix estimé des ingrédients (feature prix-estime). Aucun calcul ici (moyenne,
 * scaling, agrégation, conversion d'unité) : contrainte transverse actée, tout
 * est côté client — ce service ne fait que stocker/retourner les valeurs saisies.
 */
@Injectable()
export class IngredientPricesService {
  constructor(
    @Inject(DRIZZLE) private readonly db: DrizzleDB,
    private readonly ingredientsService: IngredientsService,
    private readonly premiumService: PremiumService,
  ) {}

  /** Tous les prix saisis par l'utilisateur — alimente le cache offline mobile. */
  async listMine(userId: string): Promise<IngredientPriceDto[]> {
    const rows = await this.db
      .select()
      .from(ingredientPrices)
      .where(eq(ingredientPrices.userId, userId));
    return rows.map(toDto);
  }

  /**
   * Upsert du prix d'un ingrédient pour l'utilisateur courant, même si
   * l'ingrédient est système partagé (le prix reste propre à chaque
   * utilisateur, jamais partagé). `lowPrice`/`highPrice` rejetés (403) si
   * l'utilisateur n'est pas premium — gate binaire, pas une limite de quota :
   * l'app ne propose ces champs qu'aux premium, ce 403 est un garde-fou
   * serveur, pas un chemin UX normal.
   */
  async upsert(
    userId: string,
    ingredientId: string,
    dto: UpsertIngredientPriceDto,
  ): Promise<IngredientPriceDto> {
    await this.ingredientsService.assertVisible(userId, ingredientId);

    const setsPremiumRange = dto.lowPrice !== undefined || dto.highPrice !== undefined;
    if (setsPremiumRange && !(await this.premiumService.isPremium(userId))) {
      throw new ForbiddenException(
        'La fourchette bas/haut est réservée aux comptes premium',
      );
    }

    const patch: Pick<NewIngredientPriceRow, 'priceReferenceUnit'> &
      Partial<Pick<NewIngredientPriceRow, 'lowPrice' | 'highPrice' | 'averagePrice'>> = {
      priceReferenceUnit: dto.priceReferenceUnit,
    };
    if (dto.lowPrice !== undefined) patch.lowPrice = dto.lowPrice;
    if (dto.highPrice !== undefined) patch.highPrice = dto.highPrice;
    if (dto.averagePrice !== undefined) patch.averagePrice = dto.averagePrice;

    const [existing] = await this.db
      .select({ id: ingredientPrices.id })
      .from(ingredientPrices)
      .where(
        and(eq(ingredientPrices.userId, userId), eq(ingredientPrices.ingredientId, ingredientId)),
      );

    if (existing) {
      const [row] = await this.db
        .update(ingredientPrices)
        .set({ ...patch, updatedAt: new Date() })
        .where(eq(ingredientPrices.id, existing.id))
        .returning();
      return toDto(row);
    }

    const [row] = await this.db
      .insert(ingredientPrices)
      .values({ userId, ingredientId, ...patch })
      .returning();
    return toDto(row);
  }
}
