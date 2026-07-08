import { Inject, Injectable, Logger, NotFoundException } from '@nestjs/common';
import { and, eq, inArray, isNull } from 'drizzle-orm';

import { DRIZZLE, DrizzleDB } from '../../db/drizzle.provider';
import { people, type PersonRow } from '../../db/schema/people.schema';
import { personRecipes } from '../../db/schema/person-recipes.schema';
import { personTags } from '../../db/schema/person-tags.schema';
import {
  RecipesService,
  type RecipeSummaryDto,
} from '../recipes/recipes.service';
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
  /** Recettes associées directement (« ses recettes »). */
  recipeIds: string[];
  createdAt: string;
}

function toDto(row: PersonRow, tags: TagDto[], recipeIds: string[]): PersonDto {
  return {
    id: row.id,
    firstName: row.firstName,
    lastName: row.lastName,
    avatarUrl: row.avatarUrl,
    tags,
    recipeIds,
    createdAt: row.createdAt.toISOString(),
  };
}

@Injectable()
export class PeopleService {
  private readonly logger = new Logger(PeopleService.name);

  constructor(
    @Inject(DRIZZLE) private readonly db: DrizzleDB,
    private readonly tagsService: TagsService,
    private readonly recipesService: RecipesService,
  ) {}

  /** Personnes de l'utilisateur (hors supprimées), tags associés inclus. */
  async listMine(userId: string): Promise<PersonDto[]> {
    const rows = await this.db
      .select()
      .from(people)
      .where(and(eq(people.ownerId, userId), isNull(people.deletedAt)))
      .orderBy(people.firstName);
    if (rows.length === 0) return [];

    // Une seule requête par pivot + une seule hydratation des tags (pas de N+1).
    const personIds = rows.map((r) => r.id);
    const [links, recipeLinks] = await Promise.all([
      this.db
        .select()
        .from(personTags)
        .where(inArray(personTags.personId, personIds)),
      this.db
        .select()
        .from(personRecipes)
        .where(inArray(personRecipes.personId, personIds)),
    ]);
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
        recipeLinks
          .filter((l) => l.personId === row.id)
          .map((l) => l.recipeId),
      ),
    );
  }

  /**
   * Union des tags portés par un ensemble de personnes possédées, pour la
   * recherche avancée (« pour qui on cuisine » → recettes compatibles avec au
   * moins un tag de la/des personne(s) sélectionnée(s)). Lève si un id fourni
   * n'appartient pas à l'utilisateur. Peut renvoyer un tableau vide si les
   * personnes sélectionnées ne portent aucun tag (l'appelant en déduit alors
   * qu'aucune recette ne peut correspondre à ce critère).
   */
  async tagIdsForPeople(userId: string, personIds: string[]): Promise<string[]> {
    if (personIds.length === 0) return [];
    const uniqueIds = [...new Set(personIds)];
    const owned = await this.db
      .select({ id: people.id })
      .from(people)
      .where(
        and(
          eq(people.ownerId, userId),
          isNull(people.deletedAt),
          inArray(people.id, uniqueIds),
        ),
      );
    if (owned.length !== uniqueIds.length) {
      throw new NotFoundException('Personne introuvable');
    }
    const links = await this.db
      .select({ tagId: personTags.tagId })
      .from(personTags)
      .where(inArray(personTags.personId, uniqueIds));
    return [...new Set(links.map((l) => l.tagId))];
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
    return toDto(row, [], []);
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

  /** Associe une recette à une personne (idempotent). Retourne la personne à jour. */
  async addRecipe(
    userId: string,
    personId: string,
    recipeId: string,
  ): Promise<PersonDto> {
    const person = await this.findOwnedOrFail(userId, personId);
    await this.recipesService.assertOwnedRecipe(userId, recipeId);
    await this.db
      .insert(personRecipes)
      .values({ personId, recipeId })
      .onConflictDoNothing();
    return this.hydrate(userId, person);
  }

  /** Retire l'association d'une recette. Retourne la personne à jour. */
  async removeRecipe(
    userId: string,
    personId: string,
    recipeId: string,
  ): Promise<PersonDto> {
    const person = await this.findOwnedOrFail(userId, personId);
    await this.db
      .delete(personRecipes)
      .where(
        and(
          eq(personRecipes.personId, personId),
          eq(personRecipes.recipeId, recipeId),
        ),
      );
    return this.hydrate(userId, person);
  }

  /** « Ses recettes » : résumés des recettes associées directement à la personne. */
  async listRecipes(userId: string, personId: string): Promise<RecipeSummaryDto[]> {
    await this.findOwnedOrFail(userId, personId);
    const links = await this.db
      .select({ recipeId: personRecipes.recipeId })
      .from(personRecipes)
      .where(eq(personRecipes.personId, personId));
    return this.recipesService.listByIds(
      userId,
      links.map((l) => l.recipeId),
    );
  }

  /**
   * Union des recettes associées directement à un ensemble de personnes
   * possédées (recherche avancée). Lève si un id n'appartient pas à l'utilisateur.
   */
  async recipeIdsForPeople(userId: string, personIds: string[]): Promise<string[]> {
    if (personIds.length === 0) return [];
    const uniqueIds = [...new Set(personIds)];
    const owned = await this.db
      .select({ id: people.id })
      .from(people)
      .where(
        and(
          eq(people.ownerId, userId),
          isNull(people.deletedAt),
          inArray(people.id, uniqueIds),
        ),
      );
    if (owned.length !== uniqueIds.length) {
      throw new NotFoundException('Personne introuvable');
    }
    const links = await this.db
      .select({ recipeId: personRecipes.recipeId })
      .from(personRecipes)
      .where(inArray(personRecipes.personId, uniqueIds));
    return [...new Set(links.map((l) => l.recipeId))];
  }

  /**
   * Toutes les recettes associées à AU MOINS une personne (non supprimée) de
   * l'utilisateur — sert à déterminer les recettes « associées à rien » dans la
   * recherche.
   */
  async allAssociatedRecipeIds(userId: string): Promise<string[]> {
    const links = await this.db
      .select({ recipeId: personRecipes.recipeId })
      .from(personRecipes)
      .innerJoin(people, eq(people.id, personRecipes.personId))
      .where(and(eq(people.ownerId, userId), isNull(people.deletedAt)));
    return [...new Set(links.map((l) => l.recipeId))];
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

  /** Recharge tags et recettes associés à une personne et construit son DTO. */
  private async hydrate(userId: string, row: PersonRow): Promise<PersonDto> {
    const [links, recipeLinks] = await Promise.all([
      this.db
        .select({ tagId: personTags.tagId })
        .from(personTags)
        .where(eq(personTags.personId, row.id)),
      this.db
        .select({ recipeId: personRecipes.recipeId })
        .from(personRecipes)
        .where(eq(personRecipes.personId, row.id)),
    ]);
    const tags = await this.tagsService.listByIds(
      userId,
      links.map((l) => l.tagId),
    );
    return toDto(row, tags, recipeLinks.map((l) => l.recipeId));
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
