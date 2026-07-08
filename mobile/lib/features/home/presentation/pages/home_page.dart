import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../categories/data/categories_repository.dart';
import '../../../categories/domain/category.dart';
import '../../../recipes/domain/recipe.dart';
import '../../../recipes/presentation/pages/recipe_create_page.dart';
import '../../../recipes/presentation/pages/recipe_detail_page.dart';
import '../../../search/presentation/pages/search_page.dart';
import '../../data/discovery_repository.dart';
import '../bloc/home_cubit.dart';

/// Couleurs du bandeau crème de l'en-tête (maquette 1b/2a).
const Color _kCreamTop = Color(0xFFEAE1C8);
const Color _kCreamBottom = Color(0xFFEFE8D4);

/// Onglet « Accueil » = flux Découverte : salutation, recherche + chips dossiers
/// (collants au scroll), hero « à la une » puis rangées éditoriales (de saison,
/// prêt en 30 min, récentes, par personne, recettes de base, portions).
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeCubit(
        discoveryRepository: sl<DiscoveryRepository>(),
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
        SliverToBoxAdapter(
          child: ColoredBox(
            color: _kCreamTop,
            child: _Greeting(l10n: l10n),
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickyHeader(
            extent: 186,
            child: _SearchAndChips(
              categories: state.categories,
              l10n: l10n,
              onSearchTap: () => Navigator.of(context).push(SearchPage.route()),
              onCategoryTap: (category) => Navigator.of(context)
                  .push(SearchPage.route(initialFolder: category)),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Container(
            color: AppColors.surface,
            padding: const EdgeInsets.only(bottom: 150),
            child: state.isEmpty
                ? _EmptyBody(l10n: l10n, onCreate: () => _create(context))
                : _DiscoveryBody(
                    state: state,
                    l10n: l10n,
                    onOpenRecipe: (id) => _openRecipe(context, id),
                    onSeeAll: () =>
                        Navigator.of(context).push(SearchPage.route()),
                  ),
          ),
        ),
      ],
    );
  }
}

// --- corps Découverte --------------------------------------------------------

class _DiscoveryBody extends StatelessWidget {
  const _DiscoveryBody({
    required this.state,
    required this.l10n,
    required this.onOpenRecipe,
    required this.onSeeAll,
  });

  final HomeLoaded state;
  final AppLocalizations l10n;
  final ValueChanged<String> onOpenRecipe;
  final VoidCallback onSeeAll;

  static const _monthsFr = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août',
    'septembre', 'octobre', 'novembre', 'décembre',
  ];
  static const _monthsEn = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August',
    'September', 'October', 'November', 'December',
  ];

  String _monthName(BuildContext context) {
    final index = (state.month - 1).clamp(0, 11);
    final isFrench = Localizations.localeOf(context).languageCode == 'fr';
    return (isFrench ? _monthsFr : _monthsEn)[index];
  }

  String _title(DiscoverySection s, String monthName) {
    return switch (s.kind) {
      DiscoverySectionKind.seasonal => l10n.homeRowSeasonalIn(monthName),
      DiscoverySectionKind.quick => l10n.homeRowQuick,
      DiscoverySectionKind.recent => l10n.homeRowRecent,
      DiscoverySectionKind.person => l10n.homeRowPerson(s.personName ?? ''),
      DiscoverySectionKind.base => l10n.homeRowBase,
      DiscoverySectionKind.large => l10n.homeRowLarge,
      DiscoverySectionKind.solo => l10n.homeRowSolo,
    };
  }

  @override
  Widget build(BuildContext context) {
    final hero = state.hero!;
    final monthName = _monthName(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
          child: _RecipePoster(
            recipe: hero,
            l10n: l10n,
            height: 210,
            accentBadge: l10n.homeHeroBadge,
            lightBadge: state.heroSeasonal ? l10n.homeSeasonBadge : null,
            onTap: () => onOpenRecipe(hero.id),
          ),
        ),
        for (final section in state.sections)
          _DiscoveryRow(
            title: _title(section, monthName),
            avatarUrl:
                section.kind == DiscoverySectionKind.person ? section.avatarUrl : null,
            initial: section.kind == DiscoverySectionKind.person
                ? (section.personName ?? '?')
                : null,
            recipes: section.recipes,
            l10n: l10n,
            seeAllLabel: l10n.homeSeeAll,
            onSeeAll: onSeeAll,
            onTapRecipe: onOpenRecipe,
          ),
      ],
    );
  }
}

