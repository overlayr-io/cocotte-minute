import {
  BadRequestException,
  Inject,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { and, desc, eq, inArray, isNull, sql } from 'drizzle-orm';

import { PremiumLimitException } from '../../common/errors/premium-limit.exception';
import { DRIZZLE, DrizzleDB } from '../../db/drizzle.provider';
import {
  shoppingListItems,
  shoppingListRecipes,
  shoppingLists,
  type ShoppingItemSource,
  type ShoppingListItemRow,
  type ShoppingListRow,
} from '../../db/schema/shopping-lists.schema';
import { PremiumService } from '../billing/premium.service';
import { IngredientsService } from '../ingredients/ingredients.service';
import { RecipesService } from '../recipes/recipes.service';
import { CreateShoppingListDto } from './dto/create-shopping-list.dto';
import {
  AddShoppingListItemDto,
  UpdateShoppingListItemDto,
} from './dto/shopping-list-item.dto';
import { UpdateShoppingListDto } from './dto/update-shopping-list.dto';
import { aggregateShoppingItems } from './shopping-list-aggregation';

/** Représentations d'API (camelCase) — jamais la ligne Drizzle brute. */
export interface ShoppingListItemDto {
  id: string;
  ingredientId: string | null;
  customLabel: string | null;
  name: string;
  quantity: number | null;
  unit: string | null;
  isChecked: boolean;
  replacedByAlternativeId: string | null;
  replacementName: string | null;
  sources: ShoppingItemSource[];
  position: number;
  clientUpdatedAt: string;
}

export interface ShoppingListRecipeDto {
  recipeId: string;
  recipeName: string;
  photoUrl: string | null;
  servings: number;
}

export interface ShoppingListSummaryDto {
  id: string;
  name: string;
  isArchived: boolean;
  itemCount: number;
  checkedCount: number;
  recipeCount: number;
  clientUpdatedAt: string;
  createdAt: string;
}

export interface ShoppingListDetailDto extends ShoppingListSummaryDto {
  items: ShoppingListItemDto[];
  recipes: ShoppingListRecipeDto[];
}

function toItemDto(row: ShoppingListItemRow): ShoppingListItemDto {
  return {
    id: row.id,
    ingredientId: row.ingredientId,
    customLabel: row.customLabel,
    name: row.name,
    quantity: row.quantity,
    unit: row.unit,
    isChecked: row.isChecked,
    replacedByAlternativeId: row.replacedByAlternativeId,
    replacementName: row.replacementName,
    sources: row.sources,
    position: row.position,
    clientUpdatedAt: row.clientUpdatedAt.toISOString(),
  };
}

@Injectable()
export class ShoppingListsService {
  private readonly logger = new Logger(ShoppingListsService.name);

  constructor(
    @Inject(DRIZZLE) private readonly db: DrizzleDB,
    // Isolation des domaines : agrégation via le service Recipes, résolution des
    // alternatives via le service Ingredients — jamais d'accès à leur schéma.
    private readonly recipesService: RecipesService,
    private readonly ingredientsService: IngredientsService,
    private readonly premiumService: PremiumService,
  ) {}

  /** Mes listes actives (non supprimées), les plus récentes d'abord. */
  async listMine(userId: string): Promise<ShoppingListSummaryDto[]> {
    const lists = await this.db
      .select()
      .from(shoppingLists)
      .where(and(eq(shoppingLists.ownerId, userId), isNull(shoppingLists.deletedAt)))
      .orderBy(desc(shoppingLists.createdAt));
    if (lists.length === 0) return [];

    const ids = lists.map((l) => l.id);
    const [itemCounts, recipeCounts] = await Promise.all([
      this.db
        .select({
          listId: shoppingListItems.shoppingListId,
          total: sql<number>`count(*)::int`,
          checked: sql<number>`count(*) filter (where ${shoppingListItems.isChecked})::int`,
        })
        .from(shoppingListItems)
        .where(inArray(shoppingListItems.shoppingListId, ids))
        .groupBy(shoppingListItems.shoppingListId),
      this.db
        .select({
          listId: shoppingListRecipes.shoppingListId,
          total: sql<number>`count(*)::int`,
        })
        .from(shoppingListRecipes)
        .where(inArray(shoppingListRecipes.shoppingListId, ids))
        .groupBy(shoppingListRecipes.shoppingListId),
    ]);
    const itemMap = new Map(itemCounts.map((r) => [r.listId, r]));
    const recipeMap = new Map(recipeCounts.map((r) => [r.listId, r.total]));

    return lists.map((row) =>
      this.toSummary(
        row,
        itemMap.get(row.id)?.total ?? 0,
        itemMap.get(row.id)?.checked ?? 0,
        recipeMap.get(row.id) ?? 0,
      ),
    );
  }

  /** Détail complet d'une liste : articles (ordonnés) + recettes sources. */
  async getDetail(userId: string, id: string): Promise<ShoppingListDetailDto> {
    const list = await this.findOwnedOrFail(userId, id);
    const [items, recipes] = await Promise.all([
      this.db
        .select()
        .from(shoppingListItems)
        .where(eq(shoppingListItems.shoppingListId, id))
        .orderBy(shoppingListItems.position),
      this.db
        .select()
        .from(shoppingListRecipes)
        .where(eq(shoppingListRecipes.shoppingListId, id)),
    ]);
    const checked = items.filter((i) => i.isChecked).length;
    return {
      ...this.toSummary(list, items.length, checked, recipes.length),
      items: items.map(toItemDto),
      recipes: recipes.map((r) => ({
        recipeId: r.recipeId,
        recipeName: r.recipeName,
        photoUrl: r.photoUrl,
        servings: r.servings,
      })),
    };
  }

  /**
   * Génère une liste de courses à partir de recettes sélectionnées (5b → 5d) :
   * met à l'échelle par nombre de parts, exclut le placard, additionne les
   * ingrédients communs. Garde freemium serveur : **une seule liste active** en
   * gratuit (il faut vider l'actuelle avant d'en créer une nouvelle).
   */
  async generate(userId: string, dto: CreateShoppingListDto): Promise<ShoppingListDetailDto> {
    // Garde freemium : levée pour les comptes premium (listes multiples).
    if (!(await this.premiumService.isPremium(userId))) {
      await this.assertNoActiveList(userId);
    }

    const selections = dto.recipes;
    const recipeData = await this.recipesService.listForShoppingList(
      userId,
      selections.map((r) => r.recipeId),
    );
    const dataById = new Map(recipeData.map((r) => [r.id, r]));

    const aggregated = aggregateShoppingItems(
      selections.map((sel) => {
        const data = dataById.get(sel.recipeId)!;
        return {
          recipeId: sel.recipeId,
          baseServings: data.servings,
          chosenServings: sel.servings,
          ingredients: data.ingredients.map((i) => ({
            ingredientId: i.id,
            name: i.name,
            unit: i.unit,
            quantity: i.quantity,
          })),
        };
      }),
      dto.pantryIngredientIds ?? [],
    );

    const clientUpdatedAt = this.parseClientTs(dto.clientUpdatedAt);

    return this.db.transaction(async (tx) => {
      const [list] = await tx
        .insert(shoppingLists)
        .values({
          id: dto.id,
          ownerId: userId,
          name: dto.name,
          clientUpdatedAt,
        })
        .returning();

      await tx.insert(shoppingListRecipes).values(
        selections.map((sel) => {
          const data = dataById.get(sel.recipeId)!;
          return {
            shoppingListId: list.id,
            recipeId: sel.recipeId,
            recipeName: data.name,
            photoUrl: data.photoUrl,
            servings: sel.servings,
          };
        }),
      );

      if (aggregated.length > 0) {
        await tx.insert(shoppingListItems).values(
          aggregated.map((item, index) => ({
            shoppingListId: list.id,
            ingredientId: item.ingredientId,
            name: item.name,
            quantity: item.quantity,
            unit: item.unit,
            sources: item.sources,
            position: index,
            clientUpdatedAt,
          })),
        );
      }

      this.logger.log(
        `Liste de courses générée (${aggregated.length} articles) pour l'utilisateur ${userId}`,
      );
      // Relecture dans la transaction pour un DTO cohérent.
      const items = await tx
        .select()
        .from(shoppingListItems)
        .where(eq(shoppingListItems.shoppingListId, list.id))
        .orderBy(shoppingListItems.position);
      const checked = items.filter((i) => i.isChecked).length;
      return {
        ...this.toSummary(list, items.length, checked, selections.length),
        items: items.map(toItemDto),
        recipes: selections.map((sel) => {
          const data = dataById.get(sel.recipeId)!;
          return {
            recipeId: sel.recipeId,
            recipeName: data.name,
            photoUrl: data.photoUrl,
            servings: sel.servings,
          };
        }),
      };
    });
  }

  /** Renomme une liste (résolution « le plus récent gagne » via clientUpdatedAt). */
  async rename(
    userId: string,
    id: string,
    dto: UpdateShoppingListDto,
  ): Promise<ShoppingListSummaryDto> {
    const list = await this.findOwnedOrFail(userId, id);
    if (dto.name === undefined) return this.summaryOf(list);

    const incoming = this.parseClientTs(dto.clientUpdatedAt);
    if (this.isStale(incoming, list.clientUpdatedAt)) {
      return this.summaryOf(list);
    }
    const [row] = await this.db
      .update(shoppingLists)
      .set({ name: dto.name, clientUpdatedAt: incoming, updatedAt: new Date() })
      .where(eq(shoppingLists.id, id))
      .returning();
    return this.summaryOf(row);
  }

  /** « Vider » une liste = soft delete (pas d'historique en gratuit). */
  async clear(userId: string, id: string): Promise<void> {
    await this.findOwnedOrFail(userId, id);
    await this.db
      .update(shoppingLists)
      .set({ deletedAt: new Date(), updatedAt: new Date() })
      .where(eq(shoppingLists.id, id));
  }

  /** Ajoute un article libre (hors recette) — 5e « Ajouter un article ». */
  async addItem(
    userId: string,
    id: string,
    dto: AddShoppingListItemDto,
  ): Promise<ShoppingListItemDto> {
    await this.findOwnedOrFail(userId, id);
    const position = await this.nextItemPosition(id);
    const [row] = await this.db
      .insert(shoppingListItems)
      .values({
        id: dto.id,
        shoppingListId: id,
        customLabel: dto.customLabel,
        name: dto.customLabel,
        quantity: dto.quantity ?? null,
        unit: dto.unit ?? null,
        sources: [],
        position,
        clientUpdatedAt: this.parseClientTs(dto.clientUpdatedAt),
      })
      .returning();
    await this.touch(id);
    return toItemDto(row);
  }

  /**
   * Coche/décoche un article et/ou lui applique une alternative « introuvable en
   * magasin » (5h). L'alternative doit être une alternative **déclarée** de
   * l'ingrédient de l'article et ne touche que l'affichage de cette liste — jamais
   * la recette. `replacedByAlternativeId: null` réinitialise vers l'original.
   * Résolution « le plus récent gagne » via clientUpdatedAt.
   */
  async updateItem(
    userId: string,
    id: string,
    itemId: string,
    dto: UpdateShoppingListItemDto,
  ): Promise<ShoppingListItemDto> {
    await this.findOwnedOrFail(userId, id);
    const item = await this.findItemOrFail(id, itemId);

    const incoming = this.parseClientTs(dto.clientUpdatedAt);
    if (this.isStale(incoming, item.clientUpdatedAt)) {
      return toItemDto(item);
    }

    const patch: Partial<ShoppingListItemRow> = {};
    if (dto.isChecked !== undefined) patch.isChecked = dto.isChecked;

    if (dto.replacedByAlternativeId !== undefined) {
      if (dto.replacedByAlternativeId === null) {
        patch.replacedByAlternativeId = null;
        patch.replacementName = null;
      } else {
        if (!item.ingredientId) {
          throw new BadRequestException(
            "Un article libre n'a pas d'alternative",
          );
        }
        const alternative = await this.ingredientsService.resolveAlternative(
          userId,
          item.ingredientId,
          dto.replacedByAlternativeId,
        );
        if (!alternative) {
          throw new BadRequestException(
            'Alternative non reconnue pour cet ingrédient',
          );
        }
        patch.replacedByAlternativeId = alternative.id;
        patch.replacementName = alternative.name;
      }
    }

    const [row] = await this.db
      .update(shoppingListItems)
      .set({ ...patch, clientUpdatedAt: incoming, updatedAt: new Date() })
      .where(eq(shoppingListItems.id, itemId))
      .returning();
    await this.touch(id);
    return toItemDto(row);
  }

  async removeItem(userId: string, id: string, itemId: string): Promise<void> {
    await this.findOwnedOrFail(userId, id);
    await this.findItemOrFail(id, itemId);
    await this.db.delete(shoppingListItems).where(eq(shoppingListItems.id, itemId));
    await this.touch(id);
  }

  /**
   * Hard delete de toutes les listes d'un utilisateur ("repartir de zéro").
   * Articles et recettes partent en cascade (FK onDelete: cascade). Exposé pour
   * AccountService uniquement.
   */
  async deleteAllForUser(userId: string): Promise<void> {
    await this.db.delete(shoppingLists).where(eq(shoppingLists.ownerId, userId));
    this.logger.log(`Listes de courses supprimées pour l'utilisateur ${userId}`);
  }

  // --- privé -------------------------------------------------------------

  private toSummary(
    row: ShoppingListRow,
    itemCount: number,
    checkedCount: number,
    recipeCount: number,
  ): ShoppingListSummaryDto {
    return {
      id: row.id,
      name: row.name,
      isArchived: row.archivedAt !== null,
      itemCount,
      checkedCount,
      recipeCount,
      clientUpdatedAt: row.clientUpdatedAt.toISOString(),
      createdAt: row.createdAt.toISOString(),
    };
  }

  /** Résumé sans recompter (rename/no-op) : les compteurs ne changent pas ici. */
  private async summaryOf(row: ShoppingListRow): Promise<ShoppingListSummaryDto> {
    const [items, recipes] = await Promise.all([
      this.db
        .select({
          total: sql<number>`count(*)::int`,
          checked: sql<number>`count(*) filter (where ${shoppingListItems.isChecked})::int`,
        })
        .from(shoppingListItems)
        .where(eq(shoppingListItems.shoppingListId, row.id)),
      this.db
        .select({ total: sql<number>`count(*)::int` })
        .from(shoppingListRecipes)
        .where(eq(shoppingListRecipes.shoppingListId, row.id)),
    ]);
    return this.toSummary(
      row,
      items[0]?.total ?? 0,
      items[0]?.checked ?? 0,
      recipes[0]?.total ?? 0,
    );
  }

  /** Garde freemium : refuse une nouvelle liste si une liste active existe déjà. */
  private async assertNoActiveList(userId: string): Promise<void> {
    const [active] = await this.db
      .select({ id: shoppingLists.id })
      .from(shoppingLists)
      .where(
        and(
          eq(shoppingLists.ownerId, userId),
          isNull(shoppingLists.deletedAt),
          isNull(shoppingLists.archivedAt),
        ),
      )
      .limit(1);
    if (active) {
      throw new PremiumLimitException(
        'PREMIUM_LIMIT_SHOPPING_LISTS',
        1,
        1,
        'Tu as déjà une liste active : vide-la avant d’en créer une nouvelle (plusieurs listes = Pro).',
      );
    }
  }

  private parseClientTs(iso?: string): Date {
    return iso ? new Date(iso) : new Date();
  }

  /** Vrai si la modif entrante est plus ancienne (ou égale) que celle stockée. */
  private isStale(incoming: Date, stored: Date): boolean {
    return incoming.getTime() <= stored.getTime();
  }

  private async nextItemPosition(listId: string): Promise<number> {
    const [row] = await this.db
      .select({ max: sql<number>`coalesce(max(${shoppingListItems.position}), -1)::int` })
      .from(shoppingListItems)
      .where(eq(shoppingListItems.shoppingListId, listId));
    return (row?.max ?? -1) + 1;
  }

  /** Bump `updated_at` de la liste après une modif d'article (fraîcheur du cache). */
  private async touch(listId: string): Promise<void> {
    await this.db
      .update(shoppingLists)
      .set({ updatedAt: new Date() })
      .where(eq(shoppingLists.id, listId));
  }

  private async findOwnedOrFail(userId: string, id: string): Promise<ShoppingListRow> {
    const [row] = await this.db
      .select()
      .from(shoppingLists)
      .where(and(eq(shoppingLists.id, id), isNull(shoppingLists.deletedAt)));
    if (!row || row.ownerId !== userId) {
      throw new NotFoundException('Liste de courses introuvable');
    }
    return row;
  }

  private async findItemOrFail(
    listId: string,
    itemId: string,
  ): Promise<ShoppingListItemRow> {
    const [row] = await this.db
      .select()
      .from(shoppingListItems)
      .where(
        and(
          eq(shoppingListItems.id, itemId),
          eq(shoppingListItems.shoppingListId, listId),
        ),
      );
    if (!row) {
      throw new NotFoundException('Article introuvable');
    }
    return row;
  }
}
