import { Transform } from 'class-transformer';
import {
  IsIn,
  IsOptional,
  IsString,
  IsUrl,
  MaxLength,
  MinLength,
  ValidateIf,
} from 'class-validator';

import { INGREDIENT_UNITS, type IngredientUnit } from '../../../db/schema/ingredients.schema';

/**
 * Édition d'un ingrédient utilisateur. Tous les champs sont optionnels (patch
 * partiel). `imageUrl: null` explicite permet de retirer l'image.
 */
export class UpdateIngredientDto {
  @IsOptional()
  @IsString()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @MinLength(1)
  @MaxLength(120)
  name?: string;

  @IsOptional()
  @IsIn(INGREDIENT_UNITS)
  unit?: IngredientUnit;

  @IsOptional()
  @ValidateIf((o: UpdateIngredientDto) => o.imageUrl !== null)
  @IsUrl({ require_tld: false })
  @MaxLength(2048)
  imageUrl?: string | null;
}
