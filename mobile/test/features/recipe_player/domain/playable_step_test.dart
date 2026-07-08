import 'package:cocotte_minute/features/recipe_player/domain/playable_step.dart';
import 'package:cocotte_minute/features/recipes/domain/recipe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('flattenRecipeSteps', () {
    test('returns an empty list for no steps', () {
      expect(flattenRecipeSteps(const []), isEmpty);
    });

    test('flattens text-only steps with sequential indices', () {
      const steps = [
        RecipeTextStep(id: 's1', description: 'Étape 1'),
        RecipeTextStep(id: 's2', description: 'Étape 2'),
      ];

      final result = flattenRecipeSteps(steps);

      expect(result, hasLength(2));
      expect(result[0].index, 0);
      expect(result[0].sourceStepId, 's1');
      expect(result[0].subRecipe, isNull);
      expect(result[1].index, 1);
      expect(result[1].sourceStepId, 's2');
    });

    test('flattens a base-ref block into its own sub-recipe steps', () {
      const steps = [
        RecipeBaseRefStep(
          id: 'ref1',
          baseRecipeId: 'base1',
          baseRecipeName: 'Sauce tomate maison',
          steps: [
            ExpandedStep(description: 'Chauffer les tomates.'),
            ExpandedStep(description: 'Laisser mijoter 15 min.'),
          ],
        ),
      ];

      final result = flattenRecipeSteps(steps);

      expect(result, hasLength(2));
      expect(result[0].sourceStepId, 'ref1#0');
      expect(result[0].subRecipe, const SubRecipeContext(
        baseRecipeName: 'Sauce tomate maison',
        localIndex: 1,
        localTotal: 2,
      ));
      expect(result[1].sourceStepId, 'ref1#1');
      expect(result[1].subRecipe!.localIndex, 2);
      expect(result[1].subRecipe!.localTotal, 2);
    });

    test('mixes text steps and base-ref blocks with continuous numbering', () {
      const steps = [
        RecipeTextStep(id: 's1', description: 'Faire revenir.'),
        RecipeBaseRefStep(
          id: 'ref1',
          baseRecipeId: 'base1',
          baseRecipeName: 'Sauce tomate maison',
          steps: [ExpandedStep(description: 'Mijoter.')],
        ),
        RecipeTextStep(id: 's2', description: 'Servir.'),
      ];

      final result = flattenRecipeSteps(steps);

      expect(result.map((s) => s.index), [0, 1, 2]);
      expect(result[0].subRecipe, isNull);
      expect(result[1].subRecipe?.baseRecipeName, 'Sauce tomate maison');
      expect(result[2].subRecipe, isNull);
      expect(result[2].sourceStepId, 's2');
    });

    test('carries banner and ingredients through for text steps', () {
      const banner = StepBanner(type: StepBannerType.warning, text: 'Attention');
      const ingredient = RecipeIngredientLine(
        id: 'i1',
        name: 'Oignon',
        unit: 'piece',
        quantity: 1,
      );
      const steps = [
        RecipeTextStep(
          id: 's1',
          description: 'Étape',
          banner: banner,
          ingredients: [ingredient],
        ),
      ];

      final result = flattenRecipeSteps(steps);

      expect(result[0].banner, banner);
      expect(result[0].ingredients, [ingredient]);
    });

    test('carries banner through for base-ref sub-steps but no ingredients', () {
      const banner = StepBanner(type: StepBannerType.info, text: 'Info');
      const steps = [
        RecipeBaseRefStep(
          id: 'ref1',
          baseRecipeId: 'base1',
          baseRecipeName: 'Sous-recette',
          steps: [ExpandedStep(description: 'Sous-étape', banner: banner)],
        ),
      ];

      final result = flattenRecipeSteps(steps);

      expect(result[0].banner, banner);
      expect(result[0].ingredients, isEmpty);
    });
  });
}
