import { Transform } from 'class-transformer';
import {
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  MinLength,
} from 'class-validator';

export class CreateCategoryDto {
  @IsString()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @MinLength(1)
  @MaxLength(120)
  name!: string;

  /** Emoji système, optionnel (null/absent = icône dossier par défaut côté client). */
  @IsOptional()
  @IsString()
  @MaxLength(16)
  icon?: string;

  /** Dossier parent (absent = racine). Doit appartenir au même compte. */
  @IsOptional()
  @IsUUID()
  parentCategoryId?: string;
}
