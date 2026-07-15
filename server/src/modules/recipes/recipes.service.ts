import {
  BadRequestException,
  ConflictException,
  Inject,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import {
  and,
  asc,
  desc,
  eq,
  ilike,
  inArray,
  isNotNull,
  isNull,
  notInArray,
  or,
  sql,
} from 'drizzle-orm';

import { ADVISORY_LOCK_NS } from '../../common/db/advisory-locks';
import { PremiumLimitException } from '../../common/errors/premium-limit.exception';
import { SupabaseStorageService } from '../../common/supabase/supabase-storage.service';
import { DRIZZLE, DrizzleDB } from '../../db/drizzle.provider';
import { recipeGalleryImages } from '../../db/schema/recipe-gallery.schema';
import {
  recipeCategories,
  recipeComponents,
  recipeFavorites,
  recipeIngredients,
  recipeSteps,
  recipeTags,
  recipes,
  stepIngredients,
  type RecipePriceBracket,
  type RecipePriceMode,
  type RecipeRow,
  type RecipeStepRow,
} from '../../db/schema/recipes.schema';
import { PremiumService } from '../billing/premium.service';
import { IngredientsService } from '../ingredients/ingredients.service';
import { isSeasonal } from './data/seasonality';
import { CreateRecipeDto } from './dto/create-recipe.dto';
import { type RecipeSort } from './dto/list-recipes-query.dto';
import {
  CreateRecipeStepDto,
  UpdateRecipeStepDto,
} from './dto/recipe-relations.dto';
import { UpdateRecipeDto } from './dto/update-recipe.dto';

/**
 * Filtres de recherche déjà résolus (dossiers dépliés en descendants, personnes
 * traduites en tags) par la couche d'orchestration (SearchService). RecipesService
 * ne connaît que ses propres pivots : il n'interroge jamais catégories/personnes.
 * Toutes les dimensions renseignées se combinent en ET.
 */
export interface RecipeSearchFilters {
  /** Recherche texte sur le nom (insensible à la casse). */
  q?: string;
  /** Dossiers (déjà dépliés) : la recette est rangée dans au moins un (OU). */
  categoryIds?: string[];
  /** Tags explicites : la recette porte TOUS ces tags (ET intra-dimension). */
  allTagIds?: string[];
  /** Tags dérivés des personnes : la recette porte AU MOINS UN de ces tags (OU). */
  anyTagIds?: string[];
  /**
   * Filtre « personnes » résolu par SearchService. Une recette correspond si :
   * associée directement à une des personnes (recipeIds), OU porte un de leurs
   * tags (tagIds), OU n'est associée à rien (aucun tag ET aucune personne —
   * associatedRecipeIds = toutes les recettes liées à au moins une personne).
   */
  person?: {
    recipeIds: string[];
    tagIds: string[];
    associatedRecipeIds: string[];
  };
}

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
 * Résumé enrichi pour la vue Découverte (Accueil) : ajoute le flag « de saison »
 * (dérivé des ingrédients + mois courant) et les pivots tags/dossiers, pour
 * permettre au client de composer toutes les rangées sans requête par section.
 */
export interface RecipeDiscoveryDto extends RecipeSummaryDto {
  seasonal: boolean;
  tagIds: string[];
  categoryIds: string[];
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
  /**
   * true = ligne héritée uniquement d'une sous-recette de base (pas un
   * ingrédient direct de la recette). Lecture seule côté fiche : ni édition de
   * quantité, ni réordonnancement.
   */
  inherited: boolean;
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
  /** Mode de prix (feature prix-estime) : calculé depuis les ingrédients, ou étiquette fixe. */
  priceMode: RecipePriceMode;
  /** Prix étiquette pour `servings` personnes — non-null seulement si `priceMode === 'fixed'`. */
  fixedPrice: number | null;
  /** Tranche de prix affichée en badge, calculée côté client. Null si prix inconnu/partiel. */
  priceBracket: RecipePriceBracket | null;
  /** Nutrition saisie à la main (feature #8), PAR PORTION. Null = non renseigné. */
  caloriesPerServing: number | null;
  proteinsPerServing: number | null;
  carbsPerServing: number | null;
  fatsPerServing: number | null;
  ingredients: RecipeIngredientLineDto[];
  /** Étapes (arbre déjà déplié + numéroté ; réfs de base résolues récursivement). */
  steps: RecipeStepDto[];
  /** Sous-recettes (recettes de base) utilisées par cette recette. */
  components: RecipeSummaryDto[];
  /** Recettes qui utilisent cette recette comme composant (seulement si `is_base`). */
  usedIn: RecipeSummaryDto[];
  categoryIds: string[];
  tagIds: string[];
  /** true si la recette est dans les favoris « J'aime » du lecteur (false en lecture publique). */
  isFavorite: boolean;
  /** Photos de galerie (réalisations), les plus anciennes d'abord. Hors couverture. */
  galleryPhotos: RecipeGalleryPhotoDto[];
}

/** Une photo de galerie (feature galerie-recette) — réalisation postée par l'utilisateur. */
export interface RecipeGalleryPhotoDto {
  id: string;
  imageUrl: string;
  createdAt: string;
}

/** Échappe les métacaractères LIKE (`%`, `_`, `\`) d'une saisie utilisateur. */
function escapeLike(value: string): string {
  return value.replace(/[\\%_]/g, (c) => `\\${c}`);
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
    private readonly premiumService: PremiumService,
    // Nettoyage effectif des fichiers Storage (feature galerie-recette) :
    // couverture remplacée, recette supprimée, compte purgé.
    private readonly storage: SupabaseStorageService,
  ) {}

  /** Limite du plan gratuit : nombre max de recettes de base (cf. premium-version.md). */
  private static readonly FREE_BASE_RECIPES_LIMIT = 5;

  /**
   * Garde freemium : bloque la création/bascule d'une recette de base au-delà
   * de la limite gratuite. Vérifiée serveur (jamais uniquement UI), ignorée
   * pour les comptes premium.
   */
  private async assertBaseRecipeQuota(userId: string): Promise<void> {
    const [row] = await this.db
      .select({ n: sql<number>`count(*)::int` })
      .from(recipes)
      .where(
        and(
          eq(recipes.authorId, userId),
          eq(recipes.isBase, true),
          isNull(recipes.deletedAt),
        ),
      );
    const current = row?.n ?? 0;
    if (current < RecipesService.FREE_BASE_RECIPES_LIMIT) return;
    if (await this.premiumService.isPremium(userId)) return;
    throw new PremiumLimitException(
      'PREMIUM_LIMIT_BASE_RECIPES',
      RecipesService.FREE_BASE_RECIPES_LIMIT,
      current,
      `Limite gratuite atteinte : ${RecipesService.FREE_BASE_RECIPES_LIMIT} recettes de base maximum. Passe en Pro pour en créer sans limite.`,
    );
  }

  // --- favoris « J'aime » (#15) -----------------------------------------

  /** Recettes aimées de l'utilisateur, plus récemment ajoutées d'abord. */
  async listFavorites(userId: string): Promise<RecipeSummaryDto[]> {
    const rows = await this.db
      .select({ recipe: recipes })
      .from(recipeFavorites)
      .innerJoin(recipes, eq(recipes.id, recipeFavorites.recipeId))
      .where(and(eq(recipeFavorites.userId, userId), isNull(recipes.deletedAt)))
      .orderBy(desc(recipeFavorites.createdAt));
    return rows.map((r) => toSummary(r.recipe));
  }

  /**
   * Ajoute une recette aux favoris (idempotent). Vérifie la propriété. Les
   * favoris sont illimités pour tout le monde (gratuit inclus).
   */
  async addFavorite(userId: string, recipeId: string): Promise<void> {
    await this.findOwnedOrFail(userId, recipeId);
    const [existing] = await this.db
      .select({ recipeId: recipeFavorites.recipeId })
      .from(recipeFavorites)
      .where(
        and(
          eq(recipeFavorites.userId, userId),
          eq(recipeFavorites.recipeId, recipeId),
        ),
      );
    if (existing) return; // déjà favori : rien à faire
    await this.db.insert(recipeFavorites).values({ userId, recipeId });
  }

  /** Retire une recette des favoris (idempotent). */
  async removeFavorite(userId: string, recipeId: string): Promise<void> {
    await this.db
      .delete(recipeFavorites)
      .where(
        and(
          eq(recipeFavorites.userId, userId),
          eq(recipeFavorites.recipeId, recipeId),
        ),
      );
  }

  /**
   * Mes recettes (les plus récentes d'abord), hors supprimées. Options pour la
   * vue Liste paginée : `q` (filtre texte simple sur le nom), `limit`/`offset`.
   * Sans option, tout est renvoyé (rétro-compatible).
   */
  async listMine(
    userId: string,
    options?: { q?: string; limit?: number; offset?: number; sort?: RecipeSort },
  ): Promise<RecipeSummaryDto[]> {
    const conditions = [eq(recipes.authorId, userId), isNull(recipes.deletedAt)];
    const q = options?.q?.trim();
    if (q) {
      conditions.push(ilike(recipes.name, `%${escapeLike(q)}%`));
    }
    let query = this.db
      .select()
      .from(recipes)
      .where(and(...conditions))
      .orderBy(...this.recipeOrderBy(options?.sort))
      .$dynamic();
    if (options?.limit !== undefined) query = query.limit(options.limit);
    if (options?.offset !== undefined) query = query.offset(options.offset);
    const rows = await query;
    return rows.map(toSummary);
  }

  /**
   * Clause de tri de la vue Liste. `createdAt` desc en critère secondaire pour un
   * ordre déterministe (stabilité de la pagination limit/offset). Pas de tri par
   * prix : calcul de prix côté client uniquement (contrainte transverse).
   */
  private recipeOrderBy(sort?: RecipeSort) {
    switch (sort) {
      case 'name':
        return [asc(recipes.name), desc(recipes.createdAt)];
      case 'time':
        return [
          asc(
            sql`${recipes.prepTime} + ${recipes.cookTime} + ${recipes.restTime}`,
          ),
          desc(recipes.createdAt),
        ];
      case 'recent':
      default:
        return [desc(recipes.createdAt)];
    }
  }

  /**
   * Recettes rangées dans aucun dossier (non supprimées, plus récentes d'abord)
   * — alimente le dossier virtuel « Autres » de la page Recettes.
   */
  async listUncategorized(userId: string): Promise<RecipeSummaryDto[]> {
    const rows = await this.db
      .select()
      .from(recipes)
      .where(
        and(
          eq(recipes.authorId, userId),
          isNull(recipes.deletedAt),
          notInArray(
            recipes.id,
            this.db
              .select({ id: recipeCategories.recipeId })
              .from(recipeCategories),
          ),
        ),
      )
      .orderBy(desc(recipes.createdAt));
    return rows.map(toSummary);
  }

  /**
   * Résumés d'un ensemble de recettes possédées (non supprimées), les plus
   * récentes d'abord. Les ids inconnus ou étrangers sont ignorés silencieusement.
   */
  async listByIds(userId: string, ids: string[]): Promise<RecipeSummaryDto[]> {
    if (ids.length === 0) return [];
    const rows = await this.db
      .select()
      .from(recipes)
      .where(
        and(
          inArray(recipes.id, [...new Set(ids)]),
          eq(recipes.authorId, userId),
          isNull(recipes.deletedAt),
        ),
      )
      .orderBy(desc(recipes.createdAt));
    return rows.map(toSummary);
  }

  /**
   * Recettes rangées dans un dossier donné (pivot `recipe_categories`), les
   * plus récentes d'abord, hors supprimées. Ne renvoie que les recettes de
   * l'utilisateur — l'appartenance du dossier est vérifiée en amont par
   * CategoriesService. Directes uniquement (pas de récursion sous-dossiers,
   * cohérent avec `countByCategoryIds`).
   */
  async listByCategory(
    userId: string,
    categoryId: string,
  ): Promise<RecipeSummaryDto[]> {
    const rows = await this.db
      .select({ recipe: recipes })
      .from(recipeCategories)
      .innerJoin(recipes, eq(recipes.id, recipeCategories.recipeId))
      .where(
        and(
          eq(recipeCategories.categoryId, categoryId),
          eq(recipes.authorId, userId),
          isNull(recipes.deletedAt),
        ),
      )
      .orderBy(desc(recipes.createdAt));
    return rows.map((r) => toSummary(r.recipe));
  }

  /**
   * Recherche avancée sur mes recettes (non supprimées), plus récentes d'abord.
   * Chaque dimension renseignée est un sous-critère combiné en ET via des
   * sous-requêtes sur les pivots `recipe_categories` / `recipe_tags` (le domaine
   * de Recipes). Sans aucun filtre, se comporte comme `listMine`. Les filtres
   * transverses (descendants de dossier, tags d'une personne) sont résolus en
   * amont par SearchService — ici on ne touche qu'aux tables de Recipes.
   */
  async search(
    userId: string,
    filters: RecipeSearchFilters,
  ): Promise<RecipeSummaryDto[]> {
    const conditions = [eq(recipes.authorId, userId), isNull(recipes.deletedAt)];

    const q = filters.q?.trim();
    if (q) {
      conditions.push(ilike(recipes.name, `%${escapeLike(q)}%`));
    }

    if (filters.categoryIds && filters.categoryIds.length > 0) {
      conditions.push(
        inArray(
          recipes.id,
          this.db
            .select({ id: recipeCategories.recipeId })
            .from(recipeCategories)
            .where(inArray(recipeCategories.categoryId, filters.categoryIds)),
        ),
      );
    }

    if (filters.anyTagIds && filters.anyTagIds.length > 0) {
      conditions.push(
        inArray(
          recipes.id,
          this.db
            .select({ id: recipeTags.recipeId })
            .from(recipeTags)
            .where(inArray(recipeTags.tagId, filters.anyTagIds)),
        ),
      );
    }

    if (filters.person) {
      const { recipeIds, tagIds, associatedRecipeIds } = filters.person;
      const alternatives = [];
      if (recipeIds.length > 0) {
        alternatives.push(inArray(recipes.id, recipeIds));
      }
      if (tagIds.length > 0) {
        alternatives.push(
          inArray(
            recipes.id,
            this.db
              .select({ id: recipeTags.recipeId })
              .from(recipeTags)
              .where(inArray(recipeTags.tagId, tagIds)),
          ),
        );
      }
      // « Associée à rien » : aucun tag et liée à aucune personne.
      const orphanParts = [
        notInArray(
          recipes.id,
          this.db.select({ id: recipeTags.recipeId }).from(recipeTags),
        ),
      ];
      if (associatedRecipeIds.length > 0) {
        orphanParts.push(notInArray(recipes.id, associatedRecipeIds));
      }
      alternatives.push(and(...orphanParts)!);
      conditions.push(or(...alternatives)!);
    }

    if (filters.allTagIds && filters.allTagIds.length > 0) {
      // ET intra-dimension : la recette doit porter chacun des tags → on ne garde
      // que les recette_id ayant autant de tags distincts (parmi la sélection)
      // que de tags demandés.
      const uniqueTagIds = [...new Set(filters.allTagIds)];
      conditions.push(
        inArray(
          recipes.id,
          this.db
            .select({ id: recipeTags.recipeId })
            .from(recipeTags)
            .where(inArray(recipeTags.tagId, uniqueTagIds))
            .groupBy(recipeTags.recipeId)
            .having(
              sql`count(distinct ${recipeTags.tagId}) = ${uniqueTagIds.length}`,
            ),
        ),
      );
    }

    const rows = await this.db
      .select()
      .from(recipes)
      .where(and(...conditions))
      .orderBy(desc(recipes.createdAt));
    return rows.map(toSummary);
  }

  /**
   * Toutes mes recettes (non supprimées, plus récentes d'abord) enrichies pour
   * la vue Découverte : flag « de saison » (via ingrédients + `month`), tags et
   * dossiers. Une seule passe : recettes + pivots batchés, noms d'ingrédients
   * hydratés via IngredientsService (isolation des domaines). Exposé à
   * DiscoveryService.
   */
  async listMineForDiscovery(
    userId: string,
    month: number,
  ): Promise<RecipeDiscoveryDto[]> {
    const rows = await this.db
      .select()
      .from(recipes)
      .where(and(eq(recipes.authorId, userId), isNull(recipes.deletedAt)))
      .orderBy(desc(recipes.createdAt));
    if (rows.length === 0) return [];

    const ids = rows.map((r) => r.id);
    const [ingRows, tagRows, catRows] = await Promise.all([
      this.db
        .select({
          recipeId: recipeIngredients.recipeId,
          ingredientId: recipeIngredients.ingredientId,
        })
        .from(recipeIngredients)
        .where(inArray(recipeIngredients.recipeId, ids)),
      this.db
        .select({ recipeId: recipeTags.recipeId, tagId: recipeTags.tagId })
        .from(recipeTags)
        .where(inArray(recipeTags.recipeId, ids)),
      this.db
        .select({
          recipeId: recipeCategories.recipeId,
          categoryId: recipeCategories.categoryId,
        })
        .from(recipeCategories)
        .where(inArray(recipeCategories.recipeId, ids)),
    ]);

    const allIngredientIds = [...new Set(ingRows.map((r) => r.ingredientId))];
    const owned = await this.ingredientsService.listByIds(
      userId,
      allIngredientIds,
    );
    const nameById = new Map(owned.map((i) => [i.id, i.name]));

    const namesByRecipe = new Map<string, string[]>();
    for (const r of ingRows) {
      const name = nameById.get(r.ingredientId);
      if (!name) continue;
      const arr = namesByRecipe.get(r.recipeId);
      if (arr) arr.push(name);
      else namesByRecipe.set(r.recipeId, [name]);
    }
    const tagsByRecipe = new Map<string, string[]>();
    for (const r of tagRows) {
      const arr = tagsByRecipe.get(r.recipeId);
      if (arr) arr.push(r.tagId);
      else tagsByRecipe.set(r.recipeId, [r.tagId]);
    }
    const catsByRecipe = new Map<string, string[]>();
    for (const r of catRows) {
      const arr = catsByRecipe.get(r.recipeId);
      if (arr) arr.push(r.categoryId);
      else catsByRecipe.set(r.recipeId, [r.categoryId]);
    }

    return rows.map((row) => ({
      ...toSummary(row),
      seasonal: isSeasonal(namesByRecipe.get(row.id) ?? [], month),
      tagIds: tagsByRecipe.get(row.id) ?? [],
      categoryIds: catsByRecipe.get(row.id) ?? [],
    }));
  }

  async create(userId: string, dto: CreateRecipeDto): Promise<RecipeSummaryDto> {
    if (dto.isBase === true) await this.assertBaseRecipeQuota(userId);
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

  /**
   * Sème des recettes d'exemple pour un nouveau compte (feature #12), afin de
   * montrer le but de l'app : une recette de base « Sauce tomate maison » + un
   * plat « Pâtes à la sauce tomate » qui l'utilise comme sous-recette. Idempotent :
   * ne fait rien si le compte a déjà eu la moindre recette (y compris supprimée).
   */
  async seedSamples(userId: string): Promise<void> {
    // Verrou consultatif tenu pendant TOUT le semis : le garde « ce compte
    // a-t-il déjà des recettes ? » est suivi de ~10 allers-retours avant que la
    // 1re recette n'existe. Deux appels concurrents (2 lancements qui se
    // chevauchent pendant un cold start Render) semaient chacun leur jeu.
    // `pg_advisory_xact_lock` reste tenu jusqu'au commit de la transaction :
    // comme on `await` tout le semis à l'intérieur, le 2e appelant attend, puis
    // voit les recettes commitées et sort. Les écritures passent par `this.db`
    // (autre connexion) pour réutiliser les méthodes métier telles quelles.
    await this.db.transaction(async (tx) => {
      await tx.execute(
        sql`select pg_advisory_xact_lock(${ADVISORY_LOCK_NS.sampleRecipes}, hashtext(${userId}))`,
      );
      const [existing] = await tx
        .select({ n: sql<number>`count(*)::int` })
        .from(recipes)
        .where(eq(recipes.authorId, userId));
      if ((existing?.n ?? 0) > 0) return;
      await this.insertSamples(userId);
    });
  }

  /** Contenu du semis d'onboarding. Toujours appelé sous verrou (cf. [seedSamples]). */
  private async insertSamples(userId: string): Promise<void> {
    const ing = async (
      name: string,
      unit: 'gramme' | 'piece' | 'cuillere_soupe',
      emoji: string,
    ): Promise<string> =>
      (await this.ingredientsService.create(userId, { name, unit, emoji })).id;

    const tomate = await ing('Tomate', 'piece', '🍅');
    const oignon = await ing('Oignon', 'piece', '🧅');
    const ail = await ing('Ail', 'piece', '🧄');
    const huile = await ing("Huile d'olive", 'cuillere_soupe', '🫒');
    const pates = await ing('Pâtes', 'gramme', '🍝');
    const parmesan = await ing('Parmesan', 'gramme', '🧀');

    // Recette de base réutilisable.
    const base = await this.create(userId, {
      name: 'Sauce tomate maison',
      isBase: true,
      servings: 4,
      prepTime: 10,
      cookTime: 25,
      description:
        'Une sauce tomate simple et réutilisable : ajoute-la comme sous-recette dans tes plats.',
    });
    await this.addIngredient(userId, base.id, tomate, 6);
    await this.addIngredient(userId, base.id, oignon, 1);
    await this.addIngredient(userId, base.id, ail, 2);
    await this.addIngredient(userId, base.id, huile, 2);
    await this.addStep(userId, base.id, {
      description:
        "Fais revenir l'oignon et l'ail émincés dans l'huile d'olive jusqu'à ce qu'ils soient translucides.",
    });
    await this.addStep(userId, base.id, {
      description:
        'Ajoute les tomates concassées, sale, puis laisse mijoter 20 minutes à feu doux.',
    });

    // Plat qui utilise la recette de base comme sous-recette.
    const dish = await this.create(userId, {
      name: 'Pâtes à la sauce tomate',
      isBase: false,
      servings: 4,
      prepTime: 5,
      cookTime: 12,
      description:
        'Un classique express qui réutilise ta sauce tomate maison (ajoutée en sous-recette).',
    });
    await this.addIngredient(userId, dish.id, pates, 500);
    await this.addIngredient(userId, dish.id, parmesan, 50);
    await this.addComponent(userId, dish.id, base.id);
    await this.addStep(userId, dish.id, {
      description: "Fais cuire les pâtes dans un grand volume d'eau bouillante salée.",
    });
    await this.addStep(userId, dish.id, {
      description:
        'Égoutte, mélange avec la sauce tomate maison, puis parsème de parmesan.',
    });

    this.logger.log(`Recettes d'exemple semées pour l'utilisateur ${userId}`);
  }

  /**
   * Duplique une recette possédée (copie profonde) : nom + « (copie) »,
   * ingrédients (+ positions), étapes (+ positions, bannières, réfs de base et
   * sélections d'ingrédients d'étape), composants/sous-recettes, catégories,
   * tags. Ne sont PAS copiés : la photo de couverture et la galerie — ce sont
   * des objets Storage ; partager leur URL casserait la copie si l'original est
   * supprimé. Respecte le quota freemium si la source est une recette de base.
   */
  async duplicateRecipe(userId: string, recipeId: string): Promise<RecipeSummaryDto> {
    const source = await this.findOwnedOrFail(userId, recipeId);
    if (source.isBase) await this.assertBaseRecipeQuota(userId);

    // 1) Recette (couverture non copiée)
    const [copy] = await this.db
      .insert(recipes)
      .values({
        authorId: userId,
        name: `${source.name} (copie)`.slice(0, 160),
        photoUrl: null,
        description: source.description,
        isBase: source.isBase,
        prepTime: source.prepTime,
        cookTime: source.cookTime,
        restTime: source.restTime,
        servings: source.servings,
        priceMode: source.priceMode,
        fixedPrice: source.fixedPrice,
        priceBracket: source.priceBracket,
      })
      .returning();
    const newId = copy.id;

    // 2) Ingrédients (avec position)
    const ings = await this.db
      .select({
        ingredientId: recipeIngredients.ingredientId,
        quantity: recipeIngredients.quantity,
        position: recipeIngredients.position,
      })
      .from(recipeIngredients)
      .where(eq(recipeIngredients.recipeId, recipeId));
    if (ings.length > 0) {
      await this.db
        .insert(recipeIngredients)
        .values(ings.map((r) => ({ recipeId: newId, ...r })));
    }

    // 3) Étapes (mapping ancien id → nouvel id pour les sélections d'ingrédients)
    const steps = await this.db
      .select()
      .from(recipeSteps)
      .where(eq(recipeSteps.recipeId, recipeId))
      .orderBy(asc(recipeSteps.position));
    const stepIdMap = new Map<string, string>();
    for (const s of steps) {
      const [ns] = await this.db
        .insert(recipeSteps)
        .values({
          recipeId: newId,
          position: s.position,
          description: s.description,
          bannerType: s.bannerType,
          bannerText: s.bannerText,
          baseRecipeRefId: s.baseRecipeRefId,
        })
        .returning({ id: recipeSteps.id });
      stepIdMap.set(s.id, ns.id);
    }
    if (steps.length > 0) {
      const stepIngRows = await this.db
        .select({
          stepId: stepIngredients.stepId,
          ingredientId: stepIngredients.ingredientId,
        })
        .from(stepIngredients)
        .where(
          inArray(
            stepIngredients.stepId,
            steps.map((s) => s.id),
          ),
        );
      if (stepIngRows.length > 0) {
        await this.db.insert(stepIngredients).values(
          stepIngRows.map((r) => ({
            stepId: stepIdMap.get(r.stepId)!,
            ingredientId: r.ingredientId,
          })),
        );
      }
    }

    // 4) Composants (sous-recettes)
    const comps = await this.db
      .select({ baseRecipeId: recipeComponents.baseRecipeId })
      .from(recipeComponents)
      .where(eq(recipeComponents.parentRecipeId, recipeId));
    if (comps.length > 0) {
      await this.db
        .insert(recipeComponents)
        .values(comps.map((c) => ({ parentRecipeId: newId, baseRecipeId: c.baseRecipeId })));
    }

    // 5) Catégories
    const cats = await this.db
      .select({ categoryId: recipeCategories.categoryId })
      .from(recipeCategories)
      .where(eq(recipeCategories.recipeId, recipeId));
    if (cats.length > 0) {
      await this.db
        .insert(recipeCategories)
        .values(cats.map((c) => ({ recipeId: newId, categoryId: c.categoryId })));
    }

    // 6) Tags
    const tgs = await this.db
      .select({ tagId: recipeTags.tagId })
      .from(recipeTags)
      .where(eq(recipeTags.recipeId, recipeId));
    if (tgs.length > 0) {
      await this.db
        .insert(recipeTags)
        .values(tgs.map((t) => ({ recipeId: newId, tagId: t.tagId })));
    }

    return toSummary(copy);
  }

  /** Fiche détail : ingrédients, composants, « utilisée dans », catégories, tags. */
  async getDetail(userId: string, id: string): Promise<RecipeDetailDto> {
    const row = await this.findOwnedOrFail(userId, id);
    return this.buildDetail(row, userId);
  }

  /**
   * Fiche détail publique (lecture seule) : même forme que `getDetail`, mais sans
   * contrôle de propriété — la recette est hydratée avec les données de son auteur.
   * Exposé à la feature Partage (lien public résolu depuis un token). N'expose que
   * des recettes non supprimées.
   */
  async getPublicDetail(id: string): Promise<RecipeDetailDto> {
    const [row] = await this.db
      .select()
      .from(recipes)
      .where(and(eq(recipes.id, id), isNull(recipes.deletedAt)));
    if (!row) throw new NotFoundException('Recette introuvable');
    return this.buildDetail(row);
  }

  /**
   * Vérifie que la recette appartient à l'utilisateur (sinon 404). Exposé à
   * SharesService pour n'autoriser que le propriétaire à générer un lien de partage
   * (isolation des domaines : le module Partage ne touche jamais au schéma recettes).
   */
  async assertOwnedRecipe(userId: string, id: string): Promise<void> {
    await this.findOwnedOrFail(userId, id);
  }

  /**
   * Corps commun de `getDetail`/`getPublicDetail` : hydratation depuis l'auteur
   * de la recette. `viewerId` (le lecteur courant) sert au flag `isFavorite` —
   * absent en lecture publique/partage (isFavorite = false).
   */
  private async buildDetail(
    row: RecipeRow,
    viewerId?: string,
  ): Promise<RecipeDetailDto> {
    const id = row.id;
    const authorId = row.authorId;

    const isFavorite = viewerId
      ? (
          await this.db
            .select({ recipeId: recipeFavorites.recipeId })
            .from(recipeFavorites)
            .where(
              and(
                eq(recipeFavorites.userId, viewerId),
                eq(recipeFavorites.recipeId, id),
              ),
            )
            .limit(1)
        ).length > 0
      : false;

    const [ingredientRows, componentRows, stepBaseRefRows, categoryRows, tagRows, galleryRows] =
      await Promise.all([
        this.db
          .select({
            ingredientId: recipeIngredients.ingredientId,
            quantity: recipeIngredients.quantity,
            position: recipeIngredients.position,
          })
          .from(recipeIngredients)
          .where(eq(recipeIngredients.recipeId, id)),
        this.db
          .select({ baseRecipeId: recipeComponents.baseRecipeId })
          .from(recipeComponents)
          .where(eq(recipeComponents.parentRecipeId, id)),
        // Une recette de base référencée par une étape (base_ref) est aussi
        // une « sous-recette utilisée », même si elle n'a jamais été ajoutée
        // explicitement via l'onglet Ingrédients (recipe_components).
        this.db
          .select({ baseRecipeId: recipeSteps.baseRecipeRefId })
          .from(recipeSteps)
          .where(
            and(eq(recipeSteps.recipeId, id), isNotNull(recipeSteps.baseRecipeRefId)),
          ),
        this.db
          .select({ categoryId: recipeCategories.categoryId })
          .from(recipeCategories)
          .where(eq(recipeCategories.recipeId, id)),
        this.db
          .select({ tagId: recipeTags.tagId })
          .from(recipeTags)
          .where(eq(recipeTags.recipeId, id)),
        // Photos de galerie (feature galerie-recette), les plus anciennes d'abord.
        this.db
          .select({
            id: recipeGalleryImages.id,
            imageUrl: recipeGalleryImages.imageUrl,
            createdAt: recipeGalleryImages.createdAt,
          })
          .from(recipeGalleryImages)
          .where(eq(recipeGalleryImages.recipeId, id))
          .orderBy(asc(recipeGalleryImages.createdAt)),
      ]);

    // Agrégation récursive : ingrédients directs + ceux des sous-recettes de
    // base (1×), cumulés par ingrédient. Les directs gardent leur position
    // (drag & drop) et restent éditables ; les ingrédients hérités uniquement
    // des sous-recettes sont marqués `inherited` (lecture seule) et ajoutés en
    // fin de liste.
    const aggregated = await this.collectIngredientQuantities(id);
    const directIngredientIds = new Set(ingredientRows.map((r) => r.ingredientId));
    const ingredientLines = await this.hydrateIngredients(authorId, [
      ...ingredientRows.map((r) => ({
        ingredientId: r.ingredientId,
        quantity: aggregated.get(r.ingredientId) ?? r.quantity,
        position: r.position,
        inherited: false,
      })),
      ...[...aggregated.entries()]
        .filter(([ingId]) => !directIngredientIds.has(ingId))
        .map(([ingredientId, quantity]) => ({
          ingredientId,
          quantity,
          position: Number.MAX_SAFE_INTEGER,
          inherited: true,
        })),
    ]);
    const ingredientMap = new Map(ingredientLines.map((l) => [l.id, l]));
    const steps = await this.buildRecipeSteps(id, ingredientMap);
    const componentIds = new Set([
      ...componentRows.map((r) => r.baseRecipeId),
      ...stepBaseRefRows.map((r) => r.baseRecipeId!),
    ]);
    const components = await this.summariesByIds(authorId, [...componentIds]);

    // « Utilisée dans » : relation inverse, pertinente uniquement pour une base.
    let usedIn: RecipeSummaryDto[] = [];
    if (row.isBase) {
      const parents = await this.db
        .select({ parentRecipeId: recipeComponents.parentRecipeId })
        .from(recipeComponents)
        .where(eq(recipeComponents.baseRecipeId, id));
      usedIn = await this.summariesByIds(
        authorId,
        parents.map((r) => r.parentRecipeId),
      );
    }

    return {
      ...toSummary(row),
      authorId: row.authorId,
      description: row.description,
      isLocked: row.isBase && usedIn.length > 0,
      priceMode: row.priceMode,
      fixedPrice: row.fixedPrice,
      priceBracket: row.priceBracket,
      caloriesPerServing: row.caloriesPerServing,
      proteinsPerServing: row.proteinsPerServing,
      carbsPerServing: row.carbsPerServing,
      fatsPerServing: row.fatsPerServing,
      ingredients: ingredientLines,
      steps,
      components,
      usedIn,
      categoryIds: categoryRows.map((r) => r.categoryId),
      tagIds: tagRows.map((r) => r.tagId),
      isFavorite,
      galleryPhotos: galleryRows.map((r) => ({
        id: r.id,
        imageUrl: r.imageUrl,
        createdAt: r.createdAt.toISOString(),
      })),
    };
  }

  /**
   * Recettes possédées (non supprimées) + leurs ingrédients agrégés (directs +
   * ceux des sous-recettes de base en 1×, cf. `collectIngredientQuantities`),
   * pour générer une liste de courses (feature liste-courses-auto). Lève si un
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

    // Quantités agrégées par recette : ingrédients directs + ceux des
    // sous-recettes de base (1×), cumulés récursivement.
    const aggregatedByRecipe = new Map<string, Map<string, number>>();
    for (const id of uniqueIds) {
      aggregatedByRecipe.set(id, await this.collectIngredientQuantities(id));
    }

    // Hydratation en une passe (nom/unité/image via le service Ingredients).
    const allIngredientIds = [
      ...new Set([...aggregatedByRecipe.values()].flatMap((m) => [...m.keys()])),
    ];
    const owned = await this.ingredientsService.listByIds(userId, allIngredientIds);
    const ingredientMap = new Map(owned.map((i) => [i.id, i]));

    const linesByRecipe = new Map<string, RecipeIngredientLineDto[]>();
    for (const [recipeId, totals] of aggregatedByRecipe) {
      const arr: RecipeIngredientLineDto[] = [];
      for (const [ingredientId, quantity] of totals) {
        const info = ingredientMap.get(ingredientId);
        if (!info) continue; // ingrédient supprimé entre-temps → ignoré
        arr.push({
          id: info.id,
          name: info.name,
          unit: info.unit,
          imageUrl: info.imageUrl,
          quantity,
          inherited: false,
        });
      }
      linesByRecipe.set(recipeId, arr);
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

    // Garde freemium : la bascule normale→base compte comme une création de base.
    if (dto.isBase === true && !current.isBase) {
      await this.assertBaseRecipeQuota(userId);
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
    // Prix (feature prix-estime) : calculés côté client, simplement stockés ici.
    if (dto.priceMode !== undefined) patch.priceMode = dto.priceMode;
    if (dto.fixedPrice !== undefined) patch.fixedPrice = dto.fixedPrice;
    if (dto.priceBracket !== undefined) patch.priceBracket = dto.priceBracket;
    // Nutrition manuelle (feature #8), par portion.
    if (dto.caloriesPerServing !== undefined)
      patch.caloriesPerServing = dto.caloriesPerServing;
    if (dto.proteinsPerServing !== undefined)
      patch.proteinsPerServing = dto.proteinsPerServing;
    if (dto.carbsPerServing !== undefined)
      patch.carbsPerServing = dto.carbsPerServing;
    if (dto.fatsPerServing !== undefined)
      patch.fatsPerServing = dto.fatsPerServing;

    const [row] = await this.db
      .update(recipes)
      .set({ ...patch, updatedAt: new Date() })
      .where(eq(recipes.id, id))
      .returning();

    // Remplacement de couverture (feature galerie-recette) : l'ancien fichier
    // Storage est supprimé si la photo a effectivement changé. Best-effort.
    if (
      dto.photoUrl !== undefined &&
      current.photoUrl &&
      current.photoUrl !== row.photoUrl
    ) {
      await this.storage.removeByPublicUrls([current.photoUrl]);
    }

    return toSummary(row);
  }

  /**
   * Soft delete. Nettoie effectivement les fichiers Storage associés (photos de
   * galerie + couverture) — comportement plus strict que l'existant, spécifique
   * à la feature galerie-recette : le soft delete ne déclenche aucune cascade FK,
   * donc la suppression des fichiers est explicite ici.
   */
  async softDelete(userId: string, id: string): Promise<void> {
    const row = await this.findOwnedOrFail(userId, id);
    await this.db
      .update(recipes)
      .set({ deletedAt: new Date(), updatedAt: new Date() })
      .where(eq(recipes.id, id));
    await this.storage.removeByPublicUrls([
      row.photoUrl,
      ...(await this.collectGalleryUrls([id])),
    ]);
  }

  /**
   * URLs des photos de galerie des recettes données (feature galerie-recette),
   * pour le nettoyage Storage à la suppression. Lecture directe du pivot galerie :
   * il fait partie du domaine recettes (au même titre que les étapes/composants).
   */
  private async collectGalleryUrls(recipeIds: string[]): Promise<string[]> {
    if (recipeIds.length === 0) return [];
    const rows = await this.db
      .select({ imageUrl: recipeGalleryImages.imageUrl })
      .from(recipeGalleryImages)
      .where(inArray(recipeGalleryImages.recipeId, recipeIds));
    return rows.map((r) => r.imageUrl);
  }

  /**
   * Pose [url] comme couverture uniquement si la recette n'en a aucune (photo_url
   * NULL) — mécanisme « le 1er upload galerie devient la couverture » (feature
   * galerie-recette). Atomique (WHERE photo_url IS NULL) pour rester correct en
   * cas d'uploads concurrents. Retourne `true` si la photo est devenue la
   * couverture (et sort donc du quota galerie), `false` si une couverture
   * existait déjà. Exposé au service galerie (isolation : jamais d'écriture
   * directe sur `recipes` depuis un autre service).
   */
  async setPhotoIfEmpty(recipeId: string, url: string): Promise<boolean> {
    const updated = await this.db
      .update(recipes)
      .set({ photoUrl: url, updatedAt: new Date() })
      .where(and(eq(recipes.id, recipeId), isNull(recipes.photoUrl)))
      .returning({ id: recipes.id });
    return updated.length > 0;
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
    // Nouvel ingrédient ajouté en fin de liste (position = max + 1). Ré-ajouter
    // un ingrédient déjà présent ne met à jour que la quantité (position figée).
    const [last] = await this.db
      .select({ position: recipeIngredients.position })
      .from(recipeIngredients)
      .where(eq(recipeIngredients.recipeId, recipeId))
      .orderBy(desc(recipeIngredients.position))
      .limit(1);
    const nextPosition = (last?.position ?? -1) + 1;
    await this.db
      .insert(recipeIngredients)
      .values({ recipeId, ingredientId, quantity, position: nextPosition })
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

  /**
   * Réordonne les ingrédients d'une recette (drag & drop). `ingredientIds` doit
   * être une permutation exacte des ingrédients de la recette (le pivot n'a pas
   * d'id propre, on adresse donc par `ingredientId`).
   */
  async reorderIngredients(
    userId: string,
    recipeId: string,
    ingredientIds: string[],
  ): Promise<void> {
    await this.findOwnedOrFail(userId, recipeId);
    const rows = await this.db
      .select({ ingredientId: recipeIngredients.ingredientId })
      .from(recipeIngredients)
      .where(eq(recipeIngredients.recipeId, recipeId));
    const owned = new Set(rows.map((r) => r.ingredientId));
    const unique = new Set(ingredientIds);
    if (
      unique.size !== ingredientIds.length ||
      ingredientIds.length !== owned.size ||
      ingredientIds.some((id) => !owned.has(id))
    ) {
      throw new BadRequestException(
        'Liste d’ingrédients invalide pour le réordonnancement',
      );
    }
    for (let i = 0; i < ingredientIds.length; i++) {
      await this.db
        .update(recipeIngredients)
        .set({ position: i })
        .where(
          and(
            eq(recipeIngredients.recipeId, recipeId),
            eq(recipeIngredients.ingredientId, ingredientIds[i]),
          ),
        );
    }
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
    // Fichiers Storage (galerie + couvertures) collectés avant le DELETE cascade,
    // pour ne pas laisser d'orphelins après purge de compte (feature galerie-recette).
    const owned = await this.db
      .select({ id: recipes.id, photoUrl: recipes.photoUrl })
      .from(recipes)
      .where(eq(recipes.authorId, userId));
    const filesToRemove = [
      ...owned.map((r) => r.photoUrl),
      ...(await this.collectGalleryUrls(owned.map((r) => r.id))),
    ];

    await this.db.delete(recipes).where(eq(recipes.authorId, userId));
    await this.storage.removeByPublicUrls(filesToRemove);
    this.logger.log(`Recettes supprimées pour l'utilisateur ${userId}`);
  }

  // --- privé -------------------------------------------------------------

  /**
   * Quantités d'ingrédients agrégées d'une recette : ses ingrédients directs +
   * ceux de ses sous-recettes de base — composants (`recipe_components`) ET
   * références d'étape (`base_recipe_ref_id`), dédupliquées — cumulées par
   * ingrédient. Quantités BRUTES (1×, aux portions propres de chaque
   * sous-recette : `recipe_components` ne porte pas de quantité, pas de mise à
   * l'échelle). Récursif, anti-cycle via `visited`.
   */
  private async collectIngredientQuantities(
    recipeId: string,
    visited: Set<string> = new Set(),
  ): Promise<Map<string, number>> {
    const totals = new Map<string, number>();
    if (visited.has(recipeId)) return totals;
    visited.add(recipeId);

    const [direct, components, stepRefs] = await Promise.all([
      this.db
        .select({
          ingredientId: recipeIngredients.ingredientId,
          quantity: recipeIngredients.quantity,
        })
        .from(recipeIngredients)
        .where(eq(recipeIngredients.recipeId, recipeId)),
      this.db
        .select({ baseRecipeId: recipeComponents.baseRecipeId })
        .from(recipeComponents)
        .where(eq(recipeComponents.parentRecipeId, recipeId)),
      this.db
        .select({ baseRecipeId: recipeSteps.baseRecipeRefId })
        .from(recipeSteps)
        .where(
          and(
            eq(recipeSteps.recipeId, recipeId),
            isNotNull(recipeSteps.baseRecipeRefId),
          ),
        ),
    ]);

    for (const r of direct) {
      totals.set(r.ingredientId, (totals.get(r.ingredientId) ?? 0) + r.quantity);
    }

    const baseIds = new Set<string>();
    for (const c of components) baseIds.add(c.baseRecipeId);
    for (const s of stepRefs) {
      if (s.baseRecipeId) baseIds.add(s.baseRecipeId);
    }

    for (const baseId of baseIds) {
      const sub = await this.collectIngredientQuantities(baseId, visited);
      for (const [ingId, qty] of sub) {
        totals.set(ingId, (totals.get(ingId) ?? 0) + qty);
      }
    }
    return totals;
  }

  /**
   * Résout les lignes du pivot (id + quantité) en lignes affichables, en lisant
   * nom/unité/image depuis le service Ingredients (isolation des domaines). La
   * quantité vient du pivot, pas de l'ingrédient.
   */
  private async hydrateIngredients(
    userId: string,
    lines: {
      ingredientId: string;
      quantity: number;
      position?: number;
      inherited?: boolean;
    }[],
  ): Promise<RecipeIngredientLineDto[]> {
    if (lines.length === 0) return [];
    const owned = await this.ingredientsService.listByIds(
      userId,
      lines.map((l) => l.ingredientId),
    );
    const byId = new Map(owned.map((i) => [i.id, i]));
    // Ordre = `position` du pivot (drag & drop). Ordre secondaire = nom, pour un
    // rendu stable quand plusieurs lignes partagent la même position (héritage :
    // toutes à 0 avant un premier réordonnancement).
    const ordered = [...lines].sort((a, b) => {
      const pa = a.position ?? 0;
      const pb = b.position ?? 0;
      if (pa !== pb) return pa - pb;
      const na = byId.get(a.ingredientId)?.name ?? '';
      const nb = byId.get(b.ingredientId)?.name ?? '';
      return na.localeCompare(nb);
    });
    const result: RecipeIngredientLineDto[] = [];
    for (const line of ordered) {
      const i = byId.get(line.ingredientId);
      if (!i) continue; // ingrédient supprimé/non possédé : ligne omise
      result.push({
        id: i.id,
        name: i.name,
        unit: i.unit,
        imageUrl: i.imageUrl,
        quantity: line.quantity,
        inherited: line.inherited ?? false,
      });
    }
    return result;
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
