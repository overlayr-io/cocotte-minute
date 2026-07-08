import 'package:flutter/material.dart';

import '../../../../../core/i18n/generated/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_network_image.dart';
import '../../../../recipes/domain/recipe.dart';
import '../../../domain/timer_detector.dart';
import '../../bloc/recipe_player_cubit.dart';
import '../shared/servings_stepper.dart';

/// Écran de lancement tablette (maquette 10a) : aperçu large de la recette à
/// gauche, badges + choix des personnes + CTA à droite.
class TabletLaunchView extends StatelessWidget {
  const TabletLaunchView({super.key, required this.cubit, required this.state});

  final RecipePlayerCubit cubit;
  final RecipePlayerLoaded state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detail = state.detail;
    final subRecipeCount = detail.steps.whereType<RecipeBaseRefStep>().length;
    final detectedTimerCount =
        state.steps.where((s) => detectDuration(s.description) != null).length;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 9,
          child: Stack(
            children: [
              if (detail.summary.photoUrl != null)
                Positioned.fill(
                  child: AppNetworkImage(detail.summary.photoUrl!,
                      decodeWidth: MediaQuery.sizeOf(context).width),
                )
              else
                const Positioned.fill(
                  child: ColoredBox(color: AppColors.panelBackground),
                ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: .32),
                        Colors.transparent,
                        Colors.black.withValues(alpha: .55),
                      ],
                      stops: const [0, .32, 1],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 22,
                left: 22,
                child: _CircleButton(
                  icon: Icons.close_rounded,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
              Positioned(
                left: 28,
                right: 28,
                bottom: 28,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.playerModeLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .5,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      detail.name,
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w700,
                        fontSize: 32,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 11,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(48, 40, 48, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.playerModeLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .5,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.playerReadyTitle,
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w700,
                    fontSize: 36,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
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
                const Spacer(),
                Text(
                  l10n.playerServingsQuestion,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.playerServingsHint(detail.summary.servings),
                  style: const TextStyle(fontSize: 13.5, color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                ServingsStepper(
                  value: state.selectedServings,
                  onChanged: cubit.setServings,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => cubit.startCooking(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(
                      l10n.playerStartCta,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.smartphone_rounded, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        l10n.playerWakelockNotice,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: accent ? const Color(0xFFFBF1DE) : AppColors.card,
        border: Border.all(
          color: accent ? const Color(0xFFF1DFB8) : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
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
      color: Colors.black.withValues(alpha: .42),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
