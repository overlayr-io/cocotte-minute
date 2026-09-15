import { Transform } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsInt,
  IsOptional,
  IsString,
  IsUrl,
  IsUUID,
  Max,
  MaxLength,
  Min,
  MinLength,
} from 'class-validator';

/**
 * Création d'une recette. Flow minimal (cf. recipes.md) : seul le nom est requis,
 * la photo et le flag « recette de base » sont posés dès la création. Le reste
 * (description, temps, personnes) se complète ensuite sur la fiche via PATCH.
 */
export class CreateRecipeDto {
  @IsString()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @MinLength(1)
  @MaxLength(160)
  name!: string;

  /** Photo optionnelle (URL Storage, ou hotlink Unsplash). */
  @IsOptional()
  @IsUrl({ require_tld: false })
  @MaxLength(2048)
  photoUrl?: string;

  /**
   * Attribution photographe (feature suggestion d'image #4) — fournie
   * uniquement quand `photoUrl` provient d'Unsplash (obligatoire par les
   * conditions de l'API).
   */
  @IsOptional()
  @IsString()
  @MaxLength(200)
  photoAuthorName?: string;

  @IsOptional()
  @IsUrl({ require_tld: false })
  @MaxLength(2048)
  photoAuthorUrl?: string;

  @IsOptional()
  @IsString()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @MaxLength(2000)
  description?: string;

  /** Recette de base (réutilisable comme composant). Défaut false. */
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

  /** Dossiers dans lesquels ranger la recette dès sa création. */
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(20)
  @IsUUID('4', { each: true })
  categoryIds?: string[];
}
