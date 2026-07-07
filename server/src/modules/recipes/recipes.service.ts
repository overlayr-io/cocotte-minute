import {
  ConflictException,
  Inject,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { and, desc, eq, inArray, isNull, sql } from 'drizzle-orm';

import { DRIZZLE, DrizzleDB } from '../../db/drizzle.provider';
import {
  DEFAULT_INGREDIENT_QUANTITY,
  recipeCategories,
  recipeComponents,
  recipeIngredients,
  recipeTags,
  recipes,
  type RecipeRow,
} from '../../db/schema/recipes.schema';
import { IngredientsService } from '../ingredients/ingredients.service';
import { CreateRecipeDto } from './dto/create-recipe.dto';
import { UpdateRecipeDto } from './dto/update-recipe.dto';

/** Ligne de liste / carte (sans les relations lourdes). */
export interface RecipeSummaryDto {
  id: string;
  name: string;
  photoUrl: string | null;
  isBase: boolean;
  prepTime: number;
  cookTime: number;
  restTime: number;
  servings: number;
  createdAt: string;
}

/**
 * Ingrédient tel qu'affiché sur la fiche : nom + unité (lue depuis l'ingrédient)
 * + quantité (pour `recipes.servings` personnes ; la mise à l'échelle par
 * portions est un calcul d'affichage côté client).
 */
export interface RecipeIngredientLineDto {
  id: string;
  name: string;
  unit: string;
  imageUrl: string | null;
  quantity: number;
}

/** Fiche détail complète. */
export interface RecipeDetailDto extends RecipeSummaryDto {
  authorId: string;
  description: string | null;
  /** Recette de base utilisée comme composant ailleurs → `is_base` verrouillé. */
  isLocked: boolean;
  ingredients: RecipeIngredientLineDto[];
  /** Sous-recettes (recettes de base) utilisées par cette recette. */
  components: RecipeSummaryDto[];
  /** Recettes qui utilisent cette recette comme composant (seulement si `is_base`). */
  usedIn: RecipeSummaryDto[];
  categoryIds: string[];
  tagIds: string[];
}

function toSummary(row: RecipeRow): RecipeSummaryDto {
  return {
    id: row.id,
    name: row.name,
    photoUrl: row.photoUrl,
    isBase: row.isBase,
    prepTime: row.prepTime,
    cookTime: row.cookTime,
    restTime: row.restTime,
    servings: row.servings,
    createdAt: row.createdAt.toISOString(),
  };
}

@Injectable()
export class RecipesService {
  private readonly logger = new Logger(RecipesService.name);

  constructor(
    @Inject(DRIZZLE) private readonly db: DrizzleDB,
    // Isolation des domaines : Recipes hydrate/valide les ingrédients via le
    // service Ingredients, jamais en accédant à son schéma.
    private readonly ingredientsService: IngredientsService,
  ) {}

  /** Mes recettes (les plus récentes d'abord), hors supprimées. */
  async listMine(userId: string): Promise<RecipeSummaryDto[]> {
    const rows = await this.db
      .select()
      .from(recipes)
      .where(and(eq(recipes.authorId, userId), isNull(recipes.deletedAt)))
      .orderBy(desc(recipes.createdAt));
    return rows.map(toSummary);
  }

  async create(userId: string, dto: CreateRecipeDto): Promise<RecipeSummaryDto> {
    const [row] = await this.db
      .insert(recipes)
      .values({
        authorId: userId,
        name: dto.name,
        photoUrl: dto.photoUrl ?? null,
        description: dto.description ?? null,
        isBase: dto.isBase ?? false,
        prepTime: dto.prepTime ?? 0,
        cookTime: dto.cookTime ?? 0,
        restTime: dto.restTime ?? 0,
        servings: dto.servings ?? undefined,
      })
      .returning();
    return toSummary(row);
  }

  /** Fiche détail : ingrédients, composants, « utilisée dans », catégories, tags. */
  async getDetail(userId: string, id: string): Promise<RecipeDetailDto> {
    const row = await this.findOwnedOrFail(userId, id);

    const [ingredientRows, componentRows, categoryRows, tagRows] =
      await Promise.all([
        this.db
          .select({
            ingredientId: recipeIngredients.ingredientId,
            quantity: recipeIngredients.quantity,
          })
          .from(recipeIngredients)
          .where(eq(recipeIngredients.recipeId, id)),
        this.db
          .select({ baseRecipeId: recipeComponents.baseRecipeId })
          .from(recipeComponents)
          .where(eq(recipeComponents.parentRecipeId, id)),
        this.db
          .select({ categoryId: recipeCategories.categoryId })
          .from(recipeCategories)
          .where(eq(recipeCategories.recipeId, id)),
        this.db
          .select({ tagId: recipeTags.tagId })
          .from(recipeTags)
          .where(eq(recipeTags.recipeId, id)),
      ]);

    const ingredientLines = await this.hydrateIngredients(userId, ingredientRows);
    const components = await this.summariesByIds(
      userId,
      componentRows.map((r) => r.baseRecipeId),
    );

    // « Utilisée dans » : relation inverse, pertinente uniquement pour une base.
    let usedIn: RecipeSummaryDto[] = [];
    if (row.isBase) {
      const parents = await this.db
        .select({ parentRecipeId: recipeComponents.parentRecipeId })
        .from(recipeComponents)
        .where(eq(recipeComponents.baseRecipeId, id));
      usedIn = await this.summariesByIds(
        userId,
        parents.map((r) => r.parentRecipeId),
      );
    }

    return {
      ...toSummary(row),
      authorId: row.authorId,
      description: row.description,
      isLocked: row.isBase && usedIn.length > 0,
      ingredients: ingredientLines,
      components,
      usedIn,
      categoryIds: categoryRows.map((r) => r.categoryId),
      tagIds: tagRows.map((r) => r.tagId),
    };
  }

  async update(
    userId: string,
    id: string,
    dto: UpdateRecipeDto,
  ): Promise<RecipeSummaryDto> {
    const current = await this.findOwnedOrFail(userId, id);

    // Verrou métier : is_base true→false interdit tant que la recette sert de
    // composant ailleurs (vérifié serveur, pas seulement UI).
    if (dto.isBase === false && current.isBase && (await this.isUsedAsComponent(id))) {
      throw new ConflictException(
        'Cette recette de base est utilisée comme composant : impossible de la repasser en recette normale',
      );
    }

    const patch: Partial<RecipeRow> = {};
    if (dto.name !== undefined) patch.name = dto.name;
    if (dto.photoUrl !== undefined) patch.photoUrl = dto.photoUrl;
    if (dto.description !== undefined) patch.description = dto.description;
    if (dto.isBase !== undefined) patch.isBase = dto.isBase;
    if (dto.prepTime !== undefined) patch.prepTime = dto.prepTime;
    if (dto.cookTime !== undefined) patch.cookTime = dto.cookTime;
    if (dto.restTime !== undefined) patch.restTime = dto.restTime;
    if (dto.servings !== undefined) patch.servings = dto.servings;

    const [row] = await this.db
      .update(recipes)
      .set({ ...patch, updatedAt: new Date() })
      .where(eq(recipes.id, id))
      .returning();
    return toSummary(row);
  }

  /** Soft delete. Les pivots partent en cascade côté DB si le compte est purgé. */
  async softDelete(userId: string, id: string): Promise<void> {
    await this.findOwnedOrFail(userId, id);
    await this.db
      .update(recipes)
      .set({ deletedAt: new Date(), updatedAt: new Date() })
      .where(eq(recipes.id, id));
  }

  // --- ingrédients -------------------------------------------------------

  /**
   * Ajoute un ingrédient à une recette avec sa quantité. Ré-ajouter un ingrédient
   * déjà présent met à jour sa quantité (upsert) plutôt que de no-op.
   */
  async addIngredient(
    userId: string,
    recipeId: string,
    ingredientId: string,
    quantity: number,
  ): Promise<void> {
    await this.findOwnedOrFail(userId, recipeId);
    const [owned] = await this.ingredientsService.listByIds(userId, [ingredientId]);
    if (!owned) {
      throw new NotFoundException('Ingrédient introuvable');
    }
    await this.db
      .insert(recipeIngredients)
      .values({ recipeId, ingredientId, quantity })
      .onConflictDoUpdate({
        target: [recipeIngredients.recipeId, recipeIngredients.ingredientId],
        set: { quantity },
      });
  }

  /** Met à jour la quantité d'un ingrédient déjà présent sur la recette. */
  async updateIngredientQuantity(
    userId: string,
    recipeId: string,
    ingredientId: string,
    quantity: number,
  ): Promise<void> {
    await this.findOwnedOrFail(userId, recipeId);
    const [updated] = await this.db
      .update(recipeIngredients)
      .set({ quantity })
      .where(
        and(
          eq(recipeIngredients.recipeId, recipeId),
          eq(recipeIngredients.ingredientId, ingredientId),
        ),
      )
      .returning({ ingredientId: recipeIngredients.ingredientId });
    if (!updated) {
      throw new NotFoundException("Cet ingrédient n'est pas dans la recette");
    }
  }

  async removeIngredient(
    userId: string,
    recipeId: string,
    ingredientId: string,
  ): Promise<void> {
    await this.findOwnedOrFail(userId, recipeId);
    await this.db
      .delete(recipeIngredients)
      .where(
        and(
          eq(recipeIngredients.recipeId, recipeId),
          eq(recipeIngredients.ingredientId, ingredientId),
        ),
      );
  }

  // --- composants (sous-recettes) ---------------------------------------

  /**
   * Ajoute une recette de base comme composant. Refuse : l'auto-référence, une
   * base non possédée, et surtout une recette dont `is_base = false` (une recette
   * normale ne peut jamais être composant — règle serveur obligatoire).
   */
  async addComponent(
    userId: string,
    recipeId: string,
    baseRecipeId: string,
  ): Promise<void> {
    if (recipeId === baseRecipeId) {
      throw new ConflictException(
        'Une recette ne peut pas s’utiliser elle-même comme composant',
      );
    }
    await this.findOwnedOrFail(userId, recipeId);
    const base = await this.findOwnedOrFail(userId, baseRecipeId);
    if (!base.isBase) {
      throw new ConflictException(
        'Seule une recette de base peut être ajoutée comme composant',
      );
    }
    await this.db
      .insert(recipeComponents)
      .values({ parentRecipeId: recipeId, baseRecipeId })
      .onConflictDoNothing();
  }

  async removeComponent(
    userId: string,
    recipeId: string,
    baseRecipeId: string,
  ): Promise<void> {
    await this.findOwnedOrFail(userId, recipeId);
    await this.db
      .delete(recipeComponents)
      .where(
        and(
          eq(recipeComponents.parentRecipeId, recipeId),
          eq(recipeComponents.baseRecipeId, baseRecipeId),
        ),
      );
  }

  // --- rangement (catégories) & étiquetage (tags) ------------------------
  // L'appartenance du dossier / tag est garantie par la FK ; on ne valide ici
  // que la possession de la recette pour ne pas coupler Recipes à Categories /
  // Tags (qui, eux, dépendent de Recipes pour leurs compteurs — sens unique).

  async assignCategory(
    userId: string,
    recipeId: string,
    categoryId: string,
  ): Promise<void> {
    await this.findOwnedOrFail(userId, recipeId);
    await this.db
      .insert(recipeCategories)
      .values({ recipeId, categoryId })
      .onConflictDoNothing();
  }

  async unassignCategory(
    userId: string,
    recipeId: string,
    categoryId: string,
  ): Promise<void> {
    await this.findOwnedOrFail(userId, recipeId);
    await this.db
      .delete(recipeCategories)
      .where(
        and(
          eq(recipeCategories.recipeId, recipeId),
          eq(recipeCategories.categoryId, categoryId),
        ),
      );
  }

  async assignTag(userId: string, recipeId: string, tagId: string): Promise<void> {
    await this.findOwnedOrFail(userId, recipeId);
    await this.db
      .insert(recipeTags)
      .values({ recipeId, tagId })
      .onConflictDoNothing();
  }

  async unassignTag(userId: string, recipeId: string, tagId: string): Promise<void> {
    await this.findOwnedOrFail(userId, recipeId);
    await this.db
      .delete(recipeTags)
      .where(and(eq(recipeTags.recipeId, recipeId), eq(recipeTags.tagId, tagId)));
  }

  // --- compteurs (exposés à Tags / Categories) ---------------------------

  /**
   * Nombre de recettes (possédées, non supprimées) rangées dans chacun des
   * dossiers demandés. Exposé pour CategoriesService.recipeCount.
   */
  async countByCategoryIds(
    userId: string,
    categoryIds: string[],
  ): Promise<Map<string, number>> {
    if (categoryIds.length === 0) return new Map();
    const rows = await this.db
      .select({
        categoryId: recipeCategories.categoryId,
        n: sql<number>`count(*)::int`,
      })
      .from(recipeCategories)
      .innerJoin(recipes, eq(recipes.id, recipeCategories.recipeId))
      .where(
        and(
          eq(recipes.authorId, userId),
          isNull(recipes.deletedAt),
          inArray(recipeCategories.categoryId, categoryIds),
        ),
      )
      .groupBy(recipeCategories.categoryId);
    return new Map(rows.map((r) => [r.categoryId, r.n]));
  }

  /** Idem pour les tags. Exposé pour TagsService.recipeCount. */
  async countByTagIds(
    userId: string,
    tagIds: string[],
  ): Promise<Map<string, number>> {
    if (tagIds.length === 0) return new Map();
    const rows = await this.db
      .select({ tagId: recipeTags.tagId, n: sql<number>`count(*)::int` })
      .from(recipeTags)
      .innerJoin(recipes, eq(recipes.id, recipeTags.recipeId))
      .where(
        and(
          eq(recipes.authorId, userId),
          isNull(recipes.deletedAt),
          inArray(recipeTags.tagId, tagIds),
        ),
      )
      .groupBy(recipeTags.tagId);
    return new Map(rows.map((r) => [r.tagId, r.n]));
  }

  /**
   * Hard delete de toutes les recettes d'un utilisateur ("repartir de zéro").
   * Les pivots (ingrédients, composants, catégories, tags) partent en cascade.
   * Exposé pour AccountService uniquement.
   */
  async deleteAllForUser(userId: string): Promise<void> {
    await this.db.delete(recipes).where(eq(recipes.authorId, userId));
    this.logger.log(`Recettes supprimées pour l'utilisateur ${userId}`);
  }

  // --- privé -------------------------------------------------------------

  /**
   * Résout les lignes du pivot (id + quantité) en lignes affichables, en lisant
   * nom/unité/image depuis le service Ingredients (isolation des domaines). La
   * quantité vient du pivot, pas de l'ingrédient.
   */
  private async hydrateIngredients(
    userId: string,
    lines: { ingredientId: string; quantity: number }[],
  ): Promise<RecipeIngredientLineDto[]> {
    if (lines.length === 0) return [];
    const quantities = new Map(lines.map((l) => [l.ingredientId, l.quantity]));
    const owned = await this.ingredientsService.listByIds(
      userId,
      lines.map((l) => l.ingredientId),
    );
    return owned.map((i) => ({
      id: i.id,
      name: i.name,
      unit: i.unit,
      imageUrl: i.imageUrl,
      quantity: quantities.get(i.id) ?? DEFAULT_INGREDIENT_QUANTITY,
    }));
  }

  /** Résout des ids de recettes possédées (non supprimées) en résumés. */
  private async summariesByIds(
    userId: string,
    ids: string[],
  ): Promise<RecipeSummaryDto[]> {
    if (ids.length === 0) return [];
    const rows = await this.db
      .select()
      .from(recipes)
      .where(
        and(
          eq(recipes.authorId, userId),
          isNull(recipes.deletedAt),
          inArray(recipes.id, ids),
        ),
      )
      .orderBy(recipes.name);
    return rows.map(toSummary);
  }

  private async isUsedAsComponent(baseRecipeId: string): Promise<boolean> {
    const [used] = await this.db
      .select({ parentRecipeId: recipeComponents.parentRecipeId })
      .from(recipeComponents)
      .where(eq(recipeComponents.baseRecipeId, baseRecipeId))
      .limit(1);
    return used !== undefined;
  }

  private async findOwnedOrFail(userId: string, id: string): Promise<RecipeRow> {
    const [row] = await this.db
      .select()
      .from(recipes)
      .where(and(eq(recipes.id, id), isNull(recipes.deletedAt)));
    if (!row || row.authorId !== userId) {
      throw new NotFoundException('Recette introuvable');
    }
    return row;
  }
}
