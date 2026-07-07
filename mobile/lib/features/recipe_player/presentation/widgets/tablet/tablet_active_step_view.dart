import 'package:flutter/material.dart';

import '../../../../../core/i18n/generated/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../recipes/presentation/widgets/step_banner.dart';
import '../../../domain/recipe_timer.dart';
import '../../bloc/recipe_player_cubit.dart';
import '../shared/add_timer_button.dart';
import '../shared/quit_dialog.dart';
import '../shared/round_nav_button.dart';
import '../shared/step_ingredients_panel.dart';
import '../shared/step_timer_card.dart';
import '../shared/sub_recipe_strip.dart';
import '../shared/timer_chip.dart';

/// Étape active tablette (maquette 10b) : instruction en grand à gauche,
/// image + minuteur/ingrédients à droite. Le bouton « Étapes » (au centre de
/// la barre du haut) ouvre le sommaire (10c) via [onOpenSummary].
class TabletActiveStepView extends StatelessWidget {
  const TabletActiveStepView({
    super.key,
    required this.cubit,
    required this.state,
    required this.onOpenSummary,
  });

  final RecipePlayerCubit cubit;
  final RecipePlayerLoaded state;
  final VoidCallback onOpenSummary;

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
        if (step.subRecipe != null) SubRecipeStrip(subRecipe: step.subRecipe!),
        _TopBar(
          cubit: cubit,
          state: state,
          onOpenSummary: onOpenSummary,
          chipTimer: showChipInTopBar ? runningTimer : null,
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 11,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(52, 44, 40, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.textPrimary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${step.index + 1}',
                          style: const TextStyle(
                            fontFamily: AppFonts.display,
                            fontWeight: FontWeight.w700,
                            fontSize: 30,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            step.description,
                            style: const TextStyle(
                              fontFamily: AppFonts.display,
                              fontWeight: FontWeight.w600,
                              fontSize: 32,
                              height: 1.24,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      if (step.banner != null) ...[
                        const SizedBox(height: 14),
                        StepBannerBox(banner: step.banner!),
                      ],
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          RoundNavButton(
                            icon: Icons.chevron_left_rounded,
                            onTap: state.isFirstStep ? null : cubit.previousStep,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: cubit.nextStep,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              icon: const Icon(Icons.chevron_right_rounded),
                              label: Text(
                                state.isLastStep
                                    ? l10n.playerNext
                                    : l10n.playerNextStep,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
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
                flex: 9,
                child: Container(
                  color: AppColors.panelBackground,
                  padding: const EdgeInsets.all(26),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (state.detail.summary.photoUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              state.detail.summary.photoUrl!,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                        const SizedBox(height: 20),
                        if (stepTimer != null)
                          StepTimerCard(cubit: cubit, timer: stepTimer)
                        else
                          AddTimerButton(
                            stepId: step.sourceStepId,
                            description: step.description,
                            cubit: cubit,
                          ),
                        const SizedBox(height: 20),
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
  const _TopBar({
    required this.cubit,
    required this.state,
    required this.onOpenSummary,
    this.chipTimer,
  });

  final RecipePlayerCubit cubit;
  final RecipePlayerLoaded state;
  final VoidCallback onOpenSummary;
  final RecipeTimer? chipTimer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(34, 20, 30, 18),
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
                fontSize: 17,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onOpenSummary,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.playerStepProgress(
                          state.currentIndex + 1,
                          state.totalSteps,
                        ),
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.expand_more_rounded,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  SizedBox(
                    width: 340,
                    height: 6,
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
            ),
          ),
          const SizedBox(width: 12),
          if (chipTimer != null) ...[
            TimerChip(timer: chipTimer!),
            const SizedBox(width: 12),
          ],
          RoundNavButton(
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
