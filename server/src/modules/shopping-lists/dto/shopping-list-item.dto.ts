import { Transform } from 'class-transformer';
import {
  IsBoolean,
  IsISO8601,
  IsNumber,
  IsOptional,
  IsPositive,
  IsString,
  IsUUID,
  Max,
  MaxLength,
  MinLength,
  ValidateIf,
} from 'class-validator';

/** Ajout d'un article libre (hors recette) à une liste — 5e « Ajouter un article ». */
export class AddShoppingListItemDto {
  @IsOptional()
  @IsUUID()
  id?: string;

  @IsString()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @MinLength(1)
  @MaxLength(160)
  customLabel!: string;

  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 2 })
  @IsPositive()
  @Max(99999999)
  quantity?: number;

  @IsOptional()
  @IsString()
  @MaxLength(32)
  unit?: string;

  @IsOptional()
  @IsISO8601()
  clientUpdatedAt?: string;
}

/**
 * Mise à jour d'un article : cocher/décocher et/ou choisir une alternative.
 * `replacedByAlternativeId: null` réinitialise vers l'ingrédient d'origine.
 * `clientUpdatedAt` pilote la résolution « le plus récent gagne » à la sync.
 */
export class UpdateShoppingListItemDto {
  @IsOptional()
  @IsBoolean()
  isChecked?: boolean;

  @IsOptional()
  @ValidateIf((o: UpdateShoppingListItemDto) => o.replacedByAlternativeId !== null)
  @IsUUID()
  replacedByAlternativeId?: string | null;

  @IsOptional()
  @IsISO8601()
  clientUpdatedAt?: string;
}
