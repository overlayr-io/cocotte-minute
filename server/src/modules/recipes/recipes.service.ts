import {
  BadRequestException,
  ConflictException,
  Inject,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { and, asc, desc, eq, inArray, isNull, sql } from 'drizzle-orm';

import { DRIZZLE, DrizzleDB } from '../../db/drizzle.provider';
import {
  DEFAULT_INGREDIENT_QUANTITY,
  recipeCategories,
  recipeComponents,
  recipeIngredients,
  recipeSteps,
  recipeTags,
  recipes,
  stepIngredients,
  type RecipeRow,
  type RecipeStepRow,
} from '../../db/schema/recipes.schema';
import { IngredientsService } from '../ingredients/ingredients.service';
import { CreateRecipeDto } from './dto/create-recipe.dto';
import {
  CreateRecipeStepDto,
  UpdateRecipeStepDto,
} from './dto/recipe-relations.dto';
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

/** Bannière d'une étape (couleur/icône dérivées du type côté client). */
export interface RecipeStepBannerDto {
  type: string;
  text: string;
}

/** Étape figée affichée dans un bloc référence de base (lecture seule). */
export interface RecipeExpandedStepDto {
  number: number;
  description: string;
  banner: RecipeStepBannerDto | null;
}

/** Étape texte de la recette (éditable, réordonnable). */
export interface RecipeTextStepDto {
  kind: 'text';
  id: string;
  number: number;
  description: string;
  banner: RecipeStepBannerDto | null;
  ingredients: RecipeIngredientLineDto[];
}

/**
 * Bloc référence de base : les étapes de la recette de base, dépliées et
 * numérotées dans la continuité (jamais copiées ; internes non réordonnables).
 */
export interface RecipeBaseRefStepDto {
  kind: 'base_ref';
  id: string;
  baseRecipeId: string;
  baseRecipeName: string;
  steps: RecipeExpandedStepDto[];
}

export type RecipeStepDto = RecipeTextStepDto | RecipeBaseRefStepDto;

/** Recette possédée + ses ingrédients directs, pour générer une liste de courses. */
export interface RecipeForShoppingListDto {
  id: string;
  name: string;
  photoUrl: string | null;
  servings: number;
  ingredients: RecipeIngredientLineDto[];
}

/** Fiche détail complète. */
export interface RecipeDetailDto extends RecipeSummaryDto {
  authorId: string;
  description: string | null;
  /** Recette de base utilisée comme composant ailleurs → `is_base` verrouillé. */
  isLocked: boolean;
  ingredients: RecipeIngredientLineDto[];
  /** Étapes (arbre déjà déplié + numéroté ; réfs de base résolues récursivement). */
  steps: RecipeStepDto[];
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
    const ingredientMap = new Map(ingredientLines.map((l) => [l.id, l]));
    const steps = await this.buildRecipeSteps(id, ingredientMap);
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
      steps,
      components,
      usedIn,
      categoryIds: categoryRows.map((r) => r.categoryId),
      tagIds: tagRows.map((r) => r.tagId),
    };
  }

  /**
   * Recettes possédées (non supprimées) + leurs ingrédients directs, pour générer
   * une liste de courses (feature liste-courses-auto). N'inclut PAS les ingrédients
   * des sous-recettes (`recipe_components`) — cohérent avec `getDetail` aujourd'hui ;
   * le dépliage récursif des composants relèvera d'une itération dédiée. Lève si un
   * id demandé n'appartient pas à l'utilisateur (ou est supprimé). Exposé à
   * ShoppingListsService (isolation des domaines : jamais d'accès direct au schéma).
   */
  async listForShoppingList(
    userId: string,
    recipeIds: string[],
  ): Promise<RecipeForShoppingListDto[]> {
    if (recipeIds.length === 0) return [];
    const uniqueIds = [...new Set(recipeIds)];
    const rows = await this.db
      .select()
      .from(recipes)
      .where(
        and(
          eq(recipes.authorId, userId),
          isNull(recipes.deletedAt),
          inArray(recipes.id, uniqueIds),
        ),
      );
    if (rows.length !== uniqueIds.length) {
      throw new NotFoundException('Recette introuvable');
    }

    const ingRows = await this.db
      .select({
        recipeId: recipeIngredients.recipeId,
        ingredientId: recipeIngredients.ingredientId,
        quantity: recipeIngredients.quantity,
      })
      .from(recipeIngredients)
      .where(inArray(recipeIngredients.recipeId, uniqueIds));

    // Hydratation en une passe (nom/unité/image via le service Ingredients).
    const allIngredientIds = [...new Set(ingRows.map((r) => r.ingredientId))];
    const owned = await this.ingredientsService.listByIds(userId, allIngredientIds);
    const ingredientMap = new Map(owned.map((i) => [i.id, i]));

    const linesByRecipe = new Map<string, RecipeIngredientLineDto[]>();
    for (const r of ingRows) {
      const info = ingredientMap.get(r.ingredientId);
      if (!info) continue; // ingrédient supprimé entre-temps → ignoré
      const arr = linesByRecipe.get(r.recipeId) ?? [];
      arr.push({
        id: info.id,
        name: info.name,
        unit: info.unit,
        imageUrl: info.imageUrl,
        quantity: r.quantity,
      });
      linesByRecipe.set(r.recipeId, arr);
    }

    return rows.map((row) => ({
      id: row.id,
      name: row.name,
      photoUrl: row.photoUrl,
      servings: row.servings,
      ingredients: linesByRecipe.get(row.id) ?? [],
    }));
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

  // --- étapes ------------------------------------------------------------

  /**
   * Ajoute une étape : soit texte (description + bannière/ingrédients optionnels),
   * soit une référence de base (`baseRecipeRefId` seul). Exclusivité + règles de
   * référence (base possédée, is_base, pas de cycle) vérifiées ici.
   */
  async addStep(
    userId: string,
    recipeId: string,
    dto: CreateRecipeStepDto,
  ): Promise<void> {
    await this.findOwnedOrFail(userId, recipeId);
    const isRef = !!dto.baseRecipeRefId;
    if (isRef) {
      if (
        dto.description ||
        dto.bannerType ||
        dto.bannerText ||
        (dto.ingredientIds && dto.ingredientIds.length > 0)
      ) {
        throw new BadRequestException(
          'Une référence de base ne peut pas porter de description, de bannière ni d’ingrédients',
        );
      }
      await this.validateBaseRef(userId, recipeId, dto.baseRecipeRefId!);
    } else {
      const description = dto.description?.trim();
      if (!description) {
        throw new BadRequestException('La description de l’étape est obligatoire');
      }
      this.validateBanner(dto.bannerType, dto.bannerText);
      if (dto.ingredientIds && dto.ingredientIds.length > 0) {
        await this.assertIngredientsOnRecipe(recipeId, dto.ingredientIds);
      }
    }

    const position = await this.nextStepPosition(recipeId);
    const [step] = await this.db
      .insert(recipeSteps)
      .values({
        recipeId,
        position,
        description: isRef ? null : dto.description!.trim(),
        bannerType: isRef ? null : (dto.bannerType ?? null),
        bannerText:
          !isRef && dto.bannerType ? (dto.bannerText ?? '').trim() : null,
        baseRecipeRefId: dto.baseRecipeRefId ?? null,
      })
      .returning({ id: recipeSteps.id });

    if (!isRef && dto.ingredientIds && dto.ingredientIds.length > 0) {
      await this.db
        .insert(stepIngredients)
        .values(dto.ingredientIds.map((ingredientId) => ({ stepId: step.id, ingredientId })));
    }
  }

  /** Import texte : chaque entrée non vide devient une étape texte, à la suite. */
  async importSteps(
    userId: string,
    recipeId: string,
    descriptions: string[],
  ): Promise<void> {
    await this.findOwnedOrFail(userId, recipeId);
    const clean = descriptions.map((d) => d.trim()).filter((d) => d.length > 0);
    if (clean.length === 0) {
      throw new BadRequestException('Aucune étape à créer');
    }
    let position = await this.nextStepPosition(recipeId);
    await this.db
      .insert(recipeSteps)
      .values(clean.map((description) => ({ recipeId, position: position++, description })));
  }

  /** Édite une étape texte (description, bannière). `bannerType: null` la retire. */
  async updateStep(
    userId: string,
    recipeId: string,
    stepId: string,
    dto: UpdateRecipeStepDto,
  ): Promise<void> {
    await this.findOwnedOrFail(userId, recipeId);
    const step = await this.findStepOrFail(recipeId, stepId);
    if (step.baseRecipeRefId) {
      throw new BadRequestException('Une référence de base n’est pas éditable');
    }

    const patch: Partial<RecipeStepRow> = { updatedAt: new Date() };
    if (dto.description !== undefined) {
      const d = dto.description.trim();
      if (!d) throw new BadRequestException('La description de l’étape est obligatoire');
      patch.description = d;
    }
    if (dto.bannerType !== undefined) {
      if (dto.bannerType === null) {
        patch.bannerType = null;
        patch.bannerText = null;
      } else {
        const text = (dto.bannerText ?? step.bannerText ?? '').trim();
        if (!text) throw new BadRequestException('Le texte de la bannière est obligatoire');
        patch.bannerType = dto.bannerType;
        patch.bannerText = text;
      }
    } else if (dto.bannerText !== undefined && dto.bannerText !== null) {
      if (!step.bannerType) {
        throw new BadRequestException('Une bannière requiert un type');
      }
      const text = dto.bannerText.trim();
      if (!text) throw new BadRequestException('Le texte de la bannière est obligatoire');
      patch.bannerText = text;
    }

    await this.db.update(recipeSteps).set(patch).where(eq(recipeSteps.id, stepId));
  }

  async removeStep(userId: string, recipeId: string, stepId: string): Promise<void> {
    await this.findOwnedOrFail(userId, recipeId);
    await this.findStepOrFail(recipeId, stepId);
    await this.db
      .delete(recipeSteps)
      .where(and(eq(recipeSteps.id, stepId), eq(recipeSteps.recipeId, recipeId)));
  }

  /** Réordonne les étapes de premier niveau (drag & drop). Doit lister toutes les étapes. */
  async reorderSteps(
    userId: string,
    recipeId: string,
    stepIds: string[],
  ): Promise<void> {
    await this.findOwnedOrFail(userId, recipeId);
    const rows = await this.db
      .select({ id: recipeSteps.id })
      .from(recipeSteps)
      .where(eq(recipeSteps.recipeId, recipeId));
    const owned = new Set(rows.map((r) => r.id));
    const unique = new Set(stepIds);
    if (
      unique.size !== stepIds.length ||
      stepIds.length !== owned.size ||
      stepIds.some((id) => !owned.has(id))
    ) {
      throw new BadRequestException('Liste d’étapes invalide pour le réordonnancement');
    }
    for (let i = 0; i < stepIds.length; i++) {
      await this.db
        .update(recipeSteps)
        .set({ position: i, updatedAt: new Date() })
        .where(and(eq(recipeSteps.id, stepIds[i]), eq(recipeSteps.recipeId, recipeId)));
    }
  }

  /** Remplace la sélection d'ingrédients d'une étape texte (sous-ensemble recette). */
  async setStepIngredients(
    userId: string,
    recipeId: string,
    stepId: string,
    ingredientIds: string[],
  ): Promise<void> {
    await this.findOwnedOrFail(userId, recipeId);
    const step = await this.findStepOrFail(recipeId, stepId);
    if (step.baseRecipeRefId) {
      throw new BadRequestException('Une référence de base n’a pas d’ingrédients propres');
    }
    if (ingredientIds.length > 0) {
      await this.assertIngredientsOnRecipe(recipeId, ingredientIds);
    }
    await this.db.delete(stepIngredients).where(eq(stepIngredients.stepId, stepId));
    if (ingredientIds.length > 0) {
      await this.db
        .insert(stepIngredients)
        .values(ingredientIds.map((ingredientId) => ({ stepId, ingredientId })));
    }
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

  // --- étapes : dépliage & validations ----------------------------------

  /**
   * Construit l'arbre d'étapes affichable : étapes texte numérotées + blocs
   * référence de base dépliés récursivement (numérotation continue, réfs
   * supprimées omises, anti-cycle). `ingredientMap` = ingrédients de la recette.
   */
  private async buildRecipeSteps(
    recipeId: string,
    ingredientMap: Map<string, RecipeIngredientLineDto>,
  ): Promise<RecipeStepDto[]> {
    const ownRows = await this.db
      .select()
      .from(recipeSteps)
      .where(eq(recipeSteps.recipeId, recipeId))
      .orderBy(asc(recipeSteps.position));

    const textIds = ownRows.filter((r) => !r.baseRecipeRefId).map((r) => r.id);
    const siRows = textIds.length
      ? await this.db
          .select()
          .from(stepIngredients)
          .where(inArray(stepIngredients.stepId, textIds))
      : [];
    const ingredientIdsByStep = new Map<string, string[]>();
    for (const si of siRows) {
      const arr = ingredientIdsByStep.get(si.stepId);
      if (arr) arr.push(si.ingredientId);
      else ingredientIdsByStep.set(si.stepId, [si.ingredientId]);
    }

    const counter = { n: 0 };
    const out: RecipeStepDto[] = [];
    for (const r of ownRows) {
      if (r.baseRecipeRefId) {
        const base = await this.findBaseForDisplay(r.baseRecipeRefId);
        if (!base) continue; // référence supprimée → omise
        const steps = await this.expandBaseSteps(
          r.baseRecipeRefId,
          new Set([recipeId]),
          counter,
        );
        out.push({
          kind: 'base_ref',
          id: r.id,
          baseRecipeId: base.id,
          baseRecipeName: base.name,
          steps,
        });
      } else if (r.description) {
        const ingredients = (ingredientIdsByStep.get(r.id) ?? [])
          .map((id) => ingredientMap.get(id))
          .filter((x): x is RecipeIngredientLineDto => x !== undefined);
        out.push({
          kind: 'text',
          id: r.id,
          number: ++counter.n,
          description: r.description,
          banner: this.toBanner(r),
          ingredients,
        });
      }
    }
    return out;
  }

  /** Déplie (récursivement, à plat) les étapes d'une recette de base référencée. */
  private async expandBaseSteps(
    baseId: string,
    visited: Set<string>,
    counter: { n: number },
  ): Promise<RecipeExpandedStepDto[]> {
    if (visited.has(baseId)) return [];
    const [base] = await this.db
      .select({ id: recipes.id })
      .from(recipes)
      .where(and(eq(recipes.id, baseId), isNull(recipes.deletedAt)));
    if (!base) return [];
    const nextVisited = new Set(visited).add(baseId);
    const rows = await this.db
      .select()
      .from(recipeSteps)
      .where(eq(recipeSteps.recipeId, baseId))
      .orderBy(asc(recipeSteps.position));

    const out: RecipeExpandedStepDto[] = [];
    for (const r of rows) {
      if (r.baseRecipeRefId) {
        out.push(...(await this.expandBaseSteps(r.baseRecipeRefId, nextVisited, counter)));
      } else if (r.description) {
        out.push({
          number: ++counter.n,
          description: r.description,
          banner: this.toBanner(r),
        });
      }
    }
    return out;
  }

  private toBanner(row: RecipeStepRow): RecipeStepBannerDto | null {
    return row.bannerType ? { type: row.bannerType, text: row.bannerText ?? '' } : null;
  }

  private async findBaseForDisplay(
    id: string,
  ): Promise<{ id: string; name: string } | null> {
    const [row] = await this.db
      .select({ id: recipes.id, name: recipes.name })
      .from(recipes)
      .where(and(eq(recipes.id, id), isNull(recipes.deletedAt)));
    return row ?? null;
  }

  private async validateBaseRef(
    userId: string,
    recipeId: string,
    baseId: string,
  ): Promise<void> {
    if (baseId === recipeId) {
      throw new ConflictException('Une recette ne peut pas se référencer elle-même');
    }
    const base = await this.findOwnedOrFail(userId, baseId);
    if (!base.isBase) {
      throw new ConflictException(
        'Seule une recette de base peut être référencée dans une étape',
      );
    }
    if (await this.refWouldCycle(recipeId, baseId, new Set())) {
      throw new ConflictException('Cette référence créerait un cycle entre recettes');
    }
  }

  /** Vrai si `baseId` référence (transitivement) `targetRecipeId` via ses étapes. */
  private async refWouldCycle(
    targetRecipeId: string,
    baseId: string,
    visited: Set<string>,
  ): Promise<boolean> {
    if (baseId === targetRecipeId) return true;
    if (visited.has(baseId)) return false;
    visited.add(baseId);
    const rows = await this.db
      .select({ ref: recipeSteps.baseRecipeRefId })
      .from(recipeSteps)
      .where(eq(recipeSteps.recipeId, baseId));
    for (const r of rows) {
      if (r.ref && (await this.refWouldCycle(targetRecipeId, r.ref, visited))) {
        return true;
      }
    }
    return false;
  }

  private validateBanner(type?: string | null, text?: string | null): void {
    if (type && !(text && text.trim())) {
      throw new BadRequestException('Le texte de la bannière est obligatoire');
    }
    if (!type && text && text.trim()) {
      throw new BadRequestException('Une bannière requiert un type');
    }
  }

  private async assertIngredientsOnRecipe(
    recipeId: string,
    ingredientIds: string[],
  ): Promise<void> {
    const rows = await this.db
      .select({ id: recipeIngredients.ingredientId })
      .from(recipeIngredients)
      .where(
        and(
          eq(recipeIngredients.recipeId, recipeId),
          inArray(recipeIngredients.ingredientId, ingredientIds),
        ),
      );
    const present = new Set(rows.map((r) => r.id));
    for (const id of ingredientIds) {
      if (!present.has(id)) {
        throw new BadRequestException('Ingrédient absent de la recette');
      }
    }
  }

  private async nextStepPosition(recipeId: string): Promise<number> {
    const [row] = await this.db
      .select({ max: sql<number>`coalesce(max(${recipeSteps.position}), -1)::int` })
      .from(recipeSteps)
      .where(eq(recipeSteps.recipeId, recipeId));
    return (row?.max ?? -1) + 1;
  }

  private async findStepOrFail(
    recipeId: string,
    stepId: string,
  ): Promise<RecipeStepRow> {
    const [row] = await this.db
      .select()
      .from(recipeSteps)
      .where(and(eq(recipeSteps.id, stepId), eq(recipeSteps.recipeId, recipeId)));
    if (!row) {
      throw new NotFoundException('Étape introuvable');
    }
    return row;
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
