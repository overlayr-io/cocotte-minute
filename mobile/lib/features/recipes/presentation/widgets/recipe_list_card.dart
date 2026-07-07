import 'package:flutter/material.dart';

import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/recipe.dart';

/// Carte d'une recette en liste (onglet Recettes, recettes d'un dossier) :
/// vignette (photo ou dégradé de repli selon `isBase`), nom + badge « Base »,
/// ligne « N pers. · Prépa M min », chevron. Style maquette 7b.
class RecipeListCard extends StatelessWidget {
  const RecipeListCard({
    super.key,
    required this.recipe,
    required this.onTap,
  });

  final RecipeSummary recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
