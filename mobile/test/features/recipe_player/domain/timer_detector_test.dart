import 'package:cocotte_minute/features/recipe_player/domain/timer_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('detectDuration', () {
    final cases = <String, Duration?>{
      'Laisser mijoter 15 min à couvert.': const Duration(minutes: 15),
      'Cuire à feu vif pendant 20 minutes.': const Duration(minutes: 20),
      'Faire cuire 5min sans remuer.': const Duration(minutes: 5),
      'Laisser reposer 1h30 au frais.': const Duration(hours: 1, minutes: 30),
      'Cuire au four pendant 2h.': const Duration(hours: 2),
      'Laisser reposer 1 heure avant de servir.': const Duration(hours: 1),
      'Faire revenir l\'oignon et l\'ail émincés.': null,
      '': null,
    };

    cases.forEach((text, expected) {
      test('"$text" -> $expected', () {
        expect(detectDuration(text), expected);
      });
    });

    test('returns the first mentioned duration when several are present', () {
      final result = detectDuration('Laisser reposer 10 min, puis cuire 20 min.');
      expect(result, const Duration(minutes: 10));
    });

    test('is case-insensitive', () {
      expect(detectDuration('Cuire 15 MIN.'), const Duration(minutes: 15));
    });
  });
}
