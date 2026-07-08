import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../recipes/presentation/pages/recipe_detail_page.dart';
import '../../../recipes/presentation/widgets/recipe_list_card.dart';
import '../../domain/category.dart';
import '../bloc/categories_list_bloc.dart';
import '../bloc/folder_recipes_cubit.dart';
import '../pages/category_folder_page.dart';
import 'category_form_sheet.dart';
import 'category_path.dart';

/// Vue partagée par l'écran racine (`parent == null`) et les pages de dossier
/// (`parent` = dossier ouvert). Affiche les sous-dossiers directs du parent,
/// un `+` en trailing pour créer un sous-dossier du dossier courant, et — hors
/// racine et hors dossier par défaut — un crayon pour éditer le dossier courant.
class CategoryFolderView extends StatelessWidget {
  const CategoryFolderView({super.key, this.parent});

  final Category? parent;

  Future<void> _create(
    BuildContext context,
    String? parentId,
    List<Category> all,
  ) async {
    final bloc = context.read<CategoriesListBloc>();
    final result = await showCategoryFormSheet(
      context,
      parentId: parentId,
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

  Future<void> _editCurrent(
    BuildContext context,
    Category current,
    List<Category> all,
  ) async {
    final bloc = context.read<CategoriesListBloc>();
    final result = await showCategoryFormSheet(
      context,
      initial: current,
      allCategories: all,
    );
    if (result is CategorySaved) {
      bloc.add(
        CategoryUpdated(id: current.id, name: result.name, icon: result.icon),
      );
    } else if (result is CategoryDeleteRequested) {
      if (!context.mounted) return;
      final confirmed = await _confirmDelete(context, current);
      if (confirmed) bloc.add(CategoryDeleted(current.id));
    }
  }

  Future<bool> _confirmDelete(BuildContext context, Category category) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.categoryDeleteConfirmTitle),
        content: Text(l10n.categoryDeleteConfirmBody(category.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<CategoriesListBloc, CategoriesListState>(
      listenWhen: (_, curr) =>
          curr is CategoriesListActionFailure || curr is CategoriesListLoaded,
      listener: (context, state) {
        if (state is CategoriesListActionFailure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message)));
          return;
        }
        // Le dossier courant vient d'être supprimé (plus dans l'arbre) : on
        // referme sa page pour revenir au parent.
        if (parent != null &&
            state is CategoriesListLoaded &&
            state.byId(parent!.id) == null) {
          Navigator.of(context).maybePop();
        }
      },
      builder: (context, state) {
        // Reflète en direct un éventuel renommage du dossier courant.
        Category? current = parent;
        if (parent != null && state is CategoriesListLoaded) {
          current = state.byId(parent!.id) ?? parent;
        }
        final isLoaded = state is CategoriesListLoaded;
        final all = isLoaded ? state.categories : const <Category>[];
        final canAdd = current == null || current.canHaveChildren;

        return Scaffold(
          appBar: AppBar(
            title: current == null
                ? Text(l10n.categoriesTitle)
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _TitleIcon(icon: current.icon),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          current.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
            actions: [
              if (isLoaded && current != null && !current.isDefault)
                IconButton(
                  onPressed: () => _editCurrent(context, current!, all),
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: l10n.categoryEditTitle,
                ),
              if (isLoaded && canAdd)
                IconButton(
                  onPressed: () => _create(context, current?.id, all),
                  icon: const Icon(Icons.add_rounded),
                  tooltip: l10n.categoryCreateTitle,
                ),
              const SizedBox(width: 4),
            ],
          ),
          body: switch (state) {
            CategoriesListError(:final message) => ErrorView(
              message: message,
              onRetry: () => context.read<CategoriesListBloc>().add(
                const CategoriesRequested(),
              ),
            ),
            CategoriesListLoaded() => _buildContent(
              context,
              state,
              current,
              l10n,
            ),
            _ => const Center(child: CircularProgressIndicator()),
          },
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    CategoriesListLoaded state,
    Category? current,
    AppLocalizations l10n,
  ) {
    final children = state.childrenOf(current?.id);
    final isRoot = current == null;

    // Slivers builder : dossiers et cartes recette (avec images) ne sont
    // construits que lorsqu'ils deviennent visibles au scroll.
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
          sliver: SliverList.list(
            children: [
              if (isRoot)
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 2, 2, 16),
                  child: Text(
                    l10n.categoriesIntro,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.5,
                      color: Color(0xFF8A8574),
                    ),
                  ),
                )
              else ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 2, 2, 8),
                  child: Text(
                    categoryPath(current, state.categories),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFA79F8B),
                    ),
                  ),
                ),
                if (current.isDefault)
                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 8),
                    child: _DefaultBadge(label: l10n.categoryDefaultBadge),
                  ),
                _SectionLabel(l10n.categoriesSubfoldersLabel),
                const SizedBox(height: 8),
              ],
              if (children.isEmpty)
                _EmptyFolders(
                  message: isRoot
                      ? l10n.categoriesEmpty
                      : l10n.categoriesEmptyFolder,
                ),
            ],
          ),
        ),
        if (children.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.builder(
              itemCount: children.length,
              itemBuilder: (context, index) {
                final child = children[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _CategoryRow(
                    category: child,
                    l10n: l10n,
                    onTap: () => Navigator.of(context).push(
                      CategoryFolderPage.route(
                        bloc: context.read<CategoriesListBloc>(),
                        category: child,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        if (!isRoot) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            sliver: SliverList.list(
              children: [
                _SectionLabel(l10n.categoriesRecipesLabel),
                const SizedBox(height: 8),
              ],
            ),
          ),
          _FolderRecipes(categoryId: current.id, l10n: l10n),
        ] else
          const SliverPadding(padding: EdgeInsets.only(bottom: 28)),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.l10n,
    required this.onTap,
  });

  final Category category;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                _Tile(icon: category.icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (category.isDefault) ...[
                  _DefaultBadge(label: l10n.categoryDefaultBadge),
                  const SizedBox(width: 10),
                ],
                if (category.recipeCount > 0) ...[
                  Text(
                    l10n.categoriesRecipeCount(category.recipeCount),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFA79F8B),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
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

class _Tile extends StatelessWidget {
  const _Tile({this.icon});

  final String? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(10),
      ),
      child: icon != null
          ? Text(icon!, style: const TextStyle(fontSize: 18))
          : const Icon(
              Icons.folder_outlined,
              size: 18,
              color: AppColors.primary,
            ),
    );
  }
}

class _TitleIcon extends StatelessWidget {
  const _TitleIcon({this.icon});

  final String? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(9),
      ),
      child: icon != null
          ? Text(icon!, style: const TextStyle(fontSize: 16))
          : const Icon(
              Icons.folder_outlined,
              size: 16,
              color: AppColors.primary,
            ),
    );
  }
}

