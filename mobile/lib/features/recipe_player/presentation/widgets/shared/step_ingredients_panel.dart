import 'package:flutter/material.dart';

import '../../../../../core/i18n/generated/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_network_image.dart';
import '../../../../ingredients/domain/ingredient.dart';
import '../../../../ingredients/presentation/widgets/unit_selector.dart';
import '../../../../recipes/domain/recipe.dart';

/// Liste « Ingrédients de l'étape » (maquette 10b/10d/10j) : seulement les
/// ingrédients liés à l'étape active, quantités recalculées selon le nombre
/// de personnes choisi au lancement du mode.
class StepIngredientsPanel extends StatelessWidget {
  const StepIngredientsPanel({
    super.key,
    required this.ingredients,
    required this.scale,
    this.showTitle = true,
  });

  final List<RecipeIngredientLine> ingredients;

  /// Facteur d'échelle (personnes choisies / personnes par défaut).
  final double scale;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    if (ingredients.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTitle)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              l10n.playerIngredientsTitle,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: .2,
              ),
            ),
          ),
        for (final ingredient in ingredients)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _StepIngredientRow(ingredient: ingredient, scale: scale),
          ),
      ],
    );
  }
}

class _StepIngredientRow extends StatelessWidget {
  const _StepIngredientRow({required this.ingredient, required this.scale});

  final RecipeIngredientLine ingredient;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unit = IngredientUnit.fromWire(ingredient.unit);
    final shownQuantity = (ingredient.quantity * scale * 100).round() / 100;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppColors.pill,
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: ingredient.imageUrl != null
                ? AppNetworkImage(ingredient.imageUrl!, width: 38, height: 38)
                : const Icon(
                    Icons.egg_alt_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              ingredient.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            formatQuantityWithUnit(l10n, shownQuantity, unit),
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
