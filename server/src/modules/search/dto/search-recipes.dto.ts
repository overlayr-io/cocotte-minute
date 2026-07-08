import { Transform } from 'class-transformer';
import { IsArray, IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';

/**
 * Coerce un paramètre de query (répété `?k=a&k=b`, ou séparé par virgules) en
 * tableau de chaînes. Laisse passer `undefined`/`null` tels quels pour que
 * `@IsOptional` fasse son office.
 */
function toIdArray({ value }: { value: unknown }): unknown {
  if (value === undefined || value === null) return value;
  if (Array.isArray(value)) return value;
  if (typeof value === 'string') {
    return value
      .split(',')
      .map((s) => s.trim())
      .filter((s) => s.length > 0);
  }
  return value;
}

/**
 * Critères de la recherche avancée (query params). Toutes les dimensions sont
 * optionnelles et se combinent en ET. `whitelist + forbidNonWhitelisted` étant
 * actifs globalement, tout champ hors de ce DTO fait échouer la requête.
 */
export class SearchRecipesDto {
  /** Recherche texte libre sur le nom de la recette. */
  @IsOptional()
  @IsString()
  @MaxLength(160)
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  q?: string;

  /** Dossiers sélectionnés (leurs sous-dossiers sont inclus côté serveur). */
  @IsOptional()
  @Transform(toIdArray)
  @IsArray()
  @IsUUID('all', { each: true })
  categoryIds?: string[];

  /** Tags sélectionnés : la recette doit tous les porter (ET). */
  @IsOptional()
  @Transform(toIdArray)
  @IsArray()
  @IsUUID('all', { each: true })
  tagIds?: string[];

  /** Personnes sélectionnées : recette compatible avec au moins un de leurs tags. */
  @IsOptional()
  @Transform(toIdArray)
  @IsArray()
  @IsUUID('all', { each: true })
  personIds?: string[];
}
