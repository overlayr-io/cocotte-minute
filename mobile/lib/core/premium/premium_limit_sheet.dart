import 'package:flutter/material.dart';

import '../../features/premium/presentation/pages/premium_page.dart';
import '../i18n/generated/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import 'premium_limit_error.dart';

/// Feuille d'upsell partagée, affichée à chaque limite freemium atteinte
/// (jamais de blocage silencieux ni de dialogue d'erreur brut) : rappel de la
/// limite + CTA « Découvrir Pro » vers le paywall.
Future<void> showPremiumLimitSheet(
  BuildContext context, {
  required PremiumLimitError error,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _PremiumLimitSheet(error: error),
  );
}

class _PremiumLimitSheet extends StatelessWidget {
  const _PremiumLimitSheet({required this.error});

  final PremiumLimitError error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (title, body) = _texts(l10n);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFDAD5C8),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.premiumGold, AppColors.premiumGoldDark],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w700,
                fontSize: 21,
                letterSpacing: -0.3,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.premiumGold, AppColors.premiumGoldDark],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: AppShadows.glow(AppColors.premiumGold),
                ),
                child: FilledButton(
                  onPressed: () {
                    // Navigator capturé avant le pop : le contexte de la
                    // feuille est démonté juste après.
                    final navigator = Navigator.of(context);
                    navigator.pop();
                    navigator.push(PremiumPage.route());
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    l10n.premiumLimitCta,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  l10n.premiumLimitDismiss,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Titre + corps selon le code serveur (repli générique si code inconnu).
  (String, String) _texts(AppLocalizations l10n) {
    return switch (error.code) {
      PremiumLimitError.baseRecipes => (
          l10n.premiumLimitBaseRecipesTitle,
          l10n.premiumLimitBaseRecipesBody(error.limit ?? 5),
        ),
      PremiumLimitError.shoppingLists => (
          l10n.premiumLimitShoppingListsTitle,
          l10n.premiumLimitShoppingListsBody,
        ),
      PremiumLimitError.searchCriteria => (
          l10n.premiumLimitSearchTitle,
          l10n.premiumLimitSearchBody(error.limit ?? 6),
        ),
      PremiumLimitError.galleryPhotos => (
          l10n.premiumLimitGalleryTitle,
          l10n.premiumLimitGalleryBody(error.limit ?? 3),
        ),
      PremiumLimitError.mealSlotEntries => (
          l10n.premiumLimitMealSlotTitle,
          l10n.premiumLimitMealSlotBody,
        ),
      PremiumLimitError.mealPlanWeek => (
          l10n.premiumLimitMealWeekTitle,
          l10n.premiumLimitMealWeekBody,
        ),
      PremiumLimitError.ingredientPhotos => (
          l10n.premiumLimitIngredientPhotosTitle,
          l10n.premiumLimitIngredientPhotosBody(error.limit ?? 1),
        ),
      _ => (l10n.premiumLimitGenericTitle, l10n.premiumLimitGenericBody),
    };
  }
}
