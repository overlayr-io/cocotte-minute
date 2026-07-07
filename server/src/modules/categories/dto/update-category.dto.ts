import { Transform } from 'class-transformer';
import {
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
  ValidateIf,
} from 'class-validator';

/**
 * Édition d'un dossier : nom et/ou emoji (patch partiel). Le dossier parent
 * n'est pas modifiable ici (pas de déplacement en v1). Refusé côté service si
 * le dossier est par défaut.
 */
export class UpdateCategoryDto {
  @IsOptional()
  @IsString()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @MinLength(1)
  @MaxLength(120)
  name?: string;

  /** `null` explicite = retirer l'emoji ; absent = inchangé. */
  @IsOptional()
  @ValidateIf((o: UpdateCategoryDto) => o.icon !== null)
  @IsString()
  @MaxLength(32)
  icon?: string | null;
}
