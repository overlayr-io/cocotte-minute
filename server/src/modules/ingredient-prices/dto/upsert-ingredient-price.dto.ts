import { IsIn, IsNumber, IsOptional, Max, Min, ValidateIf } from 'class-validator';

import { PRICE_REFERENCE_UNITS, type PriceReferenceUnit } from '../../../db/schema/ingredient-prices.schema';

/**
 * Upsert du prix d'un ingrédient pour l'utilisateur courant. `lowPrice`/
 * `highPrice`/`averagePrice` absents = non touchés (permet à un gratuit de ne
 * PAS écraser ses valeurs premium déjà saisies en ne renvoyant que
 * `averagePrice`) ; explicitement `null` = effacés. Le service rejette (403)
 * `lowPrice`/`highPrice` si envoyés par un utilisateur non premium.
 */
export class UpsertIngredientPriceDto {
  @IsIn(PRICE_REFERENCE_UNITS)
  priceReferenceUnit!: PriceReferenceUnit;

  @IsOptional()
  @ValidateIf((o: UpsertIngredientPriceDto) => o.lowPrice !== null)
  @IsNumber({ maxDecimalPlaces: 3 })
  @Min(0)
  @Max(9999999)
  lowPrice?: number | null;

  @IsOptional()
  @ValidateIf((o: UpsertIngredientPriceDto) => o.highPrice !== null)
  @IsNumber({ maxDecimalPlaces: 3 })
  @Min(0)
  @Max(9999999)
  highPrice?: number | null;

  @IsOptional()
  @ValidateIf((o: UpsertIngredientPriceDto) => o.averagePrice !== null)
  @IsNumber({ maxDecimalPlaces: 3 })
  @Min(0)
  @Max(9999999)
  averagePrice?: number | null;
}
