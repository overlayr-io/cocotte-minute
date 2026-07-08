import { Transform } from 'class-transformer';
import {
  IsBoolean,
  IsInt,
  IsOptional,
  IsString,
  IsUrl,
  Max,
  MaxLength,
  Min,
  MinLength,
} from 'class-validator';

/**
 * Modification d'une recette depuis sa fiche. Tous les champs sont optionnels
 * (patch partiel). Le passage `is_base` true→false est refusé côté service si la
 * recette est utilisée comme composant (verrou métier).
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
}
