import { Inject, Injectable, Logger, NotFoundException } from '@nestjs/common';
import { and, eq, inArray, isNull } from 'drizzle-orm';

import { DRIZZLE, DrizzleDB } from '../../db/drizzle.provider';
import { people, type PersonRow } from '../../db/schema/people.schema';
import { personTags } from '../../db/schema/person-tags.schema';
import { TagDto, TagsService } from '../tags/tags.service';
import { CreatePersonDto } from './dto/create-person.dto';
import { UpdatePersonDto } from './dto/update-person.dto';

/** Représentation d'API (camelCase) — jamais la ligne Drizzle brute. */
export interface PersonDto {
  id: string;
  firstName: string;
  lastName: string | null;
  avatarUrl: string | null;
  tags: TagDto[];
  createdAt: string;
}

function toDto(row: PersonRow, tags: TagDto[]): PersonDto {
  return {
    id: row.id,
    firstName: row.firstName,
    lastName: row.lastName,
    avatarUrl: row.avatarUrl,
    tags,
    createdAt: row.createdAt.toISOString(),
  };
}

@Injectable()
export class PeopleService {
  private readonly logger = new Logger(PeopleService.name);

  constructor(
    @Inject(DRIZZLE) private readonly db: DrizzleDB,
    private readonly tagsService: TagsService,
  ) {}

  /** Personnes de l'utilisateur (hors supprimées), tags associés inclus. */
  async listMine(userId: string): Promise<PersonDto[]> {
    const rows = await this.db
      .select()
      .from(people)
      .where(and(eq(people.ownerId, userId), isNull(people.deletedAt)))
      .orderBy(people.firstName);
    if (rows.length === 0) return [];

    // Une seule requête pivot + une seule hydratation des tags (pas de N+1).
    const personIds = rows.map((r) => r.id);
    const links = await this.db
      .select()
      .from(personTags)
      .where(inArray(personTags.personId, personIds));
    const tagIds = [...new Set(links.map((l) => l.tagId))];
    const tagsById = new Map(
      (await this.tagsService.listByIds(userId, tagIds)).map((t) => [t.id, t]),
    );

    return rows.map((row) =>
      toDto(
        row,
        links
          .filter((l) => l.personId === row.id)
          .map((l) => tagsById.get(l.tagId))
          .filter((t): t is TagDto => t !== undefined),
      ),
    );
  }

  async create(userId: string, dto: CreatePersonDto): Promise<PersonDto> {
    const [row] = await this.db
      .insert(people)
      .values({
        ownerId: userId,
        firstName: dto.firstName,
        lastName: dto.lastName ?? null,
        avatarUrl: dto.avatarUrl ?? null,
      })
      .returning();
    // À la création, aucune association de tag (règle métier tags-personnes.md).
    return toDto(row, []);
  }

  async update(userId: string, id: string, dto: UpdatePersonDto): Promise<PersonDto> {
    await this.findOwnedOrFail(userId, id);
    const patch: Partial<Pick<PersonRow, 'firstName' | 'lastName' | 'avatarUrl'>> = {};
    if (dto.firstName !== undefined) patch.firstName = dto.firstName;
    if (dto.lastName !== undefined) patch.lastName = dto.lastName;
    if (dto.avatarUrl !== undefined) patch.avatarUrl = dto.avatarUrl;

    const [row] = await this.db
      .update(people)
      .set({ ...patch, updatedAt: new Date() })
      .where(eq(people.id, id))
      .returning();
    return this.hydrate(userId, row);
  }

  /** Soft delete : marque supprimé sans effacer. */
  async softDelete(userId: string, id: string): Promise<void> {
    await this.findOwnedOrFail(userId, id);
    await this.db
      .update(people)
      .set({ deletedAt: new Date(), updatedAt: new Date() })
      .where(eq(people.id, id));
  }

  /** Associe un tag à une personne (idempotent). Retourne la personne à jour. */
  async addTag(userId: string, personId: string, tagId: string): Promise<PersonDto> {
    const person = await this.findOwnedOrFail(userId, personId);
    await this.assertTagOwned(userId, tagId);
    await this.db
      .insert(personTags)
      .values({ personId, tagId })
      .onConflictDoNothing();
    return this.hydrate(userId, person);
  }

  /** Retire l'association d'un tag. Retourne la personne à jour. */
  async removeTag(userId: string, personId: string, tagId: string): Promise<PersonDto> {
    const person = await this.findOwnedOrFail(userId, personId);
    await this.db
      .delete(personTags)
      .where(and(eq(personTags.personId, personId), eq(personTags.tagId, tagId)));
    return this.hydrate(userId, person);
  }

  /**
   * Hard delete de toutes les personnes d'un utilisateur ("repartir de zéro").
   * Les liaisons person_tags partent en cascade (FK onDelete: cascade). Exposé
   * pour AccountService uniquement.
   */
  async deleteAllForUser(userId: string): Promise<void> {
    await this.db.delete(people).where(eq(people.ownerId, userId));
    this.logger.log(`Personnes supprimées pour l'utilisateur ${userId}`);
  }

  // --- privé -------------------------------------------------------------

  /** Recharge les tags associés à une personne et construit son DTO. */
  private async hydrate(userId: string, row: PersonRow): Promise<PersonDto> {
    const links = await this.db
      .select({ tagId: personTags.tagId })
      .from(personTags)
      .where(eq(personTags.personId, row.id));
    const tags = await this.tagsService.listByIds(
      userId,
      links.map((l) => l.tagId),
    );
    return toDto(row, tags);
  }

  /** Vérifie que le tag appartient à l'utilisateur, ou lève (via TagsService). */
  private async assertTagOwned(userId: string, tagId: string): Promise<void> {
    const owned = await this.tagsService.listByIds(userId, [tagId]);
    if (owned.length === 0) {
      throw new NotFoundException('Tag introuvable');
    }
  }

  /** Récupère une personne appartenant à l'utilisateur (non supprimée), ou lève. */
  private async findOwnedOrFail(userId: string, id: string): Promise<PersonRow> {
    const [row] = await this.db
      .select()
      .from(people)
      .where(and(eq(people.id, id), isNull(people.deletedAt)));
    if (!row || row.ownerId !== userId) {
      throw new NotFoundException('Personne introuvable');
    }
    return row;
  }
}
