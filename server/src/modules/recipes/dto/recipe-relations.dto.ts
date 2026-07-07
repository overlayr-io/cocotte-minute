import { IsUUID } from 'class-validator';

/** Ajout d'un ingrédient (déjà créé/importé) à une recette. */
export class AddRecipeIngredientDto {
  @IsUUID()
  ingredientId!: string;
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
