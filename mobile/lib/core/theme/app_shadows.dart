import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Ombres partagées de l'app (élévation douce en deux couches teintées encre) :
/// une ombre de contact nette + un halo diffus, pour détacher les surfaces du
/// fond sans les assombrir. À utiliser à la place de `BoxShadow` ad hoc.
class AppShadows {
  const AppShadows._();

  /// Cartes de contenu posées sur le fond (items de liste, sections).
  static final List<BoxShadow> card = [
    BoxShadow(
      color: AppColors.textPrimary.withValues(alpha: 0.05),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
    BoxShadow(
      color: AppColors.textPrimary.withValues(alpha: 0.10),
      blurRadius: 26,
      spreadRadius: -12,
      offset: const Offset(0, 12),
    ),
  ];

  /// Surfaces flottantes au-dessus du contenu (nav, menus, barres).
  static final List<BoxShadow> floating = [
    BoxShadow(
      color: AppColors.textPrimary.withValues(alpha: 0.30),
      blurRadius: 50,
      spreadRadius: -18,
      offset: const Offset(0, 24),
    ),
  ];

  /// Halo coloré d'un élément mis en avant (FAB, chip actif, CTA).
  static List<BoxShadow> glow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.55),
      blurRadius: 22,
      spreadRadius: -4,
      offset: const Offset(0, 10),
    ),
  ];
}
