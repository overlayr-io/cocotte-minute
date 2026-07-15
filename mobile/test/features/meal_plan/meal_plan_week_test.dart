import 'package:cocotte_minute/features/meal_plan/domain/meal_plan_week.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  test('mondayOfWeek retombe sur le lundi, dimanche inclus', () {
    expect(mondayOfWeek(DateTime(2026, 7, 6)), DateTime(2026, 7, 6));
    expect(mondayOfWeek(DateTime(2026, 7, 11)), DateTime(2026, 7, 6));
    expect(mondayOfWeek(DateTime(2026, 7, 12)), DateTime(2026, 7, 6));
  });

  test('dayKey est zéro-paddé', () {
    expect(dayKey(DateTime(2026, 7, 6)), '2026-07-06');
    expect(dayKey(DateTime(2026, 1, 1)), '2026-01-01');
  });

  test('retentionWindow couvre T-1 → T+2 autour du lundi courant', () {
    final weeks = MealPlanWeek.retentionWindow(now: DateTime(2026, 7, 11));
    expect(weeks, hasLength(4));
    expect(weeks.map((w) => w.offset), [-1, 0, 1, 2]);
    expect(weeks[0].monday, DateTime(2026, 6, 29));
    expect(weeks[1].monday, DateTime(2026, 7, 6));
    expect(weeks[3].monday, DateTime(2026, 7, 20));
  });

  test('isFreeEditable : T et T+1 uniquement', () {
    final weeks = MealPlanWeek.retentionWindow(now: DateTime(2026, 7, 11));
    expect(weeks.map((w) => w.isFreeEditable), [false, true, true, false]);
  });

  test('label : même mois et mois à cheval (design 1a)', () {
    final weeks = MealPlanWeek.retentionWindow(now: DateTime(2026, 7, 11));
    expect(weeks[1].label('fr'), '6 – 12 juil.');
    expect(weeks[0].label('fr'), '29 juin – 5 juil.');
  });
}
