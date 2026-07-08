import 'package:flutter/material.dart';

import '../../../../../core/i18n/generated/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_network_image.dart';
import '../../../../recipes/presentation/widgets/step_banner.dart';
import '../../bloc/recipe_player_cubit.dart';
import '../shared/quit_dialog.dart';
import '../shared/round_nav_button.dart';
import '../shared/step_ingredients_panel.dart';
import '../shared/sub_recipe_strip.dart';
import '../shared/timer_zones.dart';

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

    return SafeArea(
      child: Column(
        children: [
          if (step.subRecipe != null) SubRecipeStrip(subRecipe: step.subRecipe!),
          _TopBar(
            cubit: cubit,
            state: state,
            currentStepId: step.sourceStepId,
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
                            RoundNavButton(
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
                              child: AppNetworkImage(
                                state.detail.summary.photoUrl!,
                                height: 140,
                                decodeWidth: 400,
                              ),
                            ),
                          const SizedBox(height: 14),
                          StepTimerZone(
                            cubit: cubit,
                            stepId: step.sourceStepId,
                            description: step.description,
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
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.cubit,
    required this.state,
    required this.currentStepId,
  });

  final RecipePlayerCubit cubit;
  final RecipePlayerLoaded state;
  final String currentStepId;

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
          RunningTimerChipZone(
            cubit: cubit,
            currentStepId: currentStepId,
            padding: const EdgeInsets.only(left: 12),
          ),
          const SizedBox(width: 12),
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
