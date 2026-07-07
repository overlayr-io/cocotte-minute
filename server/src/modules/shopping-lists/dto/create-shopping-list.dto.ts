import { Transform, Type } from 'class-transformer';
import {
  ArrayNotEmpty,
  IsArray,
  IsInt,
  IsISO8601,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  MaxLength,
  Min,
  MinLength,
  ValidateNested,
} from 'class-validator';

/** Une recette sélectionnée + le nombre de parts choisi (étapes 5b/5c). */
export class ShoppingListRecipeSelectionDto {
  @IsUUID()
  recipeId!: string;

  /** Nombre de parts choisi (facteur d'échelle des quantités). */
  @IsInt()
  @Min(1)
  @Max(999)
  servings!: number;
}

/**
 * Génération d'une liste de courses à partir de recettes (5b → 5d).
 * `id`/`clientUpdatedAt` optionnels : fournis par le mobile (offline-first) pour
 * un identifiant stable local↔serveur et la résolution de conflit à la sync.
 */
export class CreateShoppingListDto {
  @IsOptional()
  @IsUUID()
  id?: string;

  @IsString()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @MinLength(1)
  @MaxLength(160)
  name!: string;

  @IsArray()
  @ArrayNotEmpty()
  @ValidateNested({ each: true })
  @Type(() => ShoppingListRecipeSelectionDto)
  recipes!: ShoppingListRecipeSelectionDto[];

  /** Ingrédients déjà en stock (cochés en 5d) → exclus de la liste générée. */
  @IsOptional()
  @IsArray()
  @IsUUID('all', { each: true })
  pantryIngredientIds?: string[];

  @IsOptional()
  @IsISO8601()
  clientUpdatedAt?: string;
}
