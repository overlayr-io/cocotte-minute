import 'package:flutter/material.dart';

import '../../../../../core/i18n/generated/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/timer_detector.dart';
import '../../bloc/recipe_player_cubit.dart';
import 'timer_sheet.dart';

/// Bouton « Ajouter un minuteur » (maquette 10b) : montre la durée détectée
/// dans le texte de l'étape si trouvée, ouvre la feuille de réglage (10f).
class AddTimerButton extends StatelessWidget {
  const AddTimerButton({
    super.key,
    required this.stepId,
    required this.description,
    required this.cubit,
  });

  final String stepId;
  final String description;
  final RecipePlayerCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detected = detectDuration(description);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final duration = await showTimerSheet(
          context,
          detected: detected,
          detectedText: detected == null ? null : description,
        );
        if (duration != null) {
          await cubit.startTimer(stepId, duration);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.pill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.timer_outlined, size: 19, color: AppColors.textMuted),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.playerAddTimerCta,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    detected == null
                        ? l10n.playerNoTimerDetected
                        : l10n.playerTimerDetectedHint(description),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.add_rounded, size: 20, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
