import { Transform } from 'class-transformer';
import { IsIn, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

import { TAG_COLORS, type TagColor } from '../../../db/schema/tags.schema';

/**
 * Édition d'un tag. Tous les champs sont optionnels (patch partiel) : on peut
 * renommer et/ou recolorer indépendamment.
 */
export class UpdateTagDto {
  @IsOptional()
  @IsString()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @MinLength(1)
  @MaxLength(60)
  name?: string;

  @IsOptional()
  @IsIn(TAG_COLORS)
  color?: TagColor;
}
