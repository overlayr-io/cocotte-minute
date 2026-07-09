import { Type } from 'class-transformer';
import { IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

/**
 * Query de `GET /recipes` : pagination optionnelle + filtre texte simple
 * (vue Liste de la page Recettes). Sans paramètre, tout est renvoyé
 * (rétro-compatible avec les autres écrans).
 */
export class ListRecipesQueryDto {
  @IsOptional()
  @IsString()
  q?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  offset?: number;
}
