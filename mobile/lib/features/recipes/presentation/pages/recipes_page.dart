import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../categories/data/categories_repository.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/bloc/categories_list_bloc.dart';
import '../../../categories/presentation/pages/category_folder_page.dart';
import '../../../categories/presentation/widgets/category_form_sheet.dart';
import '../../../search/presentation/pages/search_page.dart';
import '../../data/recipes_repository.dart';
import '../bloc/all_recipes_cubit.dart';
import '../bloc/uncategorized_recipes_cubit.dart';
import '../widgets/recipe_list_card.dart';
import 'recipe_create_page.dart';
import 'recipe_detail_page.dart';
import 'uncategorized_folder_page.dart';

/// Onglet « Recettes » (maquette 7b — vue Dossiers) : titre, recherche, cartes
/// de dossiers (racines) et bouton « Nouveau dossier ». Toucher un dossier
/// l'ouvre pour voir ses recettes ; le FAB corail crée une recette. La vue est
/// alimentée par le bloc Catégories (dossiers = catégories rangeant les
/// recettes) ; la barre de recherche ouvre l'écran de recherche avancée.
class RecipesPage extends StatelessWidget {
  const RecipesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              CategoriesListBloc(repository: sl<CategoriesRepository>())
                ..add(const CategoriesRequested()),
        ),
        BlocProvider(
          create: (_) =>
              UncategorizedRecipesCubit(repository: sl<RecipesRepository>())
                ..load(),
        ),
        // Lazy : créé (et chargé) au premier passage en vue Liste.
        BlocProvider(
          create: (_) =>
              AllRecipesCubit(repository: sl<RecipesRepository>())..load(),
        ),
      ],
      child: const _RecipesView(),
    );
  }
}

class _RecipesView extends StatefulWidget {
  const _RecipesView();

  @override
  State<_RecipesView> createState() => _RecipesViewState();
}

class _RecipesViewState extends State<_RecipesView> {
  /// false = vue Dossiers (par défaut), true = vue Liste paginée.
  bool _listMode = false;

  Future<void> _create(BuildContext context) async {
    final bloc = context.read<CategoriesListBloc>();
    final uncategorized = context.read<UncategorizedRecipesCubit>();
    final created = await Navigator.of(context).push(RecipeCreatePage.route());
    if (created == null) return;
    // Redirection automatique vers la fiche de la recette créée (cf. recipes.md).
    if (context.mounted) {
      await Navigator.of(context).push(RecipeDetailPage.route(created.id));
    }
    // Rafraîchit les compteurs de recettes des dossiers au retour, ainsi que le
    // dossier virtuel « Autres » (une recette neuve n'est rangée nulle part).
    bloc.add(const CategoriesRequested(forceRefresh: true));
    await uncategorized.load();
  }

  Future<void> _openOtherFolder(BuildContext context) async {
    final cubit = context.read<UncategorizedRecipesCubit>();
    await Navigator.of(context).push(UncategorizedFolderPage.route());
    // Des recettes ont pu être rangées/créées : rafraîchit le compteur.
    await cubit.load();
  }

  void _openFolder(BuildContext context, Category category) {
    Navigator.of(context).push(
      CategoryFolderPage.route(
        bloc: context.read<CategoriesListBloc>(),
        category: category,
      ),
    );
  }

  Future<void> _newFolder(BuildContext context, List<Category> all) async {
    final bloc = context.read<CategoriesListBloc>();
    final result = await showCategoryFormSheet(
      context,
      parentId: null,
      allCategories: all,
    );
    if (result is CategorySaved) {
      bloc.add(
        CategoryCreated(
          name: result.name,
          icon: result.icon,
          parentCategoryId: result.parentCategoryId,
        ),
      );
    }
  }

  void _comingSoon(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: BlocConsumer<CategoriesListBloc, CategoriesListState>(
              listenWhen: (_, curr) => curr is CategoriesListActionFailure,
              listener: (context, state) {
                if (state is CategoriesListActionFailure) {
                  _comingSoon(context, state.message);
                }
              },
              builder: (context, state) {
                if (_listMode) {
                  return _AllRecipesList(
                    l10n: l10n,
                    header: _titleRow(l10n),
                    onOpenRecipe: (id) => _openRecipeFromList(context, id),
                  );
                }
                return switch (state) {
                  CategoriesListError(:final message) => ErrorView(
                    message: message,
                    onRetry: () => context.read<CategoriesListBloc>().add(
                      const CategoriesRequested(),
                    ),
                  ),
                  CategoriesListLoaded() => _content(context, state, l10n),
                  _ => const Center(child: CircularProgressIndicator()),
                };
              },
            ),
          ),
          // FAB corail (créer une recette), au-dessus de la barre du shell —
          // même calage que l'Accueil.
          Positioned(
            right: 20,
            bottom: 96,
            child: _Fab(onTap: () => _create(context)),
          ),
        ],
      ),
    );
  }

  /// Titre de la page + toggle vue Dossiers / vue Liste en trailing.
  Widget _titleRow(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.recipesTitle,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w700,
                fontSize: 27,
                letterSpacing: -0.5,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _listMode = !_listMode),
            icon: Icon(
              _listMode ? Icons.folder_rounded : Icons.view_list_rounded,
              size: 24,
            ),
            color: AppColors.textPrimary,
            tooltip:
                _listMode ? l10n.recipesViewFolders : l10n.recipesViewList,
          ),
        ],
      ),
    );
  }

  Future<void> _openRecipeFromList(BuildContext context, String id) async {
    final cubit = context.read<AllRecipesCubit>();
    await Navigator.of(context).push(RecipeDetailPage.route(id));
    await cubit.load();
  }

  Widget _content(
    BuildContext context,
    CategoriesListLoaded state,
    AppLocalizations l10n,
  ) {
    final folders = state.childrenOf(null);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 150),
      children: [
        _titleRow(l10n),
        _SearchBar(
          hint: l10n.recipesSearchHint,
          onTap: () => Navigator.of(context).push(SearchPage.route()),
        ),
        const SizedBox(height: 18),
        if (folders.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              l10n.categoriesEmpty,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: AppColors.textMuted,
              ),
            ),
          )
        else
          for (final folder in folders)
            Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: _FolderCard(
                category: folder,
                subfolderCount: state.childrenOf(folder.id).length,
                l10n: l10n,
                onTap: () => _openFolder(context, folder),
              ),
            ),
        // Dossier virtuel « Autres » : recettes rangées nulle part (sinon
        // invisibles dans la vue Dossiers).
        BlocBuilder<UncategorizedRecipesCubit, UncategorizedRecipesState>(
          builder: (context, uncategorized) {
            if (uncategorized is! UncategorizedRecipesLoaded ||
                uncategorized.recipes.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: _OtherFolderCard(
                title: l10n.recipesOtherFolderTitle,
                subtitle: l10n.categoriesRecipeCount(
                  uncategorized.recipes.length,
                ),
                onTap: () => _openOtherFolder(context),
              ),
            );
          },
        ),
        const SizedBox(height: 3),
        _NewFolderButton(
          label: l10n.categoryCreateTitle,
          onTap: () => _newFolder(context, state.categories),
        ),
      ],
    );
  }
}

