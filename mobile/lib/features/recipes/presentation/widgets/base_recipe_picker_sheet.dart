import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/recipes_repository.dart';
import '../../domain/recipe.dart';

/// Sélecteur de recette de base à référencer dans une étape. Renvoie la recette
/// choisie (ses étapes seront insérées par référence), ou `null` si annulé.
Future<RecipeSummary?> showBaseRecipePicker(
  BuildContext context, {
  required String excludeRecipeId,
}) {
  return showModalBottomSheet<RecipeSummary>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BaseRecipePickerSheet(excludeRecipeId: excludeRecipeId),
  );
}

class _BaseRecipePickerSheet extends StatefulWidget {
  const _BaseRecipePickerSheet({required this.excludeRecipeId});

  final String excludeRecipeId;

  @override
  State<_BaseRecipePickerSheet> createState() => _BaseRecipePickerSheetState();
}

class _BaseRecipePickerSheetState extends State<_BaseRecipePickerSheet> {
  late final Future<List<RecipeSummary>> _future = _load();

  Future<List<RecipeSummary>> _load() async {
    final all = await sl<RecipesRepository>().fetchMine();
    return all
        .where((r) => r.isBase && r.id != widget.excludeRecipeId)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8D3C6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.recipeStepBasePickerTitle,
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  letterSpacing: -0.3,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                l10n.recipeStepBasePickerSubtitle,
                style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<List<RecipeSummary>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final items = snapshot.data!;
                    if (items.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            l10n.recipeStepBasePickerEmpty,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: AppColors.textSecondary, height: 1.4),
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _BaseRecipeTile(
                        recipe: items[i],
                        onTap: () => Navigator.of(context).pop(items[i]),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BaseRecipeTile extends StatelessWidget {
  const _BaseRecipeTile({required this.recipe, required this.onTap});

  final RecipeSummary recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accentTint,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.restaurant_rounded,
                    size: 20, color: AppColors.accent),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.link_rounded,
                            size: 13, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          l10n.recipeBaseBadge,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: Color(0xFFC4C0B5)),
            ],
          ),
        ),
      ),
    );
  }
}
