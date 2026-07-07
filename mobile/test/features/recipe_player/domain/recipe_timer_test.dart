import 'package:cocotte_minute/features/recipe_player/domain/recipe_timer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecipeTimer.copyWith', () {
    const base = RecipeTimer(
      id: 't1',
      stepId: 's1',
      totalDuration: Duration(minutes: 15),
      status: TimerStatus.idle,
    );

    test('overrides status while keeping other fields', () {
      final started = base.copyWith(
        status: TimerStatus.running,
        endTime: DateTime.fromMillisecondsSinceEpoch(1000),
      );

      expect(started.status, TimerStatus.running);
      expect(started.endTime, DateTime.fromMillisecondsSinceEpoch(1000));
      expect(started.id, base.id);
      expect(started.totalDuration, base.totalDuration);
    });

    test('clearEndTime resets endTime to null', () {
      final running = base.copyWith(
        status: TimerStatus.running,
        endTime: DateTime.fromMillisecondsSinceEpoch(1000),
      );

      final paused = running.copyWith(status: TimerStatus.paused, clearEndTime: true);

      expect(paused.endTime, isNull);
      expect(paused.status, TimerStatus.paused);
    });
  });
}
