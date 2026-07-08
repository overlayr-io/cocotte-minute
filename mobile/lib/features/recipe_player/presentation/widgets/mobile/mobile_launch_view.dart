import 'package:flutter/material.dart';

import '../../../../../core/i18n/generated/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_network_image.dart';
import '../../../../recipes/domain/recipe.dart';
import '../../../domain/timer_detector.dart';
import '../../bloc/recipe_player_cubit.dart';
import '../shared/servings_stepper.dart';

/// Écran de lancement mobile (équivalent maquette 10a) : aperçu de la
/// recette à gauche, badges + choix du nombre de personnes + CTA à droite —
/// split horizontal pour rester confortable en paysage (hauteur réduite).
class MobileLaunchView extends StatelessWidget {
  const MobileLaunchView({super.key, required this.cubit, required this.state});

  final RecipePlayerCubit cubit;
  final RecipePlayerLoaded state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detail = state.detail;
    final subRecipeCount = detail.steps.whereType<RecipeBaseRefStep>().length;
    final detectedTimerCount =
        state.steps.where((s) => detectDuration(s.description) != null).length;

    return SafeArea(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                if (detail.summary.photoUrl != null)
                  Positioned.fill(
                    child: AppNetworkImage(
                      detail.summary.photoUrl!,
                      decodeWidth: MediaQuery.sizeOf(context).width,
                    ),
                  )
                else
                  const Positioned.fill(
                    child: ColoredBox(color: AppColors.panelBackground),
                  ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: _CircleButton(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.playerModeLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .5,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.playerReadyTitle,
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Badge(text: l10n.playerStepsBadge(state.totalSteps)),
                        if (subRecipeCount > 0)
                          _Badge(text: l10n.playerSubRecipesBadge(subRecipeCount)),
                        if (detectedTimerCount > 0)
                          _Badge(
                            text: l10n.playerTimersBadge(detectedTimerCount),
                            accent: true,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.playerServingsQuestion,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.playerServingsHint(detail.summary.servings),
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 8),
                    ServingsStepper(
                      value: state.selectedServings,
                      onChanged: cubit.setServings,
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: () => cubit.startCooking(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(
                        l10n.playerStartCta,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.smartphone_rounded,
                          size: 13,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            l10n.playerWakelockNotice,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, this.accent = false});

  final String text;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: accent ? const Color(0xFFFBF1DE) : AppColors.card,
        border: Border.all(
          color: accent ? const Color(0xFFF1DFB8) : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: accent ? const Color(0xFF9A7327) : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: .38),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
