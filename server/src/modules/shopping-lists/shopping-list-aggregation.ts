import type { ShoppingItemSource } from '../../db/schema/shopping-lists.schema';

/** Ingrédient d'une recette, quantité exprimée pour `baseServings` personnes. */
export interface AggregationIngredient {
  ingredientId: string;
  name: string;
  unit: string | null;
  quantity: number;
}

/** Une recette sélectionnée : parts de base vs parts choisies + ses ingrédients. */
export interface AggregationRecipe {
  recipeId: string;
  /** Parts pour lesquelles les quantités des ingrédients sont exprimées (recette d'origine). */
  baseServings: number;
  /** Parts choisies par l'utilisateur (facteur d'échelle = chosen / base). */
  chosenServings: number;
  ingredients: AggregationIngredient[];
}

/** Article agrégé résultant (une ligne par ingrédient, quantités additionnées). */
export interface AggregatedItem {
  ingredientId: string;
  name: string;
  unit: string | null;
  /** Quantité totale (somme des contributions mises à l'échelle), arrondie 2 décimales. */
  quantity: number;
  /** Contributions par recette (déjà mises à l'échelle) — vue « par recette » + détail. */
  sources: ShoppingItemSource[];
}

/** Arrondi monétaire/quantité à 2 décimales, sans erreur de flottant. */
function round2(n: number): number {
  return Math.round((n + Number.EPSILON) * 100) / 100;
}

/**
 * Agrège les ingrédients de plusieurs recettes en une liste de courses.
 *
 * Règles (cf. features/liste-courses-auto.md) :
 * - chaque quantité est mise à l'échelle par `chosenServings / baseServings` ;
 * - un ingrédient présent dans plusieurs recettes est **additionné** en une seule
 *   ligne, en conservant le détail par recette dans `sources` ;
 * - les ingrédients déjà en stock (`pantryIngredientIds`) sont **exclus** ;
 * - l'unité étant fixée sur l'ingrédient, deux occurrences du même `ingredientId`
 *   partagent toujours la même unité — l'addition est donc toujours licite.
 *
 * Fonction pure (aucune I/O) : cœur métier testé unitairement.
 */
export function aggregateShoppingItems(
  recipes: AggregationRecipe[],
  pantryIngredientIds: Iterable<string> = [],
): AggregatedItem[] {
  const pantry = new Set(pantryIngredientIds);
  const byIngredient = new Map<string, AggregatedItem>();

  for (const recipe of recipes) {
    const factor =
      recipe.baseServings > 0 ? recipe.chosenServings / recipe.baseServings : 1;
    for (const ing of recipe.ingredients) {
      if (pantry.has(ing.ingredientId)) continue;
      const scaled = round2(ing.quantity * factor);
      const existing = byIngredient.get(ing.ingredientId);
      if (existing) {
        existing.quantity = round2(existing.quantity + scaled);
        existing.sources.push({ recipeId: recipe.recipeId, quantity: scaled });
      } else {
        byIngredient.set(ing.ingredientId, {
          ingredientId: ing.ingredientId,
          name: ing.name,
          unit: ing.unit,
          quantity: scaled,
          sources: [{ recipeId: recipe.recipeId, quantity: scaled }],
        });
      }
    }
  }

  return [...byIngredient.values()].sort((a, b) =>
    a.name.localeCompare(b.name, 'fr'),
  );
}
