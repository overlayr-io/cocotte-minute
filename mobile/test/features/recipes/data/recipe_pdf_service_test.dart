import 'package:cocotte_minute/core/i18n/generated/app_localizations.dart';
import 'package:cocotte_minute/features/recipes/data/recipe_pdf_service.dart';
import 'package:cocotte_minute/features/recipes/domain/recipe.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('fr'));
  });

  const detail = RecipeDetail(
    summary: RecipeSummary(
      id: 'r1',
      name: 'Velouté de courge rôtie',
      servings: 4,
      prepTime: 90,
      cookTime: 45,
      restTime: 0,
    ),
    authorId: 'u1',
    description: 'Un velouté réconfortant pour les soirées d\'automne.',
    ingredients: [
      RecipeIngredientLine(id: 'i1', name: 'Courge', unit: 'gramme', quantity: 800),
      RecipeIngredientLine(id: 'i2', name: 'Crème', unit: 'gramme', quantity: 200),
      RecipeIngredientLine(id: 'i3', name: 'Sel', unit: 'cuillere_cafe', quantity: 1),
    ],
    steps: [
      RecipeTextStep(
        id: 's1',
        description: 'Éplucher et couper la courge en cubes.',
      ),
      RecipeTextStep(
        id: 's2',
        description: 'Rôtir au four 40 minutes.',
        banner: StepBanner(type: StepBannerType.warning, text: 'Surveiller la coloration.'),
      ),
      RecipeBaseRefStep(
        id: 's3',
        baseRecipeId: 'b1',
        baseRecipeName: 'Bouillon maison',
        steps: [
          ExpandedStep(description: 'Faire revenir les légumes.'),
          ExpandedStep(
            description: 'Laisser mijoter 1 h.',
            banner: StepBanner(type: StepBannerType.info, text: 'À feu doux.'),
          ),
        ],
      ),
    ],
    components: [
      RecipeSummary(id: 'b1', name: 'Bouillon maison', isBase: true, servings: 4),
    ],
  );

  test('génère un PDF non vide pour une recette complète', () async {
    final bytes = await RecipePdfService().build(detail, l10n);

    expect(bytes.lengthInBytes, greaterThan(2000));
    // En-tête PDF valide.
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('gère une recette minimale (sans ingrédients ni étapes)', () async {
    const empty = RecipeDetail(
      summary: RecipeSummary(id: 'r2', name: 'Recette vide', servings: 1),
      authorId: 'u1',
    );
    final bytes = await RecipePdfService().build(empty, l10n);
    expect(bytes.lengthInBytes, greaterThan(1000));
  });
}
