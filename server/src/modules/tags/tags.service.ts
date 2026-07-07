import {
  ConflictException,
  Inject,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { and, eq, inArray, isNull, ne, sql } from 'drizzle-orm';

import { DRIZZLE, DrizzleDB } from '../../db/drizzle.provider';
import { tags, type TagRow } from '../../db/schema/tags.schema';
import { CreateTagDto } from './dto/create-tag.dto';
import { UpdateTagDto } from './dto/update-tag.dto';

/** Représentation d'API (camelCase) — jamais la ligne Drizzle brute. */
export interface TagDto {
  id: string;
  name: string;
  color: string;
  /**
   * Nombre de recettes portant ce tag. Câblé à la table pivot `recipe_tags`
   * (feature recettes, à venir) ; renvoie 0 tant que ce pivot n'existe pas.
   */
  recipeCount: number;
  createdAt: string;
}

function toDto(row: TagRow, recipeCount = 0): TagDto {
  return {
    id: row.id,
    name: row.name,
    color: row.color,
    recipeCount,
    createdAt: row.createdAt.toISOString(),
  };
}

@Injectable()
export class TagsService {
  private readonly logger = new Logger(TagsService.name);

  constructor(@Inject(DRIZZLE) private readonly db: DrizzleDB) {}

  /**
   * Tags possédés par l'utilisateur parmi une liste d'ids (hors supprimés).
   * Exposé pour PeopleService : hydratation des tags associés à une personne et
   * validation d'appartenance, sans que People accède au schéma Tags.
   */
  async listByIds(userId: string, ids: string[]): Promise<TagDto[]> {
    if (ids.length === 0) return [];
    const rows = await this.db
      .select()
      .from(tags)
      .where(
        and(
          eq(tags.ownerId, userId),
          inArray(tags.id, ids),
          isNull(tags.deletedAt),
        ),
      )
      .orderBy(tags.name);
    return rows.map((row) => toDto(row));
  }

  /** Tags de l'utilisateur, hors supprimés, triés par nom. */
  async listMine(userId: string): Promise<TagDto[]> {
    const rows = await this.db
      .select()
      .from(tags)
      .where(and(eq(tags.ownerId, userId), isNull(tags.deletedAt)))
      .orderBy(tags.name);
    return rows.map((row) => toDto(row));
  }

  async create(userId: string, dto: CreateTagDto): Promise<TagDto> {
    await this.assertNameAvailable(userId, dto.name);
    const [row] = await this.db
      .insert(tags)
      .values({ ownerId: userId, name: dto.name, color: dto.color })
      .returning();
    return toDto(row);
  }

  async update(userId: string, id: string, dto: UpdateTagDto): Promise<TagDto> {
    await this.findOwnedOrFail(userId, id);
    if (dto.name !== undefined) {
      await this.assertNameAvailable(userId, dto.name, id);
    }

    const patch: Partial<Pick<TagRow, 'name' | 'color'>> = {};
    if (dto.name !== undefined) patch.name = dto.name;
    if (dto.color !== undefined) patch.color = dto.color;

    const [row] = await this.db
      .update(tags)
      .set({ ...patch, updatedAt: new Date() })
      .where(eq(tags.id, id))
      .returning();
    return toDto(row);
  }

  /** Soft delete : marque supprimé sans effacer (préserve les liaisons). */
  async softDelete(userId: string, id: string): Promise<void> {
    await this.findOwnedOrFail(userId, id);
    await this.db
      .update(tags)
      .set({ deletedAt: new Date(), updatedAt: new Date() })
      .where(eq(tags.id, id));
  }

  /**
   * Hard delete de tous les tags d'un utilisateur ("repartir de zéro", cf.
   * features/auth.md). Exposé pour AccountService uniquement.
   */
  async deleteAllForUser(userId: string): Promise<void> {
    await this.db.delete(tags).where(eq(tags.ownerId, userId));
    this.logger.log(`Tags supprimés pour l'utilisateur ${userId}`);
  }

  // --- privé -------------------------------------------------------------

  /**
   * Refuse un nom déjà porté (insensible à la casse) par un autre tag non
   * supprimé de l'utilisateur. `exceptId` permet d'exclure le tag en cours
   * d'édition (renommage vers son propre nom autorisé).
   */
  private async assertNameAvailable(
    userId: string,
    name: string,
    exceptId?: string,
  ): Promise<void> {
    const conditions = [
      eq(tags.ownerId, userId),
      isNull(tags.deletedAt),
      sql`lower(${tags.name}) = lower(${name})`,
    ];
    if (exceptId) conditions.push(ne(tags.id, exceptId));

    const [existing] = await this.db
      .select({ id: tags.id })
      .from(tags)
      .where(and(...conditions));
    if (existing) {
      throw new ConflictException('Un tag portant ce nom existe déjà');
    }
  }

  /** Récupère un tag appartenant à l'utilisateur (non supprimé), ou lève. */
  private async findOwnedOrFail(userId: string, id: string): Promise<TagRow> {
    const [row] = await this.db
      .select()
      .from(tags)
      .where(and(eq(tags.id, id), isNull(tags.deletedAt)));
    if (!row || row.ownerId !== userId) {
      throw new NotFoundException('Tag introuvable');
    }
    return row;
  }
}
