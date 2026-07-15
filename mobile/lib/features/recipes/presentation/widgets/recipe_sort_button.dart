import 'package:flutter/material.dart';

import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/recipe_sort.dart';

/// Bouton-menu de tri (Récent / Temps / A-Z), partagé par la recherche avancée
/// et la vue Liste de la page Recettes.
class RecipeSortButton extends StatelessWidget {
  const RecipeSortButton({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final RecipeSort value;
  final ValueChanged<RecipeSort> onChanged;

  static String label(AppLocalizations l10n, RecipeSort sort) => switch (sort) {
        RecipeSort.recent => l10n.recipeSortRecent,
        RecipeSort.time => l10n.recipeSortTime,
        RecipeSort.name => l10n.recipeSortName,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<RecipeSort>(
      initialValue: value,
      tooltip: l10n.recipeSortTooltip,
      onSelected: onChanged,
      position: PopupMenuPosition.under,
      itemBuilder: (context) => [
        for (final s in RecipeSort.values)
          PopupMenuItem<RecipeSort>(
            value: s,
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  child: s == value
                      ? const Icon(Icons.check_rounded,
                          size: 18, color: AppColors.primary)
                      : null,
                ),
                Text(label(l10n, s)),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.swap_vert_rounded,
                size: 18, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Text(
              label(l10n, value),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
