import { Transform } from 'class-transformer';
import { IsISO8601, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

/** Renommage d'une liste (+ horodatage client pour « le plus récent gagne »). */
export class UpdateShoppingListDto {
  @IsOptional()
  @IsString()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @MinLength(1)
  @MaxLength(160)
  name?: string;

  @IsOptional()
  @IsISO8601()
  clientUpdatedAt?: string;
}
