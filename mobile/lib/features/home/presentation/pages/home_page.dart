import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../categories/data/categories_repository.dart';
import '../../../categories/domain/category.dart';
import '../../../recipes/data/recipes_repository.dart';
import '../../../recipes/domain/recipe.dart';
import '../../../recipes/presentation/pages/recipe_create_page.dart';
import '../../../recipes/presentation/pages/recipe_detail_page.dart';
import '../../../search/presentation/pages/search_page.dart';
import '../bloc/home_cubit.dart';

/// Couleurs du bandeau crème de l'en-tête (maquette 1b/2a).
const Color _kCreamTop = Color(0xFFEAE1C8);
const Color _kCreamBottom = Color(0xFFEFE8D4);

/// Onglet « Accueil » : salutation, recherche + chips catégories (qui se collent
/// en haut au scroll), suggestion du jour et carrousel « Mises en avant ».
/// Composé à partir des recettes et catégories du compte — aucun endpoint dédié.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeCubit(
        recipesRepository: sl<RecipesRepository>(),
        categoriesRepository: sl<CategoriesRepository>(),
      )..load(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  Future<void> _create(BuildContext context) async {
    final cubit = context.read<HomeCubit>();
    final created = await Navigator.of(context).push(RecipeCreatePage.route());
    if (created != null && context.mounted) {
      await Navigator.of(context).push(RecipeDetailPage.route(created.id));
    }
    await cubit.load();
  }

  Future<void> _openRecipe(BuildContext context, String id) async {
    final cubit = context.read<HomeCubit>();
    await Navigator.of(context).push(RecipeDetailPage.route(id));
    await cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: _kCreamTop,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: BlocBuilder<HomeCubit, HomeState>(
              builder: (context, state) {
                return switch (state) {
                  HomeError(:final message) => Container(
                      color: AppColors.surface,
                      child: ErrorView(
                        message: message,
                        onRetry: () => context.read<HomeCubit>().load(),
                      ),
                    ),
                  HomeLoaded() => _content(context, state, l10n),
                  _ => const Center(child: CircularProgressIndicator()),
                };
              },
            ),
          ),
          // FAB flottant à droite (au-dessus de la barre de navigation du shell).
          Positioned(
            right: 20,
            bottom: 96,
            child: _Fab(onTap: () => _create(context)),
          ),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, HomeLoaded state, AppLocalizations l10n) {
    return CustomScrollView(
      slivers: [
        // Salutation : défile et laisse place au header collant.
        SliverToBoxAdapter(
          child: ColoredBox(
            color: _kCreamTop,
            child: _Greeting(l10n: l10n),
          ),
        ),
        // Recherche + chips catégories : se collent en haut (fond crème inclus).
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickyHeader(
            extent: 186,
            child: _SearchAndChips(
              categories: state.categories,
              l10n: l10n,
              onSearchTap: () =>
                  Navigator.of(context).push(SearchPage.route()),
              onCategoryTap: (category) => Navigator.of(context)
                  .push(SearchPage.route(initialFolder: category)),
            ),
          ),
        ),
        // Corps sur fond clair.
        SliverToBoxAdapter(
          child: Container(
            color: AppColors.surface,
            padding: const EdgeInsets.only(bottom: 150),
            child: state.isEmpty
                ? _EmptyBody(l10n: l10n, onCreate: () => _create(context))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (state.suggestion != null)
                        _SuggestionSection(
                          recipe: state.suggestion!,
                          l10n: l10n,
                          onTap: () =>
                              _openRecipe(context, state.suggestion!.id),
                        ),
                      if (state.featured.length > 1)
                        _FeaturedSection(
                          recipes: state.featured,
                          l10n: l10n,
                          onTapRecipe: (id) => _openRecipe(context, id),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

// --- en-tête -----------------------------------------------------------------

class _Greeting extends StatelessWidget {
  const _Greeting({required this.l10n});

  final AppLocalizations l10n;

  static const _days = [
    'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche',
  ];
  static const _months = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août',
    'septembre', 'octobre', 'novembre', 'décembre',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final date = '${_days[now.weekday - 1]} ${now.day} ${_months[now.month - 1]}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            date,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8A7A4E),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.homeGreetingQuestion,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w700,
              fontSize: 25,
              height: 1.12,
              letterSpacing: -0.5,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchAndChips extends StatelessWidget {
  const _SearchAndChips({
    required this.categories,
    required this.l10n,
    required this.onSearchTap,
    required this.onCategoryTap,
  });

  final List<Category> categories;
  final AppLocalizations l10n;
  final VoidCallback onSearchTap;

  /// Ouvre la recherche, éventuellement pré-filtrée sur un dossier (null = « Tout »).
  final ValueChanged<Category?> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_kCreamTop, _kCreamBottom],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      padding: const EdgeInsets.only(top: 14, bottom: 14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _SearchBar(hint: l10n.homeSearchHint, onTap: onSearchTap),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 84,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _CategoryChip(
                  label: l10n.homeCategoryAll,
                  emoji: '🍽️',
                  active: true,
                  onTap: () => onCategoryTap(null),
                ),
                for (final c in categories) ...[
                  const SizedBox(width: 16),
                  _CategoryChip(
                    label: c.name,
                    emoji: c.icon,
                    active: false,
                    onTap: () => onCategoryTap(c),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.hint, required this.onTap});

  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 52,
          padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.10),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hint,
                  style: const TextStyle(fontSize: 16, color: AppColors.textMuted),
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.pill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.filter_list_rounded,
                    color: AppColors.primary, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.emoji,
    required this.active,
    required this.onTap,
  });

  final String label;
  final String? emoji;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? AppColors.primary : Colors.white,
              border: active ? null : Border.all(color: AppColors.border),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.45),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: emoji != null
                ? Text(emoji!, style: const TextStyle(fontSize: 23))
                : Icon(Icons.restaurant_menu_rounded,
                    color: active ? Colors.white : AppColors.primary, size: 22),
          ),
          const SizedBox(height: 7),
          SizedBox(
            width: 62,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                color: active ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Header collant à extent fixe (recherche + chips ne se replient pas ; seule la
/// salutation, sliver précédent, défile au-dessus).
class _StickyHeader extends SliverPersistentHeaderDelegate {
  _StickyHeader({required this.child, required this.extent});

  final Widget child;
  final double extent;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_StickyHeader oldDelegate) =>
      oldDelegate.child != child || oldDelegate.extent != extent;
}

// --- suggestion --------------------------------------------------------------

class _SuggestionSection extends StatelessWidget {
  const _SuggestionSection({
    required this.recipe,
    required this.l10n,
    required this.onTap,
  });

  final RecipeSummary recipe;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: l10n.homeSuggestionTitle),
          const SizedBox(height: 13),
          _RecipePoster(
            recipe: recipe,
            l10n: l10n,
            height: 220,
            badge: l10n.homeSuggestionBadge,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

// --- carrousel ---------------------------------------------------------------

class _FeaturedSection extends StatefulWidget {
  const _FeaturedSection({
    required this.recipes,
    required this.l10n,
    required this.onTapRecipe,
  });

  final List<RecipeSummary> recipes;
  final AppLocalizations l10n;
  final ValueChanged<String> onTapRecipe;

  @override
  State<_FeaturedSection> createState() => _FeaturedSectionState();
}

class _FeaturedSectionState extends State<_FeaturedSection> {
  late final PageController _controller;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.86);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipes = widget.recipes;
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SectionTitle(title: widget.l10n.homeFeaturedTitle),
                Row(
                  children: [
                    Text(
                      widget.l10n.homeFeaturedHint,
                      style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        size: 18, color: AppColors.textMuted),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          SizedBox(
            height: 220,
            // Inset gauche 20px ; les cartes « peek » à droite (viewportFraction).
            child: Padding(
              padding: const EdgeInsets.only(left: 20),
              child: PageView.builder(
                controller: _controller,
                padEnds: false,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: recipes.length,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: _RecipePoster(
                    recipe: recipes[i],
                    l10n: widget.l10n,
                    height: 220,
                    onTap: () => widget.onTapRecipe(recipes[i].id),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _Dots(count: recipes.length, active: _page),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    // Borne l'affichage à 6 points pour ne pas déborder sur beaucoup de recettes.
    final shown = count > 6 ? 6 : count;
    final activeDot = active >= shown ? shown - 1 : active;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < shown; i++)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == activeDot ? 22 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == activeDot ? AppColors.primary : const Color(0xFFD6D2C7),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
      ],
    );
  }
}

/// Carte poster d'une recette (suggestion + slides du carrousel) : photo ou
/// dégradé de repli, dégradé sombre, badge optionnel, titre + temps/personnes.
class _RecipePoster extends StatelessWidget {
  const _RecipePoster({
    required this.recipe,
    required this.l10n,
    required this.height,
    required this.onTap,
    this.badge,
  });

  final RecipeSummary recipe;
  final AppLocalizations l10n;
  final double height;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (recipe.photoUrl != null)
                Image.network(recipe.photoUrl!, fit: BoxFit.cover)
              else
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: recipe.isBase
                          ? const [Color(0xFF7D9C6A), Color(0xFF5E7F4F)]
                          : const [Color(0xFFC6957F), Color(0xFF9C5A44)],
                    ),
                  ),
                ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0xC71F2933)],
                    stops: [0.36, 1],
                  ),
                ),
              ),
              if (badge != null)
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w700,
                        fontSize: 21,
                        letterSpacing: -0.01,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${l10n.recipeServingsShort(recipe.servings)}  ·  ${l10n.recipePrepShort(recipe.prepTime)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- divers ------------------------------------------------------------------

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: AppFonts.display,
        fontWeight: FontWeight.w700,
        fontSize: 19,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody({required this.l10n, required this.onCreate});

  final AppLocalizations l10n;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
      child: Column(
        children: [
          const Icon(Icons.restaurant_menu_rounded, size: 46, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            l10n.homeEmptyTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.homeEmptyBody,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.recipeCreateAction),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Fab extends StatelessWidget {
  const _Fab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accent,
      shape: const CircleBorder(),
      elevation: 6,
      shadowColor: AppColors.accent.withValues(alpha: 0.6),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 60,
          height: 60,
          child: Icon(Icons.add_rounded, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}
