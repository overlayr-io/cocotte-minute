import {
  ConflictException,
  ForbiddenException,
  Inject,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { and, eq, inArray, isNull, or } from 'drizzle-orm';

import { DRIZZLE, DrizzleDB } from '../../db/drizzle.provider';
import { ingredientAlternatives } from '../../db/schema/ingredient-alternatives.schema';
import {
  ingredients,
  type IngredientRow,
  type IngredientUnit,
} from '../../db/schema/ingredients.schema';
import { CreateIngredientDto } from './dto/create-ingredient.dto';
import { UpdateIngredientDto } from './dto/update-ingredient.dto';

/** Représentation d'API (camelCase) — jamais la ligne Drizzle brute. */
export interface IngredientDto {
  id: string;
  name: string;
  unit: IngredientUnit;
  imageUrl: string | null;
  isSystem: boolean;
  importedFromId: string | null;
  createdAt: string;
}

export interface SystemIngredientDto extends IngredientDto {
  /** true si l'utilisateur possède déjà une copie importée de cet ingrédient système. */
  alreadyImported: boolean;
}

export interface IngredientDetailDto extends IngredientDto {
  alternatives: IngredientDto[];
}

function toDto(row: IngredientRow): IngredientDto {
  return {
    id: row.id,
    name: row.name,
    unit: row.unit,
    imageUrl: row.imageUrl,
    isSystem: row.ownerId === null,
    importedFromId: row.importedFromId,
    createdAt: row.createdAt.toISOString(),
  };
}

/** Canonise une paire d'ids pour la relation symétrique (low < high). */
function canonicalPair(a: string, b: string): { lowId: string; highId: string } {
  return a < b ? { lowId: a, highId: b } : { lowId: b, highId: a };
}

@Injectable()
export class IngredientsService {
  private readonly logger = new Logger(IngredientsService.name);

  constructor(@Inject(DRIZZLE) private readonly db: DrizzleDB) {}

  /** Ingrédients de l'utilisateur (copies importées + customs), hors supprimés. */
  async listMine(userId: string): Promise<IngredientDto[]> {
    const rows = await this.db
      .select()
      .from(ingredients)
      .where(and(eq(ingredients.ownerId, userId), isNull(ingredients.deletedAt)))
      .orderBy(ingredients.name);
    return rows.map(toDto);
  }

  /**
   * Ingrédients possédés par l'utilisateur parmi une liste d'ids (hors supprimés).
   * Exposé pour RecipesService : hydratation des ingrédients d'une recette et
   * validation d'appartenance, sans que Recipes accède au schéma Ingredients.
   */
  async listByIds(userId: string, ids: string[]): Promise<IngredientDto[]> {
    if (ids.length === 0) return [];
    const rows = await this.db
      .select()
      .from(ingredients)
      .where(
        and(
          eq(ingredients.ownerId, userId),
          inArray(ingredients.id, ids),
          isNull(ingredients.deletedAt),
        ),
      )
      .orderBy(ingredients.name);
    return rows.map(toDto);
  }

  /** Catalogue système, annoté du statut "déjà importé" pour l'utilisateur courant. */
  async listSystem(userId: string): Promise<SystemIngredientDto[]> {
    const [rows, mine] = await Promise.all([
      this.db
        .select()
        .from(ingredients)
        .where(and(isNull(ingredients.ownerId), isNull(ingredients.deletedAt)))
        .orderBy(ingredients.name),
      this.db
        .select({ importedFromId: ingredients.importedFromId })
        .from(ingredients)
        .where(and(eq(ingredients.ownerId, userId), isNull(ingredients.deletedAt))),
    ]);
    const importedSystemIds = new Set(
      mine.map((r) => r.importedFromId).filter((id): id is string => id !== null),
    );
    return rows.map((row) => ({
      ...toDto(row),
      alreadyImported: importedSystemIds.has(row.id),
    }));
  }

  /** Détail d'un ingrédient utilisateur, alternatives incluses. */
  async getDetail(userId: string, id: string): Promise<IngredientDetailDto> {
    const row = await this.findOwnedOrFail(userId, id);
    const alternatives = await this.listAlternatives(userId, id);
    return { ...toDto(row), alternatives };
  }

  async create(userId: string, dto: CreateIngredientDto): Promise<IngredientDto> {
    const [row] = await this.db
      .insert(ingredients)
      .values({
        ownerId: userId,
        name: dto.name,
        unit: dto.unit,
        imageUrl: dto.imageUrl ?? null,
      })
      .returning();
    return toDto(row);
  }

  /**
   * Importe un ingrédient système : crée une **copie indépendante** appartenant à
   * l'utilisateur, avec lien `importedFromId` vers l'origine. L'ingrédient système
   * n'est jamais modifié. Un second import du même modèle est refusé (409).
   */
  async importSystem(userId: string, systemId: string): Promise<IngredientDto> {
    const [system] = await this.db
      .select()
      .from(ingredients)
      .where(
        and(
          eq(ingredients.id, systemId),
          isNull(ingredients.ownerId),
          isNull(ingredients.deletedAt),
        ),
      );
    if (!system) {
      throw new NotFoundException('Ingrédient système introuvable');
    }

    const [existing] = await this.db
      .select({ id: ingredients.id })
      .from(ingredients)
      .where(
        and(
          eq(ingredients.ownerId, userId),
          eq(ingredients.importedFromId, systemId),
          isNull(ingredients.deletedAt),
        ),
      );
    if (existing) {
      throw new ConflictException('Cet ingrédient système est déjà importé');
    }

    const [row] = await this.db
      .insert(ingredients)
      .values({
        ownerId: userId,
        name: system.name,
        unit: system.unit,
        imageUrl: system.imageUrl,
        importedFromId: system.id,
      })
      .returning();
    return toDto(row);
  }

  async update(userId: string, id: string, dto: UpdateIngredientDto): Promise<IngredientDto> {
    await this.findOwnedOrFail(userId, id);
    const patch: Partial<Pick<IngredientRow, 'name' | 'unit' | 'imageUrl'>> = {};
    if (dto.name !== undefined) patch.name = dto.name;
    if (dto.unit !== undefined) patch.unit = dto.unit;
    if (dto.imageUrl !== undefined) patch.imageUrl = dto.imageUrl;

    const [row] = await this.db
      .update(ingredients)
      .set({ ...patch, updatedAt: new Date() })
      .where(eq(ingredients.id, id))
      .returning();
    return toDto(row);
  }

  /** Soft delete : marque supprimé sans effacer (préserve les recettes liées). */
  async softDelete(userId: string, id: string): Promise<void> {
    await this.findOwnedOrFail(userId, id);
    await this.db
      .update(ingredients)
      .set({ deletedAt: new Date(), updatedAt: new Date() })
      .where(eq(ingredients.id, id));
  }

  /** Déclare `alternativeId` comme alternative de `id` (relation symétrique, idempotente). */
  async addAlternative(userId: string, id: string, alternativeId: string): Promise<void> {
    if (id === alternativeId) {
      throw new ConflictException("Un ingrédient ne peut pas être sa propre alternative");
    }
    await this.findOwnedOrFail(userId, id);
    await this.findOwnedOrFail(userId, alternativeId);
    const { lowId, highId } = canonicalPair(id, alternativeId);
    await this.db
      .insert(ingredientAlternatives)
      .values({ lowId, highId })
      .onConflictDoNothing();
  }

  /** Retire le lien d'alternative (les deux sens, via la ligne canonique unique). */
  async removeAlternative(userId: string, id: string, alternativeId: string): Promise<void> {
    await this.findOwnedOrFail(userId, id);
    const { lowId, highId } = canonicalPair(id, alternativeId);
    await this.db
      .delete(ingredientAlternatives)
      .where(
        and(
          eq(ingredientAlternatives.lowId, lowId),
          eq(ingredientAlternatives.highId, highId),
        ),
      );
  }

  /**
   * Hard delete de tout le contenu ingrédients d'un utilisateur ("repartir de
   * zéro", cf. features/auth.md). Les lignes d'alternatives partent en cascade
   * (FK onDelete: cascade). Exposé pour AccountService uniquement.
   */
  async deleteAllForUser(userId: string): Promise<void> {
    await this.db.delete(ingredients).where(eq(ingredients.ownerId, userId));
    this.logger.log(`Ingrédients supprimés pour l'utilisateur ${userId}`);
  }

  /**
   * Résout une alternative **déclarée** d'un ingrédient (pour le remplacement
   * « introuvable en magasin » d'une liste de courses). Renvoie l'alternative si
   * le lien existe et qu'elle appartient à l'utilisateur, sinon null. Exposé à
   * ShoppingListsService (isolation des domaines).
   */
  async resolveAlternative(
    userId: string,
    ingredientId: string,
    alternativeId: string,
  ): Promise<IngredientDto | null> {
    const alternatives = await this.listAlternatives(userId, ingredientId);
    return alternatives.find((a) => a.id === alternativeId) ?? null;
  }

  // --- privé -------------------------------------------------------------

  /** Alternatives (non supprimées) d'un ingrédient de l'utilisateur. */
  private async listAlternatives(userId: string, id: string): Promise<IngredientDto[]> {
    const links = await this.db
      .select()
      .from(ingredientAlternatives)
      .where(
        or(eq(ingredientAlternatives.lowId, id), eq(ingredientAlternatives.highId, id)),
      );
    const otherIds = links.map((l) => (l.lowId === id ? l.highId : l.lowId));
    if (otherIds.length === 0) return [];

    const rows = await this.db
      .select()
      .from(ingredients)
      .where(
        and(
          inArray(ingredients.id, otherIds),
          eq(ingredients.ownerId, userId),
          isNull(ingredients.deletedAt),
        ),
      )
      .orderBy(ingredients.name);
    return rows.map(toDto);
  }

  /**
   * Récupère un ingrédient appartenant à l'utilisateur (non supprimé), ou lève.
   * Un ingrédient système (owner null) n'est jamais "possédé" : il ne peut donc
   * être ni modifié ni supprimé par un utilisateur (règle métier ingredients.md).
   */
  private async findOwnedOrFail(userId: string, id: string): Promise<IngredientRow> {
    const [row] = await this.db
      .select()
      .from(ingredients)
      .where(and(eq(ingredients.id, id), isNull(ingredients.deletedAt)));
    if (!row) {
      throw new NotFoundException('Ingrédient introuvable');
    }
    if (row.ownerId === null) {
      throw new ForbiddenException('Un ingrédient système ne peut pas être modifié');
    }
    if (row.ownerId !== userId) {
      throw new NotFoundException('Ingrédient introuvable');
    }
    return row;
  }
}
