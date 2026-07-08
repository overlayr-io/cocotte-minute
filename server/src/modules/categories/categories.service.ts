import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Inject,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { and, eq, isNull, ne, sql } from 'drizzle-orm';

import { DRIZZLE, DrizzleDB } from '../../db/drizzle.provider';
import {
  CATEGORY_MAX_DEPTH,
  DEFAULT_CATEGORIES,
  categories,
  type CategoryRow,
} from '../../db/schema/categories.schema';
import { RecipesService, type RecipeSummaryDto } from '../recipes/recipes.service';
import { CreateCategoryDto } from './dto/create-category.dto';
import { UpdateCategoryDto } from './dto/update-category.dto';

/** Représentation d'API (camelCase) — jamais la ligne Drizzle brute. */
export interface CategoryDto {
  id: string;
  name: string;
  icon: string | null;
  parentCategoryId: string | null;
  depth: number;
  isDefault: boolean;
  /**
   * Nombre de recettes rangées dans ce dossier. Câblé à la table pivot
   * `recipe_categories` (feature recettes, à venir) ; renvoie 0 tant que ce
   * pivot n'existe pas.
   */
  recipeCount: number;
  createdAt: string;
}

function toDto(row: CategoryRow, recipeCount = 0): CategoryDto {
  return {
    id: row.id,
    name: row.name,
    icon: row.icon,
    parentCategoryId: row.parentCategoryId,
    depth: row.depth,
    isDefault: row.isDefault,
    recipeCount,
    createdAt: row.createdAt.toISOString(),
  };
}

@Injectable()
export class CategoriesService {
  private readonly logger = new Logger(CategoriesService.name);

  constructor(
    @Inject(DRIZZLE) private readonly db: DrizzleDB,
    // Compteur de recettes par dossier (pivot recipe_categories), via le service
    // Recipes — dépendance à sens unique (Recipes n'importe pas Categories).
    private readonly recipesService: RecipesService,
  ) {}

  /**
   * Arborescence à plat de l'utilisateur (hors supprimées). Sème les dossiers
   * par défaut au premier accès d'un compte vierge. L'ordre (dossiers par défaut
   * d'abord, dans l'ordre du menu, puis dossiers créés) suit `created_at` ;
   * l'assemblage en arbre se fait côté mobile via `parent_category_id`.
   */
  async listMine(userId: string): Promise<CategoryDto[]> {
    await this.ensureDefaults(userId);
    const rows = await this.db
      .select()
      .from(categories)
      .where(and(eq(categories.ownerId, userId), isNull(categories.deletedAt)))
      .orderBy(categories.createdAt);
    const counts = await this.recipesService.countByCategoryIds(
      userId,
      rows.map((r) => r.id),
    );
    return rows.map((row) => toDto(row, counts.get(row.id) ?? 0));
  }

  /**
   * Recettes rangées dans un de mes dossiers. Vérifie d'abord que le dossier
   * m'appartient (404 sinon), puis délègue le listing au service Recipes —
   * dépendance à sens unique, cohérent avec `recipeCount`.
   */
  async listRecipes(
    userId: string,
    categoryId: string,
  ): Promise<RecipeSummaryDto[]> {
    await this.findOwnedOrFail(userId, categoryId);
    return this.recipesService.listByCategory(userId, categoryId);
  }

  /**
   * Déplie une sélection de dossiers en y ajoutant tous leurs descendants (récursif,
   * sous-dossiers de sous-dossiers inclus). Utilisé par la recherche avancée pour
   * qu'un filtre « /Plats » remonte aussi les recettes de « Plats / Pâtes », etc.
   * Charge l'arborescence du compte en une passe (pas de requête récursive, cohérent
   * avec `depth`) et lève si un id fourni n'appartient pas à l'utilisateur.
   */
  async expandWithDescendants(
    userId: string,
    categoryIds: string[],
  ): Promise<string[]> {
    if (categoryIds.length === 0) return [];
    const rows = await this.db
      .select({ id: categories.id, parentId: categories.parentCategoryId })
      .from(categories)
      .where(and(eq(categories.ownerId, userId), isNull(categories.deletedAt)));

    const owned = new Set(rows.map((r) => r.id));
    for (const id of categoryIds) {
      if (!owned.has(id)) {
        throw new NotFoundException('Dossier introuvable');
      }
    }

    const childrenOf = new Map<string, string[]>();
    for (const r of rows) {
      if (r.parentId) {
        const arr = childrenOf.get(r.parentId) ?? [];
        arr.push(r.id);
        childrenOf.set(r.parentId, arr);
      }
    }

    const out = new Set<string>();
    const stack = [...categoryIds];
    while (stack.length > 0) {
      const id = stack.pop()!;
      if (out.has(id)) continue;
      out.add(id);
      for (const child of childrenOf.get(id) ?? []) stack.push(child);
    }
    return [...out];
  }

  async create(userId: string, dto: CreateCategoryDto): Promise<CategoryDto> {
    let depth = 1;
    if (dto.parentCategoryId) {
      const parent = await this.findOwnedOrFail(userId, dto.parentCategoryId);
      depth = parent.depth + 1;
      if (depth > CATEGORY_MAX_DEPTH) {
        throw new BadRequestException(
          `Profondeur maximale atteinte (${CATEGORY_MAX_DEPTH} niveaux)`,
        );
      }
    }
    await this.assertNameAvailable(userId, dto.name, dto.parentCategoryId ?? null);

    const [row] = await this.db
      .insert(categories)
      .values({
        ownerId: userId,
        name: dto.name,
        icon: dto.icon ?? null,
        parentCategoryId: dto.parentCategoryId ?? null,
        depth,
      })
      .returning();
    return toDto(row);
  }

