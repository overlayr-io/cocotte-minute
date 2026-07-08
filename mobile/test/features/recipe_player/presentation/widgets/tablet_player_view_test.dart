import 'package:cocotte_minute/core/i18n/generated/app_localizations.dart';
import 'package:cocotte_minute/core/notifications/local_notifications_service.dart';
import 'package:cocotte_minute/features/recipe_player/data/recipe_player_storage.dart';
import 'package:cocotte_minute/features/recipe_player/domain/resume_state.dart';
import 'package:cocotte_minute/features/recipe_player/presentation/bloc/recipe_player_cubit.dart';
import 'package:cocotte_minute/features/recipe_player/presentation/widgets/tablet/tablet_player_view.dart';
import 'package:cocotte_minute/features/recipes/data/recipes_repository.dart';
import 'package:cocotte_minute/features/recipes/domain/recipe.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRecipesRepository extends Mock implements RecipesRepository {}

class _MockRecipePlayerStorage extends Mock implements RecipePlayerStorage {}

class _MockLocalNotificationsService extends Mock
    implements LocalNotificationsService {}

const _detail = RecipeDetail(
  summary: RecipeSummary(id: 'r1', name: 'Pâtes à la bolognaise', servings: 4),
  authorId: 'u1',
  steps: [
    RecipeTextStep(id: 's1', description: 'Faire revenir l\'oignon et l\'ail.'),
    RecipeBaseRefStep(
      id: 'ref1',
      baseRecipeId: 'base1',
      baseRecipeName: 'Sauce tomate maison',
      steps: [ExpandedStep(description: 'Laisser mijoter 15 min à couvert.')],
    ),
    RecipeTextStep(id: 's3', description: 'Servir bien chaud.'),
  ],
);

/// Mocks recréés par test (pas de setUp()/late) : combinés à un showDialog
/// dans l'arbre, ce pattern fait planter flutter_test en fin de test.
RecipePlayerCubit _buildCubit({String recipeId = 'r1'}) {
  final repository = _MockRecipesRepository();
  final storage = _MockRecipePlayerStorage();
  final notifications = _MockLocalNotificationsService();

  when(() => repository.fetchDetail(recipeId)).thenAnswer((_) async => _detail);
  when(() => storage.read()).thenAnswer((_) async => null);
  when(() => storage.write(any())).thenAnswer((_) async {});
  when(() => storage.clear()).thenAnswer((_) async {});
  when(() => notifications.requestPermissionIfNeeded()).thenAnswer((_) async {});
  when(
    () => notifications.schedule(
      id: any(named: 'id'),
      title: any(named: 'title'),
      body: any(named: 'body'),
      fireAt: any(named: 'fireAt'),
    ),
  ).thenAnswer((_) async {});
  when(() => notifications.cancel(any())).thenAnswer((_) async {});

  return RecipePlayerCubit(
    repository: repository,
    storage: storage,
    notifications: notifications,
    recipeId: recipeId,
  );
}

Future<void> _pumpApp(WidgetTester tester, RecipePlayerCubit cubit) async {
  await tester.pumpWidget(
    MaterialApp(
      // Locale figée : les assertions ciblent les textes FR.
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: BlocProvider.value(
          value: cubit,
          child: TabletPlayerView(cubit: cubit),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const ResumeState(
        recipeId: 'fallback',
        recipeName: 'fallback',
        selectedServings: 1,
        currentIndex: 0,
        sessionStartedAtMillis: 0,
      ),
    );
  });

  testWidgets('renders the tablet launch screen then the active step',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1180, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final cubit = _buildCubit();
    addTearDown(cubit.close);

    await cubit.load();
    await _pumpApp(tester, cubit);
    await tester.pumpAndSettle();

    expect(find.text('Prêt à cuisiner ?'), findsOneWidget);

    await tester.tap(find.text('Commencer à cuisiner'));
    await tester.pumpAndSettle();

    expect(
      find.text('Faire revenir l\'oignon et l\'ail.'),
      findsOneWidget,
    );
  });

  testWidgets('opens the summary and jumps to a step by tapping it',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1180, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final cubit = _buildCubit();
    addTearDown(cubit.close);

    await cubit.load();
    await cubit.startCooking();
    await _pumpApp(tester, cubit);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Étape 1 / 3'));
    await tester.pumpAndSettle();

    expect(find.text('Toutes les étapes'), findsOneWidget);
    expect(find.textContaining('Sauce tomate maison'), findsOneWidget);

    await tester.tap(find.text('Servir bien chaud.'));
    await tester.pumpAndSettle();

    expect((cubit.state as RecipePlayerLoaded).currentIndex, 2);
    expect(find.text('Toutes les étapes'), findsNothing);
    expect(find.text('Servir bien chaud.'), findsOneWidget);
  });

  testWidgets('reaching the last step and advancing shows the finish screen',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1180, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final cubit = _buildCubit();
    addTearDown(cubit.close);

    await cubit.load();
    await cubit.startCooking();
    cubit.jumpToStep(2);
    await _pumpApp(tester, cubit);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();

    expect(find.text('C\'est prêt !'), findsOneWidget);
  });
}
