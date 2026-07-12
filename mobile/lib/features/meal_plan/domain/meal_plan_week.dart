/// Semaines calendaires (lundi → dimanche) du planning, en jours civils
/// locaux. Miroir des règles serveur (`server/src/modules/meal-plan/week-window.ts`) :
/// rétention T-1 → T+2, écriture gratuite T/T+1.
library;

/// `YYYY-MM-DD` d'une date locale.
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime mondayOfWeek(DateTime d) {
  final date = DateTime(d.year, d.month, d.day);
  return date.subtract(Duration(days: date.weekday - DateTime.monday));
}

/// Une semaine affichable du planning. [offset] est relatif à la semaine
/// courante T (−1 → +2 dans la fenêtre de rétention).
class MealPlanWeek {
  const MealPlanWeek({required this.monday, required this.offset});

  final DateTime monday;
  final int offset;

  String get weekStartKey => dayKey(monday);

  DateTime dayAt(int index) => monday.add(Duration(days: index));

  /// Libellé « 6 – 12 juil. » / « 29 juin – 5 juil. » (design 1a).
  String get label {
    final end = monday.add(const Duration(days: 6));
    final sameMonth = monday.month == end.month;
    final start = sameMonth
        ? '${monday.day}'
        : '${monday.day} ${_kMonthsShortFr[monday.month - 1]}';
    return '$start – ${end.day} ${_kMonthsShortFr[end.month - 1]}';
  }

  /// Fenêtre de rétention T-1 → T+2 autour d'aujourd'hui.
  static List<MealPlanWeek> retentionWindow({DateTime? now}) {
    final currentMonday = mondayOfWeek(now ?? DateTime.now());
    return [
      for (var off = -1; off <= 2; off++)
        MealPlanWeek(
          monday: currentMonday.add(Duration(days: 7 * off)),
          offset: off,
        ),
    ];
  }

  /// Éditable pour un compte gratuit (T et T+1 uniquement).
  bool get isFreeEditable => offset == 0 || offset == 1;
}

const _kMonthsShortFr = [
  'janv.',
  'févr.',
  'mars',
  'avr.',
  'mai',
  'juin',
  'juil.',
  'août',
  'sept.',
  'oct.',
  'nov.',
  'déc.',
];
