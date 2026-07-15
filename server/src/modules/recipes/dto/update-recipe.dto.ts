import { Transform } from 'class-transformer';
import {
  IsBoolean,
  IsIn,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  IsUrl,
  Max,
  MaxLength,
  Min,
  MinLength,
  ValidateIf,
} from 'class-validator';

import {
  RECIPE_PRICE_BRACKETS,
  RECIPE_PRICE_MODES,
  type RecipePriceBracket,
  type RecipePriceMode,
} from '../../../db/schema/recipes.schema';

/**
 * Modification d'une recette depuis sa fiche. Tous les champs sont optionnels
 * (patch partiel). Le passage `is_base` true→false est refusé côté service si la
 * recette est utilisée comme composant (verrou métier).
 *
 * `fixedPrice`/`priceBracket` (feature prix-estime) sont calculés côté client
 * (jamais par le serveur) et simplement poussés ici pour stockage.
 * `priceBracket: null` = prix inconnu/partiel, jamais posé sur un total `≈`.
 */
export class UpdateRecipeDto {
  @IsOptional()
  @IsString()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @MinLength(1)
  @MaxLength(160)
  name?: string;

  @IsOptional()
  @IsUrl({ require_tld: false })
  @MaxLength(2048)
  photoUrl?: string;

  @IsOptional()
  @IsString()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @MaxLength(2000)
  description?: string;

  @IsOptional()
  @IsBoolean()
  isBase?: boolean;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(100000)
  prepTime?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(100000)
  cookTime?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(100000)
  restTime?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(1000)
  servings?: number;

  @IsOptional()
  @IsIn(RECIPE_PRICE_MODES)
  priceMode?: RecipePriceMode;

  @IsOptional()
  @ValidateIf((o: UpdateRecipeDto) => o.fixedPrice !== null)
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  @Max(99999999)
  fixedPrice?: number | null;

  @IsOptional()
  @ValidateIf((o: UpdateRecipeDto) => o.priceBracket !== null)
  @IsIn(RECIPE_PRICE_BRACKETS)
  priceBracket?: RecipePriceBracket | null;

  // Nutrition saisie à la main (feature #8), PAR PORTION. Nullable = effacée.
  // Calories en kcal, macros en grammes.
  @IsOptional()
  @ValidateIf((o: UpdateRecipeDto) => o.caloriesPerServing !== null)
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  @Max(100000)
  caloriesPerServing?: number | null;

  @IsOptional()
  @ValidateIf((o: UpdateRecipeDto) => o.proteinsPerServing !== null)
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  @Max(100000)
  proteinsPerServing?: number | null;

  @IsOptional()
  @ValidateIf((o: UpdateRecipeDto) => o.carbsPerServing !== null)
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  @Max(100000)
  carbsPerServing?: number | null;

  @IsOptional()
  @ValidateIf((o: UpdateRecipeDto) => o.fatsPerServing !== null)
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  @Max(100000)
  fatsPerServing?: number | null;
}
