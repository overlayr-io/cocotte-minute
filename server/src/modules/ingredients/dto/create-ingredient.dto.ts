import { Transform } from 'class-transformer';
import { IsIn, IsOptional, IsString, IsUrl, MaxLength, MinLength } from 'class-validator';

import { INGREDIENT_UNITS, type IngredientUnit } from '../../../db/schema/ingredients.schema';

export class CreateIngredientDto {
  @IsString()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @MinLength(1)
  @MaxLength(120)
  name!: string;

  @IsIn(INGREDIENT_UNITS)
  unit!: IngredientUnit;

  @IsOptional()
  @IsUrl({ require_tld: false })
  @MaxLength(2048)
  imageUrl?: string;

  /** Emoji illustrant l'ingrédient (exclusif avec imageUrl, tranché côté service). */
  @IsOptional()
  @IsString()
  @MaxLength(16)
  emoji?: string;
}
