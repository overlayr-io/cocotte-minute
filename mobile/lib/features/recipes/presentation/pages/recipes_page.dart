import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_view.dart';
import '../../data/recipes_repository.dart';
import '../../domain/recipe.dart';
import '../bloc/recipes_list_bloc.dart';
import 'recipe_create_page.dart';
import 'recipe_detail_page.dart';

/// Onglet « Recettes » : liste des recettes du compte, création via l'action
/// trailing de l'AppBar (jamais de bouton central), ouverture de la fiche au tap.
class RecipesPage extends StatelessWidget {
  const RecipesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RecipesListBloc(repository: sl<RecipesRepository>())
        ..add(const RecipesRequested()),
      child: const _RecipesView(),
    );
  }
}

class _RecipesView extends StatelessWidget {
  const _RecipesView();

  Future<void> _create(BuildContext context) async {
    final bloc = context.read<RecipesListBloc>();
    final created = await Navigator.of(context).push(RecipeCreatePage.route());
    if (created == null) return;
    // Redirection automatique vers la fiche de la recette créée (cf. recipes.md).
    if (context.mounted) {
      await Navigator.of(context).push(RecipeDetailPage.route(created.id));
    }
    bloc.add(const RecipesRequested());
  }

  Future<void> _open(BuildContext context, String id) async {
    final bloc = context.read<RecipesListBloc>();
    await Navigator.of(context).push(RecipeDetailPage.route(id));
    bloc.add(const RecipesRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recipesTitle),
        actions: [
          BlocBuilder<RecipesListBloc, RecipesListState>(
            builder: (context, state) {
              if (state is! RecipesListLoaded) return const SizedBox.shrink();
              return IconButton(
                onPressed: () => _create(context),
                icon: const Icon(Icons.add_rounded),
                tooltip: l10n.recipeCreateTitle,
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: BlocBuilder<RecipesListBloc, RecipesListState>(
          builder: (context, state) {
            return switch (state) {
              RecipesListError(:final message) => ErrorView(
                  message: message,
                  onRetry: () =>
                      context.read<RecipesListBloc>().add(const RecipesRequested()),
                ),
              RecipesListLoaded(:final recipes) =>
                _content(context, recipes, l10n),
              _ => const Center(child: CircularProgressIndicator()),
            };
          },
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    List<RecipeSummary> recipes,
    AppLocalizations l10n,
  ) {
    if (recipes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            l10n.recipesEmpty,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 14, height: 1.5, color: AppColors.textMuted),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      itemCount: recipes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _RecipeCard(
        recipe: recipes[i],
        l10n: l10n,
        onTap: () => _open(context, recipes[i].id),
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.recipe, required this.l10n, required this.onTap});

  final RecipeSummary recipe;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              _Thumb(recipe: recipe),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            recipe.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: AppFonts.display,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (recipe.isBase) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryTint,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              l10n.recipeBaseBadge,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${l10n.recipeServingsShort(recipe.servings)} · ${l10n.recipePrepShort(recipe.prepTime)}',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: Color(0xFFCBC7BB)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.recipe});

  final RecipeSummary recipe;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: recipe.photoUrl == null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: recipe.isBase
                    ? const [Color(0xFF6B8E5A), Color(0xFF4F6B41)]
                    : const [Color(0xFFE9A08F), Color(0xFFC6533F)],
              )
            : null,
      ),
      child: recipe.photoUrl != null
          ? Image.network(recipe.photoUrl!, fit: BoxFit.cover)
          : const Icon(Icons.restaurant_rounded, color: Colors.white, size: 24),
    );
  }
}
