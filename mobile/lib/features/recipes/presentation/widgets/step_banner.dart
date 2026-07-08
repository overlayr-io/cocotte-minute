import 'package:flutter/material.dart';

import '../../../../core/i18n/generated/app_localizations.dart';
import '../../domain/recipe.dart';

/// Couleurs/icône d'une bannière d'étape, dérivées du type (préréglages fidèles
/// à la maquette : warning ambre, info bleu, danger rouge, learn vert).
class StepBannerStyle {
  const StepBannerStyle({
    required this.background,
    required this.accent,
    required this.icon,
    required this.iconData,
    required this.text,
  });

  final Color background;
  final Color accent;
  final Color icon;
  final IconData iconData;
  final Color text;
}

StepBannerStyle stepBannerStyle(StepBannerType type) => switch (type) {
      StepBannerType.warning => const StepBannerStyle(
          background: Color(0xFFFBF1DE),
          accent: Color(0xFFE8A33D),
          icon: Color(0xFFB87A18),
          iconData: Icons.warning_amber_rounded,
          text: Color(0xFF8A5A12),
        ),
      StepBannerType.info => const StepBannerStyle(
          background: Color(0xFFE8F0F9),
          accent: Color(0xFF4B87C7),
          icon: Color(0xFF2E6BA6),
          iconData: Icons.info_outline_rounded,
          text: Color(0xFF2E5E8F),
        ),
      StepBannerType.danger => const StepBannerStyle(
          background: Color(0xFFFBE9E7),
          accent: Color(0xFFD0574B),
          icon: Color(0xFFC1493D),
          iconData: Icons.error_outline_rounded,
          text: Color(0xFF9E3529),
        ),
      StepBannerType.learn => const StepBannerStyle(
          background: Color(0xFFE7F1EC),
          accent: Color(0xFF5A9E86),
          icon: Color(0xFF47846E),
          iconData: Icons.lightbulb_outline_rounded,
          text: Color(0xFF38705B),
        ),
    };

String stepBannerLabel(AppLocalizations l10n, StepBannerType type) => switch (type) {
      StepBannerType.warning => l10n.stepBannerWarning,
      StepBannerType.info => l10n.stepBannerInfo,
      StepBannerType.danger => l10n.stepBannerDanger,
      StepBannerType.learn => l10n.stepBannerLearn,
    };

/// Bannière pleine largeur affichée sous une étape (filet de couleur à gauche).
class StepBannerBox extends StatelessWidget {
  const StepBannerBox({super.key, required this.banner});

  final StepBanner banner;

  @override
  Widget build(BuildContext context) {
    final s = stepBannerStyle(banner.type);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 9),
      padding: const EdgeInsets.fromLTRB(11, 8, 12, 8),
      decoration: BoxDecoration(
        color: s.background,
        borderRadius: BorderRadius.circular(9),
        border: Border(left: BorderSide(color: s.accent, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(s.iconData, size: 16, color: s.icon),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              banner.text,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: s.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
