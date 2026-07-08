import 'package:flutter/material.dart';

import '../../../../../core/i18n/generated/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';

/// Dialog de confirmation pour quitter le mode cuisine (maquette 10i).
/// Retourne `true` si l'utilisateur confirme vouloir quitter.
Future<bool> showQuitDialog(
  BuildContext context, {
  required int stepIndex,
  required int totalSteps,
}) async {
  final l10n = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.bookmark_added_rounded,
                color: AppColors.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.playerQuitTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.playerQuitBody(stepIndex + 1, totalSteps),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(l10n.playerQuitContinue),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: const Color(0xFFE0554A),
                      side: const BorderSide(color: Color(0xFFF4CFC9)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(l10n.playerQuitConfirm),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}
