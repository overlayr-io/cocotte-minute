import {
  ConflictException,
  ForbiddenException,
  Inject,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { and, eq, inArray, isNull, ne, sql } from 'drizzle-orm';

import { DRIZZLE, DrizzleDB } from '../../db/drizzle.provider';
import { SYSTEM_TAGS, tags, type TagRow } from '../../db/schema/tags.schema';
import { RecipesService } from '../recipes/recipes.service';
import { CreateTagDto } from './dto/create-tag.dto';
import { UpdateTagDto } from './dto/update-tag.dto';

/** Représentation d'API (camelCase) — jamais la ligne Drizzle brute. */
export interface TagDto {
  id: string;
  name: string;
  color: string;
  isSystem: boolean;
  importedFromId: string | null;
  /**
   * Nombre de recettes portant ce tag. Câblé à la table pivot `recipe_tags`
   * (feature recettes, à venir) ; renvoie 0 tant que ce pivot n'existe pas.
   */
  recipeCount: number;
  createdAt: string;
}

export interface SystemTagDto extends TagDto {
  /** true si l'utilisateur possède déjà une copie importée de ce tag système. */
  alreadyImported: boolean;
}

function toDto(row: TagRow, recipeCount = 0): TagDto {
  return {
    id: row.id,
    name: row.name,
    color: row.color,
    isSystem: row.ownerId === null,
    importedFromId: row.importedFromId,
    recipeCount,
    createdAt: row.createdAt.toISOString(),
  };
}

@Injectable()
export class TagsService {
  private readonly logger = new Logger(TagsService.name);

  constructor(
    @Inject(DRIZZLE) private readonly db: DrizzleDB,
    // Compteur de recettes par tag (pivot recipe_tags), via le service Recipes —
    // dépendance à sens unique (Recipes n'importe pas Tags), pas de cross-schéma.
    private readonly recipesService: RecipesService,
  ) {}

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

  /** Tags de l'utilisateur, hors supprimés, triés par nom, avec le nombre de recettes. */
  async listMine(userId: string): Promise<TagDto[]> {
    const rows = await this.db
      .select()
      .from(tags)
      .where(and(eq(tags.ownerId, userId), isNull(tags.deletedAt)))
      .orderBy(tags.name);
    const counts = await this.recipesService.countByTagIds(
      userId,
      rows.map((r) => r.id),
    );
    return rows.map((row) => toDto(row, counts.get(row.id) ?? 0));
  }

  /** Catalogue système, annoté du statut "déjà importé" pour l'utilisateur courant. */
  async listSystem(userId: string): Promise<SystemTagDto[]> {
    await this.ensureSystemDefaults();
    const [rows, mine] = await Promise.all([
      this.db
        .select()
        .from(tags)
        .where(and(isNull(tags.ownerId), isNull(tags.deletedAt)))
        .orderBy(tags.name),
      this.db
        .select({ importedFromId: tags.importedFromId })
        .from(tags)
        .where(and(eq(tags.ownerId, userId), isNull(tags.deletedAt))),
    ]);
    const importedSystemIds = new Set(
      mine.map((r) => r.importedFromId).filter((id): id is string => id !== null),
    );
    return rows.map((row) => ({
      ...toDto(row),
      alreadyImported: importedSystemIds.has(row.id),
    }));
  }

  async create(userId: string, dto: CreateTagDto): Promise<TagDto> {
    await this.assertNameAvailable(userId, dto.name);
    const [row] = await this.db
      .insert(tags)
      .values({ ownerId: userId, name: dto.name, color: dto.color })
      .returning();
    return toDto(row);
  }

  /**
   * Importe un tag système : crée une **copie indépendante** appartenant à
   * l'utilisateur, avec lien `importedFromId` vers l'origine. Le tag système
   * n'est jamais modifié. Un second import du même modèle est refusé (409).
   */
  async importSystem(userId: string, systemId: string): Promise<TagDto> {
    const [system] = await this.db
      .select()
      .from(tags)
      .where(and(eq(tags.id, systemId), isNull(tags.ownerId), isNull(tags.deletedAt)));
    if (!system) {
      throw new NotFoundException('Tag système introuvable');
    }

    const [existing] = await this.db
      .select({ id: tags.id })
      .from(tags)
      .where(
        and(
          eq(tags.ownerId, userId),
          eq(tags.importedFromId, systemId),
          isNull(tags.deletedAt),
        ),
      );
    if (existing) {
      throw new ConflictException('Ce tag système est déjà importé');
    }

    const [row] = await this.db
      .insert(tags)
      .values({
        ownerId: userId,
        name: system.name,
        color: system.color,
        importedFromId: system.id,
      })
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
   * Sème le catalogue de tags système (`owner_id = null`) au premier accès si
   * aucun n'existe encore (seeding paresseux, global — pas par utilisateur).
   * Idempotent : ne fait rien dès qu'au moins un tag système est présent, donc
   * un catalogue vide (DB neuve/recréée) se remplit tout seul sans lancer le
   * script `db:seed:tags`.
   */
  private async ensureSystemDefaults(): Promise<void> {
    const [existing] = await this.db
      .select({ id: tags.id })
      .from(tags)
      .where(isNull(tags.ownerId))
      .limit(1);
    if (existing) return;

    await this.db
      .insert(tags)
      .values(SYSTEM_TAGS.map((t) => ({ ownerId: null, name: t.name, color: t.color })));
    this.logger.log(`Catalogue de tags système semé (${SYSTEM_TAGS.length} tags).`);
  }

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

  /**
   * Récupère un tag appartenant à l'utilisateur (non supprimé), ou lève. Un
   * tag système (owner null) n'est jamais "possédé" : il ne peut donc être
   * ni modifié ni supprimé par un utilisateur (même règle que les ingrédients).
   */
  private async findOwnedOrFail(userId: string, id: string): Promise<TagRow> {
    const [row] = await this.db
      .select()
      .from(tags)
      .where(and(eq(tags.id, id), isNull(tags.deletedAt)));
    if (!row) {
      throw new NotFoundException('Tag introuvable');
    }
    if (row.ownerId === null) {
      throw new ForbiddenException('Un tag système ne peut pas être modifié');
    }
    if (row.ownerId !== userId) {
      throw new NotFoundException('Tag introuvable');
    }
    return row;
  }
}
