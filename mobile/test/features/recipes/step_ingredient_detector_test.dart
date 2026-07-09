import 'package:cocotte_minute/features/recipes/domain/recipe.dart';
import 'package:cocotte_minute/features/recipes/presentation/widgets/step_ingredient_detector.dart';
import 'package:flutter_test/flutter_test.dart';

RecipeIngredientLine ing(String id, String name) =>
    RecipeIngredientLine(id: id, name: name, unit: 'gramme', quantity: 1);

void main() {
  final ingredients = [
    ing('1', 'Oignon'),
    ing('2', 'Beurre'),
    ing('3', 'Ail'),
    ing('4', 'Huile d\'olive'),
    ing('5', 'Épinard'),
  ];

  group('detectIngredientIds', () {
    test('détecte un mot exact', () {
      expect(
        detectIngredientIds('Faire fondre le beurre', ingredients),
        {'2'},
      );
    });

    test('tolère le pluriel (nom singulier, texte pluriel)', () {
      expect(
        detectIngredientIds('Émincer les oignons', ingredients),
        {'1'},
      );
    });

    test('insensible à la casse et aux accents', () {
      expect(
        detectIngredientIds('Ajouter les EPINARDS puis l\'ail', ingredients),
        {'3', '5'},
      );
    });

    test('gère les noms multi-mots', () {
      expect(
        detectIngredientIds('Un filet d\'huile d\'olive', ingredients),
        {'4'},
      );
    });

    test('match uniquement sur mot entier (pas au milieu d\'un mot)', () {
      // « ailleurs » ne doit pas matcher « ail ».
      expect(
        detectIngredientIds('On verra ailleurs', ingredients),
        isEmpty,
      );
    });

    test('texte vide → aucun résultat', () {
      expect(detectIngredientIds('   ', ingredients), isEmpty);
    });
  });
}
