import 'package:flutter/material.dart';

import '../../../../../core/i18n/generated/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/recipe_timer.dart';
import '../../bloc/recipe_player_cubit.dart';
import 'circular_timer_display.dart';
import 'round_nav_button.dart';

/// Carte du minuteur rattaché à l'étape active (maquette 10d) : anneau de
/// progression + Démarrer/Pause + Réinitialiser.
class StepTimerCard extends StatelessWidget {
  const StepTimerCard({super.key, required this.cubit, required this.timer});

  final RecipePlayerCubit cubit;
  final RecipeTimer timer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          CircularTimerDisplay(
            remaining: timer.remaining ?? timer.totalDuration,
            total: timer.totalDuration,
            size: 130,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: timer.status == TimerStatus.running
                      ? () => cubit.pauseTimer(timer.id)
                      : () => cubit.startTimer(
                            timer.stepId,
                            timer.remaining ?? timer.totalDuration,
                            label: timer.label,
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.timerAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: Icon(
                    timer.status == TimerStatus.running
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 18,
                  ),
                  label: Text(l10n.playerTimerStart),
                ),
              ),
              const SizedBox(width: 10),
              RoundNavButton(
                icon: Icons.refresh_rounded,
                onTap: () => cubit.resetTimer(timer.id),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.playerTimerDetectedAdjustable,
            style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