  async update(
    userId: string,
    id: string,
    dto: UpdateCategoryDto,
  ): Promise<CategoryDto> {
    const current = await this.findOwnedOrFail(userId, id);
    if (current.isDefault) {
      throw new ForbiddenException(
        'Un dossier par défaut ne peut pas être modifié',
      );
    }
    if (dto.name !== undefined) {
      await this.assertNameAvailable(
        userId,
        dto.name,
        current.parentCategoryId,
        id,
      );
    }

    const patch: Partial<Pick<CategoryRow, 'name' | 'icon'>> = {};
    if (dto.name !== undefined) patch.name = dto.name;
    if (dto.icon !== undefined) patch.icon = dto.icon;

    const [row] = await this.db
      .update(categories)
      .set({ ...patch, updatedAt: new Date() })
      .where(eq(categories.id, id))
      .returning();
    return toDto(row);
  }

  /**
   * Soft delete. Refusé pour les dossiers par défaut et bloqué si le dossier
   * n'est pas vide (sous-dossiers ou recettes rangées dedans).
   */
  async softDelete(userId: string, id: string): Promise<void> {
    const current = await this.findOwnedOrFail(userId, id);
    if (current.isDefault) {
      throw new ForbiddenException(
        'Un dossier par défaut ne peut pas être supprimé',
      );
    }
    if (await this.hasChildren(id)) {
      throw new ConflictException(
        'Ce dossier contient des sous-dossiers : videz-le d’abord',
      );
    }
    if (await this.hasRecipes(userId, id)) {
      throw new ConflictException(
        'Ce dossier contient des recettes : videz-le d’abord',
      );
    }
    await this.db
      .update(categories)
      .set({ deletedAt: new Date(), updatedAt: new Date() })
      .where(eq(categories.id, id));
  }

  /**
   * Hard delete de toutes les catégories d'un utilisateur ("repartir de zéro").
   * Les sous-dossiers partent en cascade (FK auto-référencée onDelete: cascade).
   * Exposé pour AccountService uniquement.
   */
  async deleteAllForUser(userId: string): Promise<void> {
    await this.db.delete(categories).where(eq(categories.ownerId, userId));
    this.logger.log(`Catégories supprimées pour l'utilisateur ${userId}`);
  }

  // --- privé -------------------------------------------------------------

  /**
   * Sème les 4 dossiers par défaut si le compte n'a encore aucune catégorie
   * (seeding paresseux au premier accès). Idempotent : ne fait rien si au moins
   * une catégorie existe déjà (même supprimée, un défaut n'étant jamais supprimé).
   */
  private async ensureDefaults(userId: string): Promise<void> {
    const [existing] = await this.db
      .select({ id: categories.id })
      .from(categories)
      .where(eq(categories.ownerId, userId))
      .limit(1);
    if (existing) return;

    await this.db.insert(categories).values(
      DEFAULT_CATEGORIES.map((c) => ({
        ownerId: userId,
        name: c.name,
        icon: c.icon,
        depth: 1,
        isDefault: true,
      })),
    );
    this.logger.log(`Dossiers par défaut semés pour l'utilisateur ${userId}`);
  }

  /**
   * Refuse un nom déjà porté (insensible à la casse) par un autre dossier frère
   * non supprimé (même parent). `exceptId` exclut le dossier en cours d'édition.
   */
  private async assertNameAvailable(
    userId: string,
    name: string,
    parentCategoryId: string | null,
    exceptId?: string,
  ): Promise<void> {
    const conditions = [
      eq(categories.ownerId, userId),
      isNull(categories.deletedAt),
      sql`lower(${categories.name}) = lower(${name})`,
      parentCategoryId === null
        ? isNull(categories.parentCategoryId)
        : eq(categories.parentCategoryId, parentCategoryId),
    ];
    if (exceptId) conditions.push(ne(categories.id, exceptId));

    const [existing] = await this.db
      .select({ id: categories.id })
      .from(categories)
      .where(and(...conditions));
    if (existing) {
      throw new ConflictException('Un dossier portant ce nom existe déjà ici');
    }
  }

  /** Vrai si le dossier a au moins un sous-dossier non supprimé. */
  private async hasChildren(id: string): Promise<boolean> {
    const [child] = await this.db
      .select({ id: categories.id })
      .from(categories)
      .where(
        and(eq(categories.parentCategoryId, id), isNull(categories.deletedAt)),
      )
      .limit(1);
    return child !== undefined;
  }

  /**
   * Vrai si au moins une recette (possédée, non supprimée) est rangée dans ce
   * dossier. Passe par le service Recipes (pivot `recipe_categories`) pour ne
   * pas interroger un domaine voisin en direct.
   */
  private async hasRecipes(userId: string, id: string): Promise<boolean> {
    const counts = await this.recipesService.countByCategoryIds(userId, [id]);
    return (counts.get(id) ?? 0) > 0;
  }

  /** Récupère une catégorie de l'utilisateur (non supprimée), ou lève. */
  private async findOwnedOrFail(
    userId: string,
    id: string,
  ): Promise<CategoryRow> {
    const [row] = await this.db
      .select()
      .from(categories)
      .where(and(eq(categories.id, id), isNull(categories.deletedAt)));
    if (!row || row.ownerId !== userId) {
      throw new NotFoundException('Dossier introuvable');
    }
    return row;
  }
}
