import { Transform } from 'class-transformer';
import {
  IsOptional,
  IsString,
  IsUrl,
  MaxLength,
  MinLength,
  ValidateIf,
} from 'class-validator';

/**
 * Édition d'une personne (patch partiel). `lastName: null` / `avatarUrl: null`
 * explicites permettent de retirer le nom ou l'avatar.
 */
export class UpdatePersonDto {
  @IsOptional()
  @IsString()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @MinLength(1)
  @MaxLength(80)
  firstName?: string;

  @IsOptional()
  @ValidateIf((o: UpdatePersonDto) => o.lastName !== null)
  @IsString()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @MaxLength(80)
  lastName?: string | null;

  @IsOptional()
  @ValidateIf((o: UpdatePersonDto) => o.avatarUrl !== null)
  @IsUrl({ require_tld: false })
  @MaxLength(2048)
  avatarUrl?: string | null;
}