class _DiscoveryRow extends StatelessWidget {
  const _DiscoveryRow({
    required this.title,
    required this.recipes,
    required this.l10n,
    required this.seeAllLabel,
    required this.onSeeAll,
    required this.onTapRecipe,
    this.avatarUrl,
    this.initial,
  });

  final String title;
  final List<RecipeSummary> recipes;
  final AppLocalizations l10n;
  final String seeAllLabel;
  final VoidCallback onSeeAll;
  final ValueChanged<String> onTapRecipe;
  final String? avatarUrl;
  final String? initial;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                if (avatarUrl != null || initial != null) ...[
                  _RowAvatar(url: avatarUrl, initial: initial ?? '?'),
                  const SizedBox(width: 9),
                ],
                Expanded(child: _SectionTitle(title: title)),
                GestureDetector(
                  onTap: onSeeAll,
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    seeAllLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          SizedBox(
            height: 156,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: recipes.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, i) => _LandscapeCard(
                recipe: recipes[i],
                l10n: l10n,
                onTap: () => onTapRecipe(recipes[i].id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RowAvatar extends StatelessWidget {
  const _RowAvatar({required this.url, required this.initial});

  final String? url;
  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8FAE7C), AppColors.primary],
        ),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: url != null
          ? AppNetworkImage(url!, decodeWidth: 52)
          : Text(
              initial.isNotEmpty ? initial.substring(0, 1).toUpperCase() : '?',
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: Colors.white,
              ),
            ),
    );
  }
}

/// Carte paysage d'une rangée Découverte (216×156, style Netflix).
class _LandscapeCard extends StatelessWidget {
  const _LandscapeCard({
    required this.recipe,
    required this.l10n,
    required this.onTap,
  });

  final RecipeSummary recipe;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 216,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (recipe.photoUrl != null)
                AppNetworkImage(recipe.photoUrl!, decodeWidth: 216)
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
                    stops: [0.38, 1],
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 12,
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
                        fontSize: 17,
                        letterSpacing: -0.01,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.recipeServingsShort(recipe.servings)}  ·  ${l10n.recipePrepShort(recipe.prepTime)}',
                      style: const TextStyle(
                        fontSize: 12,
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
      borderRadius: BorderRadius.circular(17),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          height: 52,
          padding: const EdgeInsets.fromLTRB(13, 0, 9, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: const Color(0xFFE4DFD4)),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.09),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 19),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  hint,
                  style: const TextStyle(fontSize: 15, color: Color(0xFFB0AA9A)),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
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

/// Carte poster (hero « à la une ») : photo ou dégradé de repli, dégradé sombre,
/// badge accent + badge clair optionnels, titre + temps/personnes.
class _RecipePoster extends StatelessWidget {
  const _RecipePoster({
    required this.recipe,
    required this.l10n,
    required this.height,
    required this.onTap,
    this.accentBadge,
    this.lightBadge,
  });

  final RecipeSummary recipe;
  final AppLocalizations l10n;
  final double height;
  final String? accentBadge;
  final String? lightBadge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (recipe.photoUrl != null)
                AppNetworkImage(recipe.photoUrl!, decodeWidth: 720)
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
                    colors: [Color(0x00000000), Color(0xD11F2933)],
                    stops: [0.30, 1],
                  ),
                ),
              ),
              if (accentBadge != null)
                Positioned(
                  top: 14,
                  left: 14,
                  child: Row(
                    children: [
                      _Badge(text: accentBadge!, color: AppColors.accent, textColor: Colors.white),
                      if (lightBadge != null) ...[
                        const SizedBox(width: 7),
                        _Badge(
                          text: lightBadge!,
                          color: Colors.white.withValues(alpha: 0.92),
                          textColor: AppColors.textPrimary,
                        ),
                      ],
                    ],
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        letterSpacing: -0.4,
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

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color, required this.textColor});

  final String text;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textColor),
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
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
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
