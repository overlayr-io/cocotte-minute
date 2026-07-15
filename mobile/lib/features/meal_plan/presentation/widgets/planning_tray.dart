import 'package:flutter/material.dart';

import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../recipes/domain/recipe.dart';
import 'meal_entry_visuals.dart';
import 'planning_boards.dart';

/// Bandeau « À planifier » (bas du planning) : recettes gardées sous la main,
/// à glisser sur les créneaux. Source du drag & drop (écran 1a).
class PlanningTray extends StatelessWidget {
  const PlanningTray({
    super.key,
    required this.recipes,
    required this.onManage,
  });

  final List<RecipeSummary> recipes;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.only(top: 10, bottom: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F2EA),
        border: Border(top: BorderSide(color: kPlanningHairline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.menu_book_outlined,
                      size: 13,
                      color: Color(0xFFA79F8B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.planningTrayTitle(recipes.length).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: kPlanningLabelMuted,
                      ),
                    ),
                  ],
                ),
                Text(
                  l10n.planningTrayHint,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: kPlanningDayMuted,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 50,
            child: recipes.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: onManage,
                      child: CustomPaint(
                        painter: const DashedRRectPainter(
                          color: kPlanningDashIdle,
                          radius: 13,
                          strokeWidth: 1.5,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add, size: 17, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.planningTrayEmptyCta,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      for (final recipe in recipes)
                        Padding(
                          padding: const EdgeInsets.only(right: 9),
                          child: _TrayChip(recipe: recipe),
                        ),
                      _ManageButton(label: l10n.planningTrayManage, onTap: onManage),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _TrayChip extends StatelessWidget {
  const _TrayChip({required this.recipe});

  final RecipeSummary recipe;

  @override
  Widget build(BuildContext context) {
    final chip = _chipBody(context, dragging: false);
    return LongPressDraggable<RecipeSummary>(
      data: recipe,
      delay: const Duration(milliseconds: 150),
      feedback: Transform.rotate(
        angle: -0.05,
        child: Material(
          color: Colors.transparent,
          child: _chipBody(context, dragging: true),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: chip),
      child: chip,
    );
  }

  Widget _chipBody(BuildContext context, {required bool dragging}) {
    final l10n = AppLocalizations.of(context);
    final total = recipe.prepTime + recipe.cookTime + recipe.restTime;
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 11, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: dragging ? 0.35 : 0.1),
            blurRadius: dragging ? 30 : 14,
            offset: Offset(0, dragging ? 14 : 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: recipe.photoUrl != null
                ? AppNetworkImage(recipe.photoUrl!, width: 34, height: 34)
                : Container(
                    width: 34,
                    height: 34,
                    color: AppColors.primaryTint,
                    child: const Icon(
                      Icons.restaurant_menu,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recipe.name,
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                l10n.searchMinutesShort(total),
                style: const TextStyle(fontSize: 10.5, color: Color(0xFFA79F8B)),
              ),
            ],
          ),
          const SizedBox(width: 6),
          const Icon(Icons.drag_indicator, size: 16, color: Color(0xFFCFC9B9)),
        ],
      ),
    );
  }
}

class _ManageButton extends StatelessWidget {
  const _ManageButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2E9),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0xFFDCE4D3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, size: 18, color: AppColors.primaryDark),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
