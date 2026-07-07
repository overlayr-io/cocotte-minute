import 'package:cocotte_minute/features/recipe_player/data/recipe_player_storage.dart';
import 'package:cocotte_minute/features/recipe_player/domain/resume_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('RecipePlayerStorage', () {
    const storage = RecipePlayerStorage();

    test('read returns null when nothing was written', () async {
      expect(await storage.read(), isNull);
    });

    test('write then read round-trips the state', () async {
      const state = ResumeState(
        recipeId: 'r1',
        recipeName: 'Pâtes à la bolognaise',
        currentIndex: 2,
        sessionStartedAtMillis: 1000,
      );

      await storage.write(state);

      expect(await storage.read(), state);
    });

    test('clear removes the persisted state', () async {
      const state = ResumeState(
        recipeId: 'r1',
        recipeName: 'Pâtes à la bolognaise',
        currentIndex: 2,
        sessionStartedAtMillis: 1000,
      );

      await storage.write(state);
      await storage.clear();

      expect(await storage.read(), isNull);
    });

    test('read returns null for corrupted data instead of throwing', () async {
      SharedPreferences.setMockInitialValues({
        'recipe_player.resume_state': 'not-json',
      });

      expect(await storage.read(), isNull);
    });
  });
}
