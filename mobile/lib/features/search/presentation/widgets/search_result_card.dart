import 'package:flutter/material.dart';

import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../recipes/domain/recipe.dart';

/// Carte d'un résultat de recherche : vignette (photo ou dégradé de repli),
/// titre, portions + temps, chevron. Reprend la carte 11d.
class SearchResultCard extends StatelessWidget {
  const SearchResultCard({
    super.key,
    required this.recipe,
    required this.onTap,
  });

  final RecipeSummary recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final totalMinutes = recipe.prepTime + recipe.cookTime + recipe.restTime;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              _Thumb(recipe: recipe),
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
                        fontWeight: FontWeight.w700,
                        fontSize: 16.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${l10n.recipeServingsShort(recipe.servings)} · ${l10n.searchMinutesShort(totalMinutes)}',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 19, color: Color(0xFFCBC7BB)),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: SizedBox(
        width: 60,
        height: 60,
        child: recipe.photoUrl != null
            ? AppNetworkImage(recipe.photoUrl!, width: 60, height: 60)
            : DecoratedBox(
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
      ),
    );
  }
}
