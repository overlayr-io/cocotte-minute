import {
  aggregateShoppingItems,
  type AggregationRecipe,
} from './shopping-list-aggregation';

/** Petit builder de recette pour les tests. */
function recipe(
  recipeId: string,
  baseServings: number,
  chosenServings: number,
  ingredients: { ingredientId: string; name: string; unit?: string | null; quantity: number }[],
): AggregationRecipe {
  return {
    recipeId,
    baseServings,
    chosenServings,
    ingredients: ingredients.map((i) => ({
      ingredientId: i.ingredientId,
      name: i.name,
      unit: i.unit ?? 'gramme',
      quantity: i.quantity,
    })),
  };
}

describe('aggregateShoppingItems', () => {
  it('met à l’échelle les quantités par nombre de parts (chosen / base)', () => {
    const [item] = aggregateShoppingItems([
      recipe('r1', 2, 4, [{ ingredientId: 'i1', name: 'Farine', quantity: 100 }]),
    ]);
    // 100 g pour 2 parts → 200 g pour 4 parts.
    expect(item.quantity).toBe(200);
    expect(item.sources).toEqual([{ recipeId: 'r1', quantity: 200 }]);
  });

  it('additionne un même ingrédient présent dans plusieurs recettes en une ligne', () => {
    const items = aggregateShoppingItems([
      recipe('r1', 1, 1, [{ ingredientId: 'oignon', name: 'Oignon', unit: 'piece', quantity: 2 }]),
      recipe('r2', 1, 1, [{ ingredientId: 'oignon', name: 'Oignon', unit: 'piece', quantity: 3 }]),
    ]);
    expect(items).toHaveLength(1);
    expect(items[0].quantity).toBe(5);
    // Le détail par recette est conservé (vue « par recette » + note « 2 + 3 »).
    expect(items[0].sources).toEqual([
      { recipeId: 'r1', quantity: 2 },
      { recipeId: 'r2', quantity: 3 },
    ]);
  });

  it('additionne des contributions déjà mises à l’échelle différemment', () => {
    const items = aggregateShoppingItems([
      recipe('r1', 2, 4, [{ ingredientId: 'lait', name: 'Lait', unit: 'milligramme', quantity: 100 }]), // ×2 → 200
      recipe('r2', 4, 2, [{ ingredientId: 'lait', name: 'Lait', unit: 'milligramme', quantity: 100 }]), // ×0.5 → 50
    ]);
    expect(items[0].quantity).toBe(250);
    expect(items[0].sources).toEqual([
      { recipeId: 'r1', quantity: 200 },
      { recipeId: 'r2', quantity: 50 },
    ]);
  });

  it('exclut les ingrédients déjà en stock (placard)', () => {
    const items = aggregateShoppingItems(
      [
        recipe('r1', 1, 1, [
          { ingredientId: 'sel', name: 'Sel', quantity: 5 },
          { ingredientId: 'farine', name: 'Farine', quantity: 250 },
        ]),
      ],
      ['sel'],
    );
    expect(items).toHaveLength(1);
    expect(items[0].name).toBe('Farine');
  });

  it('arrondit les quantités à 2 décimales sans erreur de flottant', () => {
    const [item] = aggregateShoppingItems([
      recipe('r1', 3, 1, [{ ingredientId: 'i1', name: 'Sucre', quantity: 10 }]),
    ]);
    // 10 / 3 = 3.3333… → 3.33
    expect(item.quantity).toBe(3.33);
  });

  it('traite un nombre de parts de base à 0 sans division par zéro (facteur 1)', () => {
    const [item] = aggregateShoppingItems([
      recipe('r1', 0, 5, [{ ingredientId: 'i1', name: 'Eau', quantity: 20 }]),
    ]);
    expect(item.quantity).toBe(20);
  });

  it('trie les articles par nom (fr) et renvoie une liste vide pour aucune recette', () => {
    expect(aggregateShoppingItems([])).toEqual([]);
    const items = aggregateShoppingItems([
      recipe('r1', 1, 1, [
        { ingredientId: 'b', name: 'Épinard', quantity: 1 },
        { ingredientId: 'a', name: 'Ail', quantity: 1 },
      ]),
    ]);
    expect(items.map((i) => i.name)).toEqual(['Ail', 'Épinard']);
  });
});
