import 'package:cocotte_minute/features/recipe_player/domain/recipe_timer.dart';
import 'package:cocotte_minute/features/recipe_player/domain/resume_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResumeState json round-trip', () {
    test('round-trips with no timers', () {
      const state = ResumeState(
        recipeId: 'r1',
        recipeName: 'Pâtes à la bolognaise',
        currentIndex: 3,
        sessionStartedAtMillis: 1000,
      );

      final decoded = ResumeState.fromJson(state.toJson());

      expect(decoded, state);
    });

    test('round-trips with timers, including null endTimeMillis/label', () {
      const state = ResumeState(
        recipeId: 'r1',
        recipeName: 'Pâtes à la bolognaise',
        currentIndex: 5,
        sessionStartedAtMillis: 1000,
        timers: [
          PersistedTimer(
            id: 't1',
            stepId: 's4',
            totalDurationSeconds: 900,
            status: TimerStatus.running,
            label: 'Mijotage',
            endTimeMillis: 5000,
          ),
          PersistedTimer(
            id: 't2',
            stepId: 's6',
            totalDurationSeconds: 600,
            status: TimerStatus.idle,
          ),
        ],
      );

      final decoded = ResumeState.fromJson(state.toJson());

      expect(decoded, state);
    });
  });
}
