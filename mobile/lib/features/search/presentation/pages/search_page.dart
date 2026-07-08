import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../categories/data/categories_repository.dart';
import '../../../categories/domain/category.dart';
import '../../../people/data/people_repository.dart';
import '../../../recipes/presentation/pages/recipe_detail_page.dart';
import '../../../tags/data/tags_repository.dart';
import '../../data/search_repository.dart';
import '../bloc/search_cubit.dart';
import '../widgets/search_colors.dart';
import '../widgets/search_field.dart';
import '../widgets/search_menu.dart';
import '../widgets/search_result_card.dart';

/// Écran de recherche avancée (maquettes 11a-e) : barre globale « à la Notion »
/// où l'on tape `/` (dossier), `#` (tag) ou `@` (personne), les critères se
/// cumulant en pastilles (ET), puis liste des recettes correspondantes.
class SearchPage extends StatelessWidget {
  const SearchPage({super.key, this.initialFolder});

  /// Dossier pré-sélectionné (ex: depuis une chip catégorie de l'accueil).
  final Category? initialFolder;

  /// Fondu (pas de glissement) : la barre de recherche étant identique à celle
  /// de l'accueil, la transition doit se lire comme un « mode » de la même page.
  static Route<void> route({Category? initialFolder}) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, _, _) => SearchPage(initialFolder: initialFolder),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = SearchCubit(
          searchRepository: sl<SearchRepository>(),
          categoriesRepository: sl<CategoriesRepository>(),
          tagsRepository: sl<TagsRepository>(),
          peopleRepository: sl<PeopleRepository>(),
        );
        cubit.init();
        if (initialFolder != null) cubit.addFolder(initialFolder!);
        return cubit;
      },
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatelessWidget {
  const _SearchView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: BlocConsumer<SearchCubit, SearchState>(
          listenWhen: (p, c) =>
              p.actionMessage != c.actionMessage && c.actionMessage != null,
          listener: (context, state) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.actionMessage!)));
          },
          builder: (context, state) {
            if (state.referenceStatus == SearchStatus.failure) {
              return ErrorView(
                message: state.errorMessage ?? l10n.commonRetry,
                onRetry: () => context.read<SearchCubit>().init(),
              );
            }
            if (state.referenceStatus == SearchStatus.loading ||
                state.referenceStatus == SearchStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }
            return _content(context, state, l10n);
          },
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    SearchState state,
    AppLocalizations l10n,
  ) {
    final showTriggers = state.openMenu != null || state.isIdle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Header(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: SearchField(state: state),
        ),
        // Requête en cours : fine barre de progression sous le champ, les
        // résultats précédents restent affichés (estompés) — pas d'écran plein.
        if (state.resultsStatus == SearchStatus.loading)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                minHeight: 3,
                color: AppColors.primary,
                backgroundColor: AppColors.primary.withValues(alpha: 0.18),
              ),
            ),
          ),
        if (showTriggers)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: SearchTriggerButtons(state: state),
          ),
        Expanded(child: _body(context, state, l10n)),
      ],
    );
  }

  Widget _body(BuildContext context, SearchState state, AppLocalizations l10n) {
    if (state.openMenu != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: SearchMenu(state: state),
      );
    }
    final loading = state.resultsStatus == SearchStatus.loading;
    if (state.results.isNotEmpty) {
      // Pendant une nouvelle requête, on garde la liste visible mais estompée
      // pour ne pas perdre le fil ; la barre de progression signale l'activité.
      return Opacity(
        opacity: loading ? 0.45 : 1,
        child: _Results(state: state, l10n: l10n),
      );
    }
    if (loading) return const SizedBox.shrink();
    if (!state.isIdle &&
        state.resultsStatus == SearchStatus.success &&
        state.results.isEmpty) {
      return const _EmptyResults();
    }
    return _IdleHint(l10n: l10n);
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 20, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
            ),
            splashRadius: 22,
          ),
          Text(
            AppLocalizations.of(context).navRecipes,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w700,
              fontSize: 26,
              letterSpacing: -0.5,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.state, required this.l10n});

  final SearchState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SearchCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.searchResultsCount(state.results.length),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: cubit.clearAll,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    const Icon(
                      Icons.tune_rounded,
                      size: 15,
                      color: SearchColors.sectionLabel,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.searchClearAll,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8A8574),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            itemCount: state.results.length,
            separatorBuilder: (_, _) => const SizedBox(height: 11),
            itemBuilder: (context, i) {
              final recipe = state.results[i];
              return SearchResultCard(
                recipe: recipe,
                onTap: () => Navigator.of(
                  context,
                ).push(RecipeDetailPage.route(recipe.id)),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 52,
              color: Color(0xFFC4BEAD),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.searchEmptyTitle,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w700,
                fontSize: 23,
                letterSpacing: -0.2,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdleHint extends StatelessWidget {
  const _IdleHint({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 0, 40, 80),
        child: Text(
          l10n.searchIdleHint,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            height: 1.55,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
