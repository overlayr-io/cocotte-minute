import { Type } from 'class-transformer';
import { IsIn, IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

/**
 * Tri de la vue Liste : `recent` (défaut, plus récentes d'abord), `time` (temps
 * total prépa+cuisson+repos croissant), `name` (alphabétique A-Z). Le tri par
 * prix est volontairement absent : le prix est calculé côté client (contrainte
 * transverse), le serveur n'a pas de prix fiable à ordonner.
 */
export const RECIPE_SORTS = ['recent', 'time', 'name'] as const;
export type RecipeSort = (typeof RECIPE_SORTS)[number];

/**
 * Query de `GET /recipes` : pagination optionnelle + filtre texte simple + tri
 * (vue Liste de la page Recettes). Sans paramètre, tout est renvoyé, trié par
 * récence (rétro-compatible avec les autres écrans).
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

  @IsOptional()
  @IsIn(RECIPE_SORTS)
  sort?: RecipeSort;
}
