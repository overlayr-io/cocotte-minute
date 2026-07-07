import 'package:cocotte_minute/core/i18n/generated/app_localizations.dart';
import 'package:cocotte_minute/core/notifications/local_notifications_service.dart';
import 'package:cocotte_minute/features/recipe_player/data/recipe_player_storage.dart';
import 'package:cocotte_minute/features/recipe_player/domain/resume_state.dart';
import 'package:cocotte_minute/features/recipe_player/presentation/bloc/recipe_player_cubit.dart';
import 'package:cocotte_minute/features/recipe_player/presentation/widgets/mobile/mobile_player_view.dart';
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
    RecipeTextStep(
      id: 's1',
      description: 'Faire revenir l\'oignon et l\'ail émincés.',
      banner: StepBanner(type: StepBannerType.warning, text: 'Feu vif.'),
      ingredients: [
        RecipeIngredientLine(id: 'i1', name: 'Oignon', unit: 'piece', quantity: 1),
      ],
    ),
    RecipeBaseRefStep(
      id: 'ref1',
      baseRecipeId: 'base1',
      baseRecipeName: 'Sauce tomate maison',
      steps: [ExpandedStep(description: 'Laisser mijoter 15 min à couvert.')],
    ),
    RecipeTextStep(id: 's3', description: 'Servir bien chaud.'),
  ],
);

/// Construit un Cubit avec des mocks fraîchement créés (et stubbés) pour un
/// test. Volontairement PAS de mocks partagés via `setUp()`/`late` : combinés
/// à un `showDialog` dans l'arbre (feuille de minuteur 10f), ce pattern fait
/// planter `flutter_test` en fin de test (hang à la vérification des
/// invariants). Réutiliser des instances fraîches par test contourne le
/// problème sans perdre de couverture.
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
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: BlocProvider.value(
          value: cubit,
          child: MobilePlayerView(cubit: cubit),
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

  testWidgets('renders the launch screen then the active step after starting',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 420));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final cubit = _buildCubit();
    addTearDown(cubit.close);

    await cubit.load();
    await _pumpApp(tester, cubit);
    await tester.pumpAndSettle();

    expect(find.text('Prêt à cuisiner ?'), findsOneWidget);
    expect(find.text('Commencer à cuisiner'), findsOneWidget);

    await tester.tap(find.text('Commencer à cuisiner'));
    await tester.pumpAndSettle();

    expect(
      find.text('Faire revenir l\'oignon et l\'ail émincés.'),
      findsOneWidget,
    );
    expect(find.text('Étape 1 / 3'), findsOneWidget);
  });

  testWidgets(
      'shows the sub-recipe context strip when navigating into a base ref step',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 420));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final cubit = _buildCubit();
    addTearDown(cubit.close);

    await cubit.load();
    await cubit.startCooking();
    cubit.nextStep();
    await _pumpApp(tester, cubit);
    await tester.pumpAndSettle();

    expect(find.textContaining('Sauce tomate maison'), findsOneWidget);
    expect(find.text('Laisser mijoter 15 min à couvert.'), findsOneWidget);
  });

  testWidgets('opens the timer sheet and starts a running timer',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 420));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final cubit = _buildCubit();

    await cubit.load();
    await cubit.startCooking();
    await _pumpApp(tester, cubit);
    await tester.pump();

    await tester.tap(find.text('Ajouter un minuteur'));
    await tester.pump();

    expect(find.text('Régler le minuteur'), findsOneWidget);

    // Démarrer le minuteur programme un Timer.periodic réel : ne pas utiliser
    // pumpAndSettle ensuite (il ne se stabiliserait jamais tant que le
    // minuteur tourne) — un pump borné suffit à refléter le nouvel état.
    await tester.tap(find.text('Démarrer le minuteur'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Minuteur'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsWidgets);

    await cubit.close();
  });

  testWidgets('reaching the last step and advancing shows the finish screen',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 420));
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
