import 'package:cocotte_minute/core/i18n/generated/app_localizations.dart';
import 'package:cocotte_minute/features/meal_plan/domain/meal_plan_entry.dart';
import 'package:cocotte_minute/features/meal_plan/domain/meal_plan_week.dart';
import 'package:cocotte_minute/features/meal_plan/presentation/widgets/planning_boards.dart';
import 'package:cocotte_minute/features/recipes/domain/recipe.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Rendu réel des deux mises en page du calendrier : attrape les erreurs de
/// layout (hauteur infinie, RenderBox non posé…) que les tests de cubit ne
/// voient pas.
void main() {
  final week = MealPlanWeek.retentionWindow().firstWhere((w) => w.offset == 0);
  final day = week.weekStartKey;

  final entries = <MealPlanEntry>[
    MealPlanEntry(
      id: 'e1',
      day: day,
      slot: MealSlot.midi,
      type: MealEntryType.recipe,
      recipe: const RecipeSummary(id: 'r1', name: 'Bolo', servings: 2),
    ),
    MealPlanEntry(
      id: 'e2',
      day: day,
      slot: MealSlot.midi,
      type: MealEntryType.recipe,
      recipe: const RecipeSummary(id: 'r2', name: 'Curry', servings: 2),
      position: 1,
    ),
    MealPlanEntry(
      id: 'e3',
      day: day,
      slot: MealSlot.soir,
      type: MealEntryType.note,
      noteText: 'Pâtes sauce tomate',
    ),
    MealPlanEntry(
      id: 'e4',
      day: day,
      slot: MealSlot.matin,
      type: MealEntryType.eatingOut,
    ),
  ];

  PlanningBoardData data({bool readonly = false, bool selectMode = false}) =>
      PlanningBoardData(
        week: week,
        entriesOf: (d, slot) => entries
            .where((e) => e.day == d && e.slot == slot)
            .toList(),
        readonly: readonly,
        selectMode: selectMode,
        selectedSlots: const {},
      );

  Widget app(Widget child) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('fr'),
    home: Scaffold(body: child),
  );

  testWidgets('la vue Grille se rend sans erreur de layout', (tester) async {
    await tester.pumpWidget(
      app(
        Column(
          children: [
            const PlanningGridHeader(),
            Expanded(child: PlanningGridBoard(data: data())),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Bolo'), findsOneWidget);
    expect(find.text('＋1 autre'), findsOneWidget);
  });

  testWidgets('la vue Grille en lecture seule se rend aussi', (tester) async {
    await tester.pumpWidget(
      app(PlanningGridBoard(data: data(readonly: true))),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('la vue Blocs se rend sans erreur de layout', (tester) async {
    await tester.pumpWidget(app(PlanningBlocksBoard(data: data())));
    expect(tester.takeException(), isNull);
    expect(find.text('Manger dehors'), findsOneWidget);
    expect(find.text('Pâtes sauce tomate'), findsOneWidget);
  });
}
