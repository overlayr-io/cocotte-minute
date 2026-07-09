import 'package:cocotte_minute/core/premium/premium_limit_error.dart';
import 'package:cocotte_minute/features/categories/data/categories_repository.dart';
import 'package:cocotte_minute/features/categories/domain/category.dart';
import 'package:cocotte_minute/features/people/data/people_repository.dart';
import 'package:cocotte_minute/features/recipes/domain/recipe.dart';
import 'package:cocotte_minute/features/search/data/search_repository.dart';
import 'package:cocotte_minute/features/search/presentation/bloc/search_cubit.dart';
import 'package:cocotte_minute/features/tags/data/tags_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSearchRepository extends Mock implements SearchRepository {}

class _MockCategoriesRepository extends Mock implements CategoriesRepository {}

class _MockTagsRepository extends Mock implements TagsRepository {}

class _MockPeopleRepository extends Mock implements PeopleRepository {}

Category _folder(int i) => Category(id: 'c$i', name: 'Dossier $i');

void main() {
  late _MockSearchRepository search;
  late _MockCategoriesRepository categories;
  late _MockTagsRepository tags;
  late _MockPeopleRepository people;

  setUp(() {
    search = _MockSearchRepository();
    categories = _MockCategoriesRepository();
    tags = _MockTagsRepository();
    people = _MockPeopleRepository();
    when(
      () => search.search(
        query: any(named: 'query'),
        categoryIds: any(named: 'categoryIds'),
        tagIds: any(named: 'tagIds'),
        personIds: any(named: 'personIds'),
      ),
    ).thenAnswer((_) async => const <RecipeSummary>[]);
  });

  SearchCubit build({required bool premium}) => SearchCubit(
        searchRepository: search,
        categoriesRepository: categories,
        tagsRepository: tags,
        peopleRepository: people,
        isPremium: () => premium,
      );

  test('gratuit : le 7e critère est bloqué et signale l\'upsell', () async {
    final cubit = build(premium: false);

    for (var i = 0; i < 6; i++) {
      cubit.addFolder(_folder(i));
    }
    expect(cubit.state.tokens, hasLength(6));
    expect(cubit.state.criteriaCount, 6);
    expect(cubit.state.limitBlockTick, 0);

    cubit.addFolder(_folder(6));
    expect(cubit.state.tokens, hasLength(6), reason: 'ajout refusé');
    expect(cubit.state.limitBlockTick, 1);

    // Chaque nouvelle tentative re-déclenche la feuille (tick incrémenté).
    cubit.addFolder(_folder(7));
    expect(cubit.state.limitBlockTick, 2);

    // Laisse les _runSearch en vol se terminer avant la fermeture.
    await Future<void>.delayed(Duration.zero);
    await cubit.close();
  });

  test('premium : aucun plafond de critères', () async {
    final cubit = build(premium: true);

    for (var i = 0; i < 8; i++) {
      cubit.addFolder(_folder(i));
    }
    expect(cubit.state.tokens, hasLength(8));
    expect(cubit.state.limitBlockTick, 0);

    // Laisse les _runSearch en vol se terminer avant la fermeture.
    await Future<void>.delayed(Duration.zero);
    await cubit.close();
  });

  test('403 serveur PREMIUM_LIMIT_SEARCH_CRITERIA : upsell défensif', () async {
    when(
      () => search.search(
        query: any(named: 'query'),
        categoryIds: any(named: 'categoryIds'),
        tagIds: any(named: 'tagIds'),
        personIds: any(named: 'personIds'),
      ),
    ).thenThrow(
      const SearchRepositoryException(
        'Limite de critères atteinte.',
        premiumLimit: PremiumLimitError(
          code: PremiumLimitError.searchCriteria,
          limit: 6,
          current: 7,
        ),
      ),
    );

    // Premium côté client (état local périmé) : le serveur reste l'autorité.
    final cubit = build(premium: true);
    cubit.addFolder(_folder(0));
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.limitBlockTick, 1);
    expect(cubit.state.actionMessage, isNull);

    await cubit.close();
  });
}
