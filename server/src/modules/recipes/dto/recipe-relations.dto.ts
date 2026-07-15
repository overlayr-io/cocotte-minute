import {
  ArrayNotEmpty,
  IsArray,
  IsIn,
  IsNumber,
  IsOptional,
  IsPositive,
  IsString,
  IsUUID,
  Max,
  MaxLength,
  ValidateIf,
} from 'class-validator';

import { RECIPE_STEP_BANNERS } from '../../../db/schema/recipes.schema';

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

/**
 * Création d'une étape : soit une étape texte (`description`, + bannière
 * optionnelle, + ingrédients optionnels), soit une référence de base
 * (`baseRecipeRefId` seul). L'exclusivité est vérifiée côté service.
 */
export class CreateRecipeStepDto {
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  description?: string;

  @IsOptional()
  @IsIn(RECIPE_STEP_BANNERS)
  bannerType?: (typeof RECIPE_STEP_BANNERS)[number];

  @IsOptional()
  @IsString()
  @MaxLength(200)
  bannerText?: string;

  @IsOptional()
  @IsUUID()
  baseRecipeRefId?: string;

  @IsOptional()
  @IsArray()
  @IsUUID('all', { each: true })
  ingredientIds?: string[];
}

/** Import texte : chaque entrée devient une étape texte. */
export class ImportRecipeStepsDto {
  @IsArray()
  @ArrayNotEmpty()
  @IsString({ each: true })
  descriptions!: string[];
}

/** Édition d'une étape texte. `bannerType: null` retire la bannière. */
export class UpdateRecipeStepDto {
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  description?: string;

  @IsOptional()
  @ValidateIf((o: UpdateRecipeStepDto) => o.bannerType !== null)
  @IsIn(RECIPE_STEP_BANNERS)
  bannerType?: (typeof RECIPE_STEP_BANNERS)[number] | null;

  @IsOptional()
  @ValidateIf((o: UpdateRecipeStepDto) => o.bannerText !== null)
  @IsString()
  @MaxLength(200)
  bannerText?: string | null;
}

/** Réordonnancement : ids des étapes de premier niveau dans le nouvel ordre. */
export class ReorderRecipeStepsDto {
  @IsArray()
  @ArrayNotEmpty()
  @IsUUID('all', { each: true })
  stepIds!: string[];
}

/** Réordonnancement : ids des ingrédients de la recette dans le nouvel ordre. */
export class ReorderRecipeIngredientsDto {
  @IsArray()
  @ArrayNotEmpty()
  @IsUUID('all', { each: true })
  ingredientIds!: string[];
}

/** Sélection des ingrédients d'une étape (sous-ensemble de ceux de la recette). */
export class SetStepIngredientsDto {
  @IsArray()
  @IsUUID('all', { each: true })
  ingredientIds!: string[];
}
