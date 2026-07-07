import 'package:flutter/material.dart';

import '../../../../../core/i18n/generated/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../recipes/presentation/widgets/step_banner.dart';
import '../../../domain/playable_step.dart';
import '../../../domain/recipe_timer.dart';
import '../../../domain/timer_detector.dart';
import '../../bloc/recipe_player_cubit.dart';
import '../shared/circular_timer_display.dart';
import '../shared/quit_dialog.dart';
import '../shared/step_ingredients_panel.dart';
import '../shared/timer_sheet.dart';

/// Étape active en mobile paysage (maquette 10d/10e/10j) : instruction en
/// grand à gauche, image + minuteur/ingrédients à droite. Bandeau de
/// sous-recette permanent si l'étape provient d'une référence de base ;
/// minuteur en cours affiché en top bar quand il ne concerne pas l'étape
/// affichée.
class MobileActiveStepView extends StatelessWidget {
  const MobileActiveStepView({
    super.key,
    required this.cubit,
    required this.state,
  });

  final RecipePlayerCubit cubit;
  final RecipePlayerLoaded state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final step = state.currentStep;
    final scale = state.selectedServings / state.detail.summary.servings;
    final runningTimer = state.runningTimer;
    final stepTimer = state.timers
        .where((t) => t.stepId == step.sourceStepId)
        .fold<RecipeTimer?>(null, (acc, t) => t);
    final showChipInTopBar =
        runningTimer != null && runningTimer.stepId != step.sourceStepId;

    return Column(
      children: [
        if (step.subRecipe != null) _SubRecipeStrip(subRecipe: step.subRecipe!),
        _TopBar(
          cubit: cubit,
          state: state,
          chipTimer: showChipInTopBar ? runningTimer : null,
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 22, 18, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.textPrimary,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${step.index + 1}',
                          style: const TextStyle(
                            fontFamily: AppFonts.display,
                            fontWeight: FontWeight.w700,
                            fontSize: 21,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            step.description,
                            style: const TextStyle(
                              fontFamily: AppFonts.display,
                              fontWeight: FontWeight.w600,
                              fontSize: 24,
                              height: 1.25,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      if (step.banner != null) ...[
                        const SizedBox(height: 12),
                        StepBannerBox(banner: step.banner!),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _RoundNavButton(
                            icon: Icons.chevron_left_rounded,
                            onTap: state.isFirstStep ? null : cubit.previousStep,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: cubit.nextStep,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(Icons.chevron_right_rounded),
                              label: Text(
                                state.isLastStep
                                    ? l10n.playerNext
                                    : l10n.playerNextStep,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  color: AppColors.panelBackground,
                  padding: const EdgeInsets.all(18),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (state.detail.summary.photoUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.network(
                              state.detail.summary.photoUrl!,
                              height: 140,
                              fit: BoxFit.cover,
                            ),
                          ),
                        const SizedBox(height: 14),
                        if (stepTimer != null)
                          _StepTimerCard(cubit: cubit, timer: stepTimer)
                        else
                          _AddTimerButton(
                            stepId: step.sourceStepId,
                            description: step.description,
                            cubit: cubit,
                          ),
                        const SizedBox(height: 14),
                        StepIngredientsPanel(
                          ingredients: step.ingredients,
                          scale: scale,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.cubit, required this.state, this.chipTimer});

  final RecipePlayerCubit cubit;
  final RecipePlayerLoaded state;
  final RecipeTimer? chipTimer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 18, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              state.detail.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.playerStepProgress(state.currentIndex + 1, state.totalSteps),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 170,
                height: 5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: (state.currentIndex + 1) / state.totalSteps,
                    backgroundColor: AppColors.divider,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
          if (chipTimer != null) ...[
            const SizedBox(width: 12),
            _TimerChip(timer: chipTimer!),
          ],
          const SizedBox(width: 12),
          _RoundNavButton(
            icon: Icons.close_rounded,
            onTap: () async {
              final confirmed = await showQuitDialog(
                context,
                stepIndex: state.currentIndex,
                totalSteps: state.totalSteps,
              );
              if (confirmed) {
                await cubit.quitSession();
                if (context.mounted) Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }
}

class _TimerChip extends StatelessWidget {
  const _TimerChip({required this.timer});

  final RecipeTimer timer;

  @override
  Widget build(BuildContext context) {
    final remaining = timer.remaining ?? Duration.zero;
    final minutes = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF1DE),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFF1DFB8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 15, color: AppColors.timerAccent),
          const SizedBox(width: 6),
          Text(
            '$minutes:$seconds',
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFF8A6316),
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubRecipeStrip extends StatelessWidget {
  const _SubRecipeStrip({required this.subRecipe});

  final SubRecipeContext subRecipe;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      color: const Color(0xFFEDF2E7),
      child: Row(
        children: [
          const Icon(Icons.link_rounded, size: 16, color: Color(0xFF5C7A4C)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.playerSubRecipeContext(subRecipe.baseRecipeName),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13.5, color: Color(0xFF4B6340)),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFE2ECD7),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              l10n.playerSubRecipeBadge(subRecipe.localIndex, subRecipe.localTotal),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF5C7A4C),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddTimerButton extends StatelessWidget {
  const _AddTimerButton({
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

class _StepTimerCard extends StatelessWidget {
  const _StepTimerCard({required this.cubit, required this.timer});

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
              _RoundNavButton(
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

class _RoundNavButton extends StatelessWidget {
  const _RoundNavButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            icon,
            size: 22,
            color: onTap == null ? AppColors.textMuted : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
