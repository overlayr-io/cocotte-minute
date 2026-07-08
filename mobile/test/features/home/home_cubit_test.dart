import 'package:cocotte_minute/features/categories/data/categories_repository.dart';
import 'package:cocotte_minute/features/categories/domain/category.dart';
import 'package:cocotte_minute/features/home/data/discovery_repository.dart';
import 'package:cocotte_minute/features/home/domain/discovery.dart';
import 'package:cocotte_minute/features/home/presentation/bloc/home_cubit.dart';
import 'package:cocotte_minute/features/recipes/domain/recipe.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

class _MockCategoriesRepository extends Mock implements CategoriesRepository {}

DiscoveryRecipe _r(
  String id, {
  bool seasonal = false,
  bool isBase = false,
  int prep = 20,
  int cook = 0,
  int servings = 4,
  List<String> tagIds = const [],
}) {
  return DiscoveryRecipe(
    summary: RecipeSummary(
      id: id,
      name: 'Recette $id',
      isBase: isBase,
      prepTime: prep,
      cookTime: cook,
      servings: servings,
    ),
    seasonal: seasonal,
    tagIds: tagIds,
    categoryIds: const [],
  );
}

void main() {
  late _MockDiscoveryRepository discovery;
  late _MockCategoriesRepository categories;

  setUp(() {
    discovery = _MockDiscoveryRepository();
    categories = _MockCategoriesRepository();
    when(() => categories.fetchMine()).thenAnswer((_) async => const <Category>[]);
  });

  HomeCubit build() => HomeCubit(
        discoveryRepository: discovery,
        categoriesRepository: categories,
      );

  test('hero = première recette de saison, rangées composées selon les seuils',
      () async {
    when(() => discovery.fetchHome()).thenAnswer(
      (_) async => DiscoveryData(
        month: 10,
        recipes: [
          _r('recent1', prep: 60),
          _r('season1', seasonal: true),
          _r('season2', seasonal: true),
          _r('quick1', prep: 10, cook: 5),
          _r('quick2', prep: 15),
          _r('base1', isBase: true),
          _r('base2', isBase: true),
        ],
        people: const [],
      ),
    );

    final cubit = build();
    await cubit.load();

    final state = cubit.state as HomeLoaded;
    // Hero = la première recette de saison rencontrée.
    expect(state.hero!.id, 'season1');
    expect(state.heroSeasonal, isTrue);

    final kinds = state.sections.map((s) => s.kind).toList();
    expect(kinds, contains(DiscoverySectionKind.seasonal));
    expect(kinds, contains(DiscoverySectionKind.quick));
    expect(kinds, contains(DiscoverySectionKind.recent));
    expect(kinds, contains(DiscoverySectionKind.base));

    await cubit.close();
  });

  test('une rangée avec moins de 2 recettes est omise', () async {
    when(() => discovery.fetchHome()).thenAnswer(
      (_) async => DiscoveryData(
        month: 3,
        recipes: [
          _r('a', servings: 4),
          _r('b', servings: 4),
          _r('big', servings: 8), // une seule « pour la tablée » → pas de rangée
        ],
        people: const [],
      ),
    );

    final cubit = build();
    await cubit.load();

    final state = cubit.state as HomeLoaded;
    final kinds = state.sections.map((s) => s.kind).toList();
    expect(kinds, isNot(contains(DiscoverySectionKind.large)));

    await cubit.close();
  });

  test('rangée « Pour {personne} » via intersection des tags', () async {
    when(() => discovery.fetchHome()).thenAnswer(
      (_) async => DiscoveryData(
        month: 6,
        recipes: [
          _r('m1', tagIds: ['t1']),
          _r('m2', tagIds: ['t1', 't2']),
          _r('other', tagIds: ['tX']),
        ],
        people: const [
          DiscoveryPerson(
            id: 'p1',
            firstName: 'Emma',
            avatarUrl: null,
            tagIds: ['t1'],
          ),
        ],
      ),
    );

    final cubit = build();
    await cubit.load();

    final state = cubit.state as HomeLoaded;
    final personRow = state.sections
        .where((s) => s.kind == DiscoverySectionKind.person)
        .toList();
    expect(personRow, hasLength(1));
    expect(personRow.first.personName, 'Emma');
    expect(personRow.first.recipes.map((r) => r.id), containsAll(['m1', 'm2']));
    expect(personRow.first.recipes.map((r) => r.id), isNot(contains('other')));

    await cubit.close();
  });

  test('compte vide → HomeLoaded.isEmpty', () async {
    when(() => discovery.fetchHome()).thenAnswer(
      (_) async => const DiscoveryData(month: 1, recipes: [], people: []),
    );

    final cubit = build();
    await cubit.load();

    expect((cubit.state as HomeLoaded).isEmpty, isTrue);

    await cubit.close();
  });
}
