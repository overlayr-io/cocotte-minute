import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_view.dart';
import '../../data/recipes_repository.dart';
import '../bloc/uncategorized_recipes_cubit.dart';
import '../widgets/recipe_list_card.dart';
import 'recipe_detail_page.dart';

/// Dossier virtuel « Autres » : recettes rangées dans aucun dossier.
class UncategorizedFolderPage extends StatelessWidget {
  const UncategorizedFolderPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => const UncategorizedFolderPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          UncategorizedRecipesCubit(repository: sl<RecipesRepository>())
            ..load(),
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const _View();

  Future<void> _openRecipe(BuildContext context, String id) async {
    final cubit = context.read<UncategorizedRecipesCubit>();
    await Navigator.of(context).push(RecipeDetailPage.route(id));
    // La recette a pu être rangée dans un dossier entre-temps.
    await cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.recipesOtherFolderTitle)),
      body: BlocBuilder<UncategorizedRecipesCubit, UncategorizedRecipesState>(
        builder: (context, state) {
          return switch (state) {
            UncategorizedRecipesError(:final message) => ErrorView(
              message: message,
              onRetry: () => context.read<UncategorizedRecipesCubit>().load(),
            ),
            UncategorizedRecipesLoaded(:final recipes) =>
              recipes.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          l10n.recipesOtherFolderEmpty,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                      itemCount: recipes.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 11),
                      itemBuilder: (context, i) => RecipeListCard(
                        recipe: recipes[i],
                        onTap: () => _openRecipe(context, recipes[i].id),
                      ),
                    ),
            _ => const Center(child: CircularProgressIndicator()),
          };
        },
      ),
    );
  }
}