/// Carte d'un dossier racine (maquette 7b) : pastille emoji, nom, sous-titre
/// « N recettes · M sous-dossiers », chevron.
class _FolderCard extends StatelessWidget {
  const _FolderCard({
    required this.category,
    required this.subfolderCount,
    required this.l10n,
    required this.onTap,
  });

  final Category category;
  final int subfolderCount;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  String _subtitle() {
    final recipes = l10n.categoriesRecipeCount(category.recipeCount);
    if (subfolderCount == 0) return recipes;
    return '$recipes · ${l10n.categoriesSubfolderCount(subfolderCount)}';
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _FolderTile(icon: category.icon),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppFonts.display,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _subtitle(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Color(0xFFCBC7BB),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Vue Liste : toutes les recettes, paginées automatiquement au scroll, avec
/// une barre de filtre texte simple (débouncée) — distincte de la recherche
/// avancée de l'Accueil.
class _AllRecipesList extends StatefulWidget {
  const _AllRecipesList({
    required this.l10n,
    required this.header,
    required this.onOpenRecipe,
  });

  final AppLocalizations l10n;
  final Widget header;
  final ValueChanged<String> onOpenRecipe;

  @override
  State<_AllRecipesList> createState() => _AllRecipesListState();
}

class _AllRecipesListState extends State<_AllRecipesList> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.read<AllRecipesCubit>().state.query,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.metrics.extentAfter < 400) {
      context.read<AllRecipesCubit>().loadMore();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return BlocBuilder<AllRecipesCubit, AllRecipesState>(
      builder: (context, state) {
        return NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 150),
            children: [
              widget.header,
              _FilterField(
                controller: _controller,
                hint: l10n.recipesListFilterHint,
                onChanged: (q) => context.read<AllRecipesCubit>().load(query: q),
              ),
              const SizedBox(height: 18),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 30),
                  child: ErrorView(
                    message: state.error!,
                    onRetry: () => context.read<AllRecipesCubit>().load(),
                  ),
                )
              else if (state.loading && state.recipes.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.recipes.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Text(
                    l10n.recipesListEmpty,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.45,
                      color: AppColors.textMuted,
                    ),
                  ),
                )
              else ...[
                for (final recipe in state.recipes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 11),
                    child: RecipeListCard(
                      recipe: recipe,
                      onTap: () => widget.onOpenRecipe(recipe.id),
                    ),
                  ),
                if (state.loadingMore)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Champ de filtre de la vue Liste (débounce 350 ms).
class _FilterField extends StatefulWidget {
  const _FilterField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  State<_FilterField> createState() => _FilterFieldState();
}

class _FilterFieldState extends State<_FilterField> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) widget.onChanged(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      onChanged: _onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: const TextStyle(fontSize: 15, color: Color(0xFFB0AA9A)),
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 19,
          color: AppColors.textMuted,
        ),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: Color(0xFFE4DFD4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

/// Carte du dossier virtuel « Autres » — même gabarit que [_FolderCard], avec
/// une pastille neutre (pas d'emoji, pas de sous-dossiers).
class _OtherFolderCard extends StatelessWidget {
  const _OtherFolderCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.pill,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.folder_open_rounded,
                    size: 24,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppFonts.display,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Color(0xFFCBC7BB),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FolderTile extends StatelessWidget {
  const _FolderTile({this.icon});

  final String? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(15),
      ),
      child: icon != null
          ? Text(icon!, style: const TextStyle(fontSize: 26))
          : const Icon(
              Icons.folder_rounded,
              size: 24,
              color: AppColors.primary,
            ),
    );
  }
}

class _NewFolderButton extends StatelessWidget {
  const _NewFolderButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFC4BEAD), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Barre de recherche (ouvre l'écran de recherche avancée) — même style que
/// l'Accueil : champ blanc, icône loupe, pastille filtre.
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
              const Icon(
                Icons.search_rounded,
                color: AppColors.textMuted,
                size: 19,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  hint,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFFB0AA9A),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.tune_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
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
