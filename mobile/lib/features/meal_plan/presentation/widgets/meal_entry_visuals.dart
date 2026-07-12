import 'package:flutter/material.dart';

import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../domain/meal_plan_entry.dart';

/// Fond bleu « Manger dehors » (design : pastille couverts). Couleurs propres
/// à ce type d'entrée, absentes de la palette globale.
const kEatingOutTint = Color(0xFFE7EEF5);
const kEatingOutFg = Color(0xFF4E7196);

/// Fond ambre « Note libre » (pastille crayon).
const kNoteTint = Color(0xFFF6EEDF);
const kNoteFg = Color(0xFFB8792B);

/// Vignette d'une entrée de planning : photo de la recette, ou pastille
/// dédiée (couverts / crayon) pour « manger dehors » et les notes.
class MealEntryThumb extends StatelessWidget {
  const MealEntryThumb({
    super.key,
    required this.entry,
    required this.size,
    this.width,
    this.radius = 10,
  });

  final MealPlanEntry entry;
  final double size;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final w = width ?? size;
    final (tint, fg, icon) = switch (entry.type) {
      MealEntryType.eatingOut => (kEatingOutTint, kEatingOutFg, Icons.restaurant),
      MealEntryType.note => (kNoteTint, kNoteFg, Icons.edit_outlined),
      MealEntryType.recipe => (AppColors.primaryTint, AppColors.primary, Icons.restaurant_menu),
    };
    final photoUrl = entry.recipe?.photoUrl;
    // Largeur infinie (vignette pleine largeur de card) : on laisse le parent
    // contraindre et on fixe seulement la largeur de décodage.
    final finiteWidth = w.isFinite ? w : null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: entry.type == MealEntryType.recipe && photoUrl != null
          ? SizedBox(
              width: w,
              height: size,
              child: AppNetworkImage(
                photoUrl,
                width: finiteWidth,
                height: size,
                decodeWidth: finiteWidth == null ? 160 : null,
              ),
            )
          : Container(
              width: w,
              height: size,
              color: tint,
              child: Icon(icon, color: fg, size: size * 0.45),
            ),
    );
  }
}

/// Nom affiché d'une entrée (titre recette, note, ou « Manger dehors »).
String mealEntryName(AppLocalizations l10n, MealPlanEntry entry) {
  return switch (entry.type) {
    MealEntryType.recipe => entry.recipe?.name ?? '',
    MealEntryType.eatingOut => l10n.planningEatingOut,
    MealEntryType.note => entry.noteText ?? l10n.planningNoteMeta,
  };
}

/// Sous-titre d'une entrée (« Plat · 50 min » façon design, ici parts + temps).
String mealEntryMeta(AppLocalizations l10n, MealPlanEntry entry) {
  return switch (entry.type) {
    MealEntryType.recipe => () {
      final r = entry.recipe!;
      final total = r.prepTime + r.cookTime + r.restTime;
      return '${l10n.recipeServingsShort(r.servings)} · ${l10n.searchMinutesShort(total)}';
    }(),
    MealEntryType.eatingOut => l10n.planningEatingOutMeta,
    MealEntryType.note => l10n.planningNoteMeta,
  };
}

/// Icône d'un créneau (matin / midi / soir).
IconData mealSlotIcon(MealSlot slot) => switch (slot) {
  MealSlot.matin => Icons.wb_twilight_rounded,
  MealSlot.midi => Icons.wb_sunny_outlined,
  MealSlot.soir => Icons.nightlight_outlined,
};

String mealSlotLabel(AppLocalizations l10n, MealSlot slot) => switch (slot) {
  MealSlot.matin => l10n.planningSlotMorning,
  MealSlot.midi => l10n.planningSlotNoon,
  MealSlot.soir => l10n.planningSlotEvening,
};

/// Bordure pointillée arrondie (créneaux vides / zones de dépôt), absente des
/// primitives Flutter.
class DashedRRectPainter extends CustomPainter {
  const DashedRRectPainter({
    required this.color,
    this.radius = 13,
    this.strokeWidth = 1.6,
    this.dash = 5,
    this.gap = 4,
  });

  final Color color;
  final double radius;
  final double strokeWidth;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dash),
          paint,
        );
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(DashedRRectPainter oldDelegate) =>
      color != oldDelegate.color ||
      radius != oldDelegate.radius ||
      strokeWidth != oldDelegate.strokeWidth;
}
