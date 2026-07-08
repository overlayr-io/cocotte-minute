import 'package:cocotte_minute/core/notifications/local_notifications_service.dart';
import 'package:cocotte_minute/features/recipe_player/data/recipe_player_storage.dart';
import 'package:cocotte_minute/features/recipe_player/domain/recipe_timer.dart';
import 'package:cocotte_minute/features/recipe_player/domain/resume_state.dart';
import 'package:cocotte_minute/features/recipe_player/presentation/bloc/recipe_player_cubit.dart';
import 'package:cocotte_minute/features/recipes/data/recipes_repository.dart';
import 'package:cocotte_minute/features/recipes/domain/recipe.dart';
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
    RecipeTextStep(id: 's1', description: 'Étape 1'),
    RecipeTextStep(id: 's2', description: 'Étape 2'),
    RecipeTextStep(id: 's3', description: 'Étape 3'),
  ],
);

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late _MockRecipesRepository repository;
  late _MockRecipePlayerStorage storage;
  late _MockLocalNotificationsService notifications;

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

  RecipePlayerCubit buildCubit({String recipeId = 'r1'}) {
    return RecipePlayerCubit(
      repository: repository,
      storage: storage,
      notifications: notifications,
      recipeId: recipeId,
    );
  }

  Future<RecipePlayerCubit> loadedCubit({ResumeState? resume}) async {
    when(() => repository.fetchDetail('r1')).thenAnswer((_) async => _detail);
    when(() => storage.read()).thenAnswer((_) async => resume);
    final cubit = buildCubit();
    await cubit.load();
    return cubit;
  }

  Future<RecipePlayerCubit> playingCubit() async {
    final cubit = await loadedCubit();
    await cubit.startCooking();
    return cubit;
  }

  setUp(() {
    repository = _MockRecipesRepository();
    storage = _MockRecipePlayerStorage();
    notifications = _MockLocalNotificationsService();

    when(() => notifications.requestPermissionIfNeeded())
        .thenAnswer((_) async {});
    when(
      () => notifications.schedule(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        fireAt: any(named: 'fireAt'),
      ),
    ).thenAnswer((_) async {});
    when(() => notifications.cancel(any())).thenAnswer((_) async {});
    when(() => storage.write(any())).thenAnswer((_) async {});
    when(() => storage.clear()).thenAnswer((_) async {});
  });

  group('load', () {
    test('emits Loading then Loaded, no pending resume', () async {
      when(() => repository.fetchDetail('r1')).thenAnswer((_) async => _detail);
      when(() => storage.read()).thenAnswer((_) async => null);

      final cubit = buildCubit();
      expect(cubit.state, isA<RecipePlayerLoading>());

      await cubit.load();

      expect(
        cubit.state,
        isA<RecipePlayerLoaded>()
            .having((s) => s.phase, 'phase', PlayerPhase.launch)
            .having((s) => s.totalSteps, 'totalSteps', 3)
            .having((s) => s.pendingResume, 'pendingResume', isNull),
      );

      await cubit.close();
    });

    test('emits Error when the repository throws', () async {
      when(
        () => repository.fetchDetail('r1'),
      ).thenThrow(const RecipesRepositoryException('boom'));

      final cubit = buildCubit();
      await cubit.load();

      expect(cubit.state, isA<RecipePlayerError>());
      await cubit.close();
    });

    test('surfaces pendingResume for a matching recipeId', () async {
      const resume = ResumeState(
        recipeId: 'r1',
        recipeName: 'Pâtes à la bolognaise',
        selectedServings: 2,
        currentIndex: 1,
        sessionStartedAtMillis: 1000,
      );
      final cubit = await loadedCubit(resume: resume);

      final loaded = cubit.state as RecipePlayerLoaded;
      expect(loaded.pendingResume, resume);
      expect(loaded.pendingSwitchWarning, isNull);

      await cubit.close();
    });

    test('surfaces pendingSwitchWarning for a different recipeId', () async {
      const resume = ResumeState(
        recipeId: 'other',
        recipeName: 'Tarte aux pommes',
        selectedServings: 6,
        currentIndex: 4,
        sessionStartedAtMillis: 1000,
      );
      final cubit = await loadedCubit(resume: resume);

      final loaded = cubit.state as RecipePlayerLoaded;
      expect(loaded.pendingResume, isNull);
      expect(
        loaded.pendingSwitchWarning,
        const SwitchRecipeWarning(recipeName: 'Tarte aux pommes', stepIndex: 4),
      );

      await cubit.close();
    });
  });

  group('navigation', () {
    test('startCooking moves to playing phase at index 0 and persists', () async {
      final cubit = await playingCubit();

      final loaded = cubit.state as RecipePlayerLoaded;
      expect(loaded.phase, PlayerPhase.playing);
      expect(loaded.currentIndex, 0);
      verify(() => storage.write(any())).called(greaterThanOrEqualTo(1));

      await cubit.close();
    });

    test('nextStep advances the index and finishes on the last step', () async {
      final cubit = await playingCubit();

      cubit.nextStep();
      await _settle();
      expect((cubit.state as RecipePlayerLoaded).currentIndex, 1);

      cubit.nextStep();
      await _settle();
      expect((cubit.state as RecipePlayerLoaded).currentIndex, 2);

      cubit.nextStep();
      await _settle();
      expect((cubit.state as RecipePlayerLoaded).phase, PlayerPhase.finished);
      verify(() => storage.clear()).called(greaterThanOrEqualTo(1));

      await cubit.close();
    });

    test('previousStep is a no-op at the first step', () async {
      final cubit = await playingCubit();

      cubit.previousStep();
      await _settle();

      expect((cubit.state as RecipePlayerLoaded).currentIndex, 0);

      await cubit.close();
    });

    test('jumpToStep ignores out-of-range indices', () async {
      final cubit = await playingCubit();

      cubit.jumpToStep(99);
      await _settle();
      expect((cubit.state as RecipePlayerLoaded).currentIndex, 0);

      cubit.jumpToStep(2);
      await _settle();
      expect((cubit.state as RecipePlayerLoaded).currentIndex, 2);

      await cubit.close();
    });
  });

  group('timers', () {
    test('startTimer creates a running timer and requests permission', () async {
      final cubit = await playingCubit();

      await cubit.startTimer('s1', const Duration(minutes: 15));

      final loaded = cubit.state as RecipePlayerLoaded;
      expect(loaded.timers, hasLength(1));
      expect(loaded.timers.single.status, TimerStatus.running);
      expect(loaded.runningTimer, isNotNull);
      verify(() => notifications.requestPermissionIfNeeded()).called(1);
      verify(
        () => notifications.schedule(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          fireAt: any(named: 'fireAt'),
        ),
      ).called(1);

      await cubit.close();
    });

    test('starting a second timer pauses the first (single running invariant)', () async {
      final cubit = await playingCubit();

      await cubit.startTimer('s1', const Duration(minutes: 15));
      await cubit.startTimer('s2', const Duration(minutes: 5));

      final loaded = cubit.state as RecipePlayerLoaded;
      expect(loaded.timers, hasLength(2));
      expect(
        loaded.timers.where((t) => t.status == TimerStatus.running),
        hasLength(1),
      );
      expect(
        loaded.timers.where((t) => t.status == TimerStatus.paused),
        hasLength(1),
      );

      await cubit.close();
    });

    test('resetTimer restores the total duration and sets idle', () async {
      final cubit = await playingCubit();
      await cubit.startTimer('s1', const Duration(minutes: 15));
      final timerId = (cubit.state as RecipePlayerLoaded).timers.single.id;

      await cubit.resetTimer(timerId);

      final loaded = cubit.state as RecipePlayerLoaded;
      expect(loaded.timers.single.status, TimerStatus.idle);
      expect(loaded.timers.single.remaining, const Duration(minutes: 15));
      verify(() => notifications.cancel(any())).called(greaterThanOrEqualTo(1));

      await cubit.close();
    });

    test('cancelTimer removes the timer from the list', () async {
      final cubit = await playingCubit();
      await cubit.startTimer('s1', const Duration(minutes: 15));
      final timerId = (cubit.state as RecipePlayerLoaded).timers.single.id;

      await cubit.cancelTimer(timerId);

      expect((cubit.state as RecipePlayerLoaded).timers, isEmpty);

      await cubit.close();
    });
  });

  group('quitSession', () {
    test('keeps the resume state (no purge) so it can be resumed later', () async {
      final cubit = await playingCubit();
      await cubit.startTimer('s1', const Duration(minutes: 15));

      await cubit.quitSession();

      // Abandon en cours de route : on conserve l'état (pas de clear) et on
      // garde les minuteurs programmés (pas de cancel).
      verifyNever(() => storage.clear());
      verify(() => storage.write(any())).called(greaterThanOrEqualTo(1));

      await cubit.close();
    });

    test('a fresh load after quitting offers to resume', () async {
      // La session persistée par le quit est relue au prochain lancement.
      ResumeState? persisted;
      when(() => storage.write(any())).thenAnswer((invocation) async {
        persisted = invocation.positionalArguments.first as ResumeState;
      });
      final cubit = await playingCubit();
      cubit.nextStep();
      await cubit.quitSession();
      expect(persisted, isNotNull);

      when(() => storage.read()).thenAnswer((_) async => persisted);
      final reopened = buildCubit();
      await reopened.load();

      final loaded = reopened.state as RecipePlayerLoaded;
      expect(loaded.phase, PlayerPhase.launch);
      expect(loaded.pendingResume, isNotNull);
      expect(loaded.pendingResume!.currentIndex, persisted!.currentIndex);

      await cubit.close();
      await reopened.close();
    });
  });

  group('resume flow', () {
    const resume = ResumeState(
      recipeId: 'r1',
      recipeName: 'Pâtes à la bolognaise',
      selectedServings: 2,
      currentIndex: 1,
      sessionStartedAtMillis: 1000,
    );

    test('resumeSession jumps directly into playing at the saved step/servings', () async {
      final cubit = await loadedCubit(resume: resume);

      await cubit.resumeSession();

      final loaded = cubit.state as RecipePlayerLoaded;
      expect(loaded.phase, PlayerPhase.playing);
      expect(loaded.currentIndex, 1);
      expect(loaded.selectedServings, 2);
      expect(loaded.pendingResume, isNull);

      await cubit.close();
    });

    test('dismissResume clears the pending resume without changing phase', () async {
      final cubit = await loadedCubit(resume: resume);

      cubit.dismissResume();

      final loaded = cubit.state as RecipePlayerLoaded;
      expect(loaded.pendingResume, isNull);
      expect(loaded.phase, PlayerPhase.launch);

      await cubit.close();
    });

    test('confirmSwitchRecipe clears storage and the pending warning', () async {
      const otherResume = ResumeState(
        recipeId: 'other',
        recipeName: 'Tarte aux pommes',
        selectedServings: 6,
        currentIndex: 4,
        sessionStartedAtMillis: 1000,
      );
      final cubit = await loadedCubit(resume: otherResume);

      await cubit.confirmSwitchRecipe();

      final loaded = cubit.state as RecipePlayerLoaded;
      expect(loaded.pendingSwitchWarning, isNull);
      verify(() => storage.clear()).called(greaterThanOrEqualTo(1));

      await cubit.close();
    });
  });
}
