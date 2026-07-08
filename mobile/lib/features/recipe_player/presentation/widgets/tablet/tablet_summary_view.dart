import 'package:flutter/material.dart';

import '../../../../../core/i18n/generated/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_network_image.dart';
import '../../../../recipes/domain/recipe.dart';
import '../../../domain/playable_step.dart';
import '../../../domain/recipe_timer.dart';
import '../../../domain/timer_detector.dart';
import '../../bloc/recipe_player_cubit.dart';
import '../shared/round_nav_button.dart';

/// Sommaire des étapes tablette (maquette 10c) : rail récap à gauche (image,
/// titre, badges, progression, retour à l'étape en cours) et liste complète
/// des étapes à droite, groupées par sous-recette, cliquables pour sauter.
class TabletSummaryView extends StatelessWidget {
  const TabletSummaryView({
    super.key,
    required this.cubit,
    required this.state,
    required this.onClose,
  });

  final RecipePlayerCubit cubit;
  final RecipePlayerLoaded state;
  final VoidCallback onClose;

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
        Container(
          width: 340,
          padding: const EdgeInsets.all(28),
          color: AppColors.panelBackground,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RoundNavButton(icon: Icons.close_rounded, onTap: onClose),
              const SizedBox(height: 20),
              if (detail.summary.photoUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AppNetworkImage(
                    detail.summary.photoUrl!,
                    height: 170,
                    decodeWidth: 340,
                  ),
                ),
              const SizedBox(height: 18),
              Text(
                detail.name,
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Badge(text: l10n.playerStepsBadge(state.totalSteps)),
                  _Badge(
                    text: l10n.playerForServings(state.selectedServings),
                  ),
                  if (subRecipeCount > 0)
                    _Badge(text: l10n.playerSubRecipesBadge(subRecipeCount)),
                  if (detectedTimerCount > 0)
                    _Badge(
                      text: l10n.playerTimersBadge(detectedTimerCount),
                      accent: true,
                    ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.playerProgressLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${state.currentIndex + 1} / ${state.totalSteps}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: (state.currentIndex + 1) / state.totalSteps,
                  minHeight: 7,
                  backgroundColor: AppColors.divider,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onClose,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    l10n.playerResumeStepCta(state.currentIndex + 1),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(30, 26, 30, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.playerSummaryTitle,
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      l10n.playerSummaryHint,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: _buildItems(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildItems(BuildContext context) {
    final items = <Widget>[];
    var i = 0;
    while (i < state.steps.length) {
      final step = state.steps[i];
      if (step.subRecipe == null) {
        items.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: _StepRow(
              step: step,
              state: state,
              onTap: () => _jumpAndClose(step.index),
            ),
          ),
        );
        i++;
        continue;
      }

      final groupName = step.subRecipe!.baseRecipeName;
      final group = <PlayableStep>[];
      while (i < state.steps.length &&
          state.steps[i].subRecipe?.baseRecipeName == groupName) {
        group.add(state.steps[i]);
        i++;
      }
      items.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: _SubRecipeGroup(
            baseRecipeName: groupName,
            steps: group,
            state: state,
            onStepTap: _jumpAndClose,
          ),
        ),
      );
    }
    return items;
  }

  void _jumpAndClose(int index) {
    cubit.jumpToStep(index);
    onClose();
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, this.accent = false});

  final String text;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: accent ? const Color(0xFF9A7327) : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.state,
    required this.onTap,
    this.compact = false,
  });

  final PlayableStep step;
  final RecipePlayerLoaded state;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDone = step.index < state.currentIndex;
    final isCurrent = step.index == state.currentIndex;
    final timer = state.timers
        .where((t) => t.stepId == step.sourceStepId)
        .fold<RecipeTimer?>(null, (acc, t) => t);

    final numberCircle = isDone
        ? Container(
            width: compact ? 26 : 30,
            height: compact ? 26 : 30,
            decoration: const BoxDecoration(
              color: Color(0xFFE7EFDD),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, size: 15, color: Color(0xFF5C7A4C)),
          )
        : Container(
            width: compact ? 26 : 30,
            height: compact ? 26 : 30,
            decoration: BoxDecoration(
              color: isCurrent ? AppColors.primary : AppColors.pill,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${step.index + 1}',
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w700,
                fontSize: compact ? 12 : 13,
                color: isCurrent ? Colors.white : AppColors.textSecondary,
              ),
            ),
          );

    return Material(
      color: isCurrent ? AppColors.card : Colors.transparent,
      borderRadius: BorderRadius.circular(isCurrent ? 15 : 13),
      child: InkWell(
        borderRadius: BorderRadius.circular(isCurrent ? 15 : 13),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 14,
            vertical: compact ? 9 : 12,
          ),
          decoration: isCurrent
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: AppColors.primary, width: 1.5),
                )
              : null,
          child: Row(
            children: [
              numberCircle,
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  step.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 13.5 : 15,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                    color: isDone
                        ? AppColors.textMuted
                        : (isCurrent ? AppColors.textPrimary : AppColors.textSecondary),
                  ),
                ),
              ),
              if (timer != null) ...[
                const SizedBox(width: 8),
                _InlineTimerBadge(timer: timer),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineTimerBadge extends StatelessWidget {
  const _InlineTimerBadge({required this.timer});

  final RecipeTimer timer;

  @override
  Widget build(BuildContext context) {
    final remaining = timer.remaining ?? timer.totalDuration;
    final minutes = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF1DE),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFF1DFB8)),
      ),
      child: Text(
        '$minutes:$seconds',
        style: const TextStyle(
          fontFamily: AppFonts.display,
          fontWeight: FontWeight.w700,
          fontSize: 11.5,
          color: Color(0xFF8A6316),
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _SubRecipeGroup extends StatelessWidget {
  const _SubRecipeGroup({
    required this.baseRecipeName,
    required this.steps,
    required this.state,
    required this.onStepTap,
  });

  final String baseRecipeName;
  final List<PlayableStep> steps;
  final RecipePlayerLoaded state;
  final ValueChanged<int> onStepTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE6D3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE4EDDA))),
            ),
            child: Row(
              children: [
                const Icon(Icons.link_rounded, size: 16, color: Color(0xFF5C7A4C)),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    baseRecipeName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4B6340),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2ECD7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    l10n.playerSubRecipeLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF5C7A4C),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              children: [
                for (final step in steps)
                  _StepRow(
                    step: step,
                    state: state,
                    onTap: () => onStepTap(step.index),
                    compact: true,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