class _DefaultBadge extends StatelessWidget {
  const _DefaultBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EAD6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFF8A7A4E),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: Color(0xFFA79F8B),
      ),
    );
  }
}

class _EmptyFolders extends StatelessWidget {
  const _EmptyFolders({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 13.5,
          height: 1.45,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

/// Recettes rangées dans le dossier courant (cubit [FolderRecipesCubit] fourni
/// par [CategoryFolderPage]). Chargement/erreur non bloquants : la navigation
/// dans les sous-dossiers reste possible même si ce bloc échoue.
class _FolderRecipes extends StatelessWidget {
  const _FolderRecipes({required this.categoryId, required this.l10n});

  final String categoryId;
  final AppLocalizations l10n;

  Future<void> _open(BuildContext context, String id) async {
    final cubit = context.read<FolderRecipesCubit>();
    await Navigator.of(context).push(RecipeDetailPage.route(id));
    // Une suppression/édition sur la fiche peut changer le contenu du dossier.
    await cubit.load(categoryId);
  }

  // Rend un SLIVER (la vue parente est un CustomScrollView) : les cartes
  // recette ne sont construites que lorsqu'elles deviennent visibles.
  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      sliver: BlocBuilder<FolderRecipesCubit, FolderRecipesState>(
        builder: (context, state) {
          return switch (state) {
            FolderRecipesError(:final message) => SliverToBoxAdapter(
              child: _RecipesNotice(
                message: message,
                actionLabel: l10n.commonRetry,
                onAction: () =>
                    context.read<FolderRecipesCubit>().load(categoryId),
              ),
            ),
            FolderRecipesLoaded(:final recipes) =>
              recipes.isEmpty
                  ? SliverToBoxAdapter(
                      child: _RecipesNotice(
                        message: l10n.categoriesRecipesEmpty,
                      ),
                    )
                  : SliverList.builder(
                      itemCount: recipes.length,
                      itemBuilder: (context, index) {
                        final r = recipes[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 9),
                          child: RecipeListCard(
                            recipe: r,
                            onTap: () => _open(context, r.id),
                          ),
                        );
                      },
                    ),
            _ => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          };
        },
      ),
    );
  }
}

/// Encart discret (dossier vide ou erreur de chargement non bloquante), avec
/// une action optionnelle de réessai.
class _RecipesNotice extends StatelessWidget {
  const _RecipesNotice({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFD8D2C4)),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 6),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
