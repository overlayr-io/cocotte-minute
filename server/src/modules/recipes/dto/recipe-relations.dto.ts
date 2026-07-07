import { IsNumber, IsPositive, IsUUID, Max } from 'class-validator';

/** Ajout (ou mise à jour de la quantité) d'un ingrédient d'une recette. */
export class AddRecipeIngredientDto {
  @IsUUID()
  ingredientId!: string;

  /**
   * Quantité pour `recipes.servings` personnes. Décimal > 0 (l'unité reste celle
   * de l'ingrédient). Max aligné sur `numeric(10,2)`.
   */
  @IsNumber({ maxDecimalPlaces: 2 })
  @IsPositive()
  @Max(99999999)
  quantity!: number;
}

/** Mise à jour de la seule quantité d'un ingrédient déjà présent sur la recette. */
export class UpdateRecipeIngredientQuantityDto {
  @IsNumber({ maxDecimalPlaces: 2 })
  @IsPositive()
  @Max(99999999)
  quantity!: number;
}

/** Ajout d'une recette de base comme composant. */
export class AddRecipeComponentDto {
  @IsUUID()
  baseRecipeId!: string;
}

/** Rangement d'une recette dans un dossier. */
export class AssignRecipeCategoryDto {
  @IsUUID()
  categoryId!: string;
}

/** Étiquetage d'une recette. */
export class AssignRecipeTagDto {
  @IsUUID()
  tagId!: string;
}
