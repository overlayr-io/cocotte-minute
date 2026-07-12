import 'package:flutter/material.dart';

import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/meal_plan_entry.dart';
import 'add_entry_sheet.dart';
import 'meal_entry_visuals.dart';

/// Détail d'un créneau multi-recettes (écran 1g) : chaque entrée est listée et
/// retirable une à une, avec l'option d'en ajouter une autre (Premium).
///
/// [onRemove] est appelé à chaque retrait (la sheet reste ouverte et se met à
/// jour) ; [onAdd] ferme la sheet puis rouvre la sheet d'ajout.
Future<void> showSlotDetailSheet(
  BuildContext context, {
  required String slotLabel,
  required List<MealPlanEntry> entries,
  required bool canEdit,
  required bool canAdd,
  required Future<void> Function(MealPlanEntry entry) onRemove,
  VoidCallback? onAdd,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _SlotDetailSheet(
      slotLabel: slotLabel,
      entries: entries,
      canEdit: canEdit,
      canAdd: canAdd,
      onRemove: onRemove,
      onAdd: onAdd,
    ),
  );
}

class _SlotDetailSheet extends StatefulWidget {
  const _SlotDetailSheet({
    required this.slotLabel,
    required this.entries,
    required this.canEdit,
    required this.canAdd,
    required this.onRemove,
    required this.onAdd,
  });

  final String slotLabel;
  final List<MealPlanEntry> entries;
  final bool canEdit;
  final bool canAdd;
  final Future<void> Function(MealPlanEntry entry) onRemove;
  final VoidCallback? onAdd;

  @override
  State<_SlotDetailSheet> createState() => _SlotDetailSheetState();
}

class _SlotDetailSheetState extends State<_SlotDetailSheet> {
  late final List<MealPlanEntry> _entries = [...widget.entries];

  Future<void> _remove(MealPlanEntry entry) async {
    await widget.onRemove(entry);
    if (!mounted) return;
    setState(() => _entries.removeWhere((e) => e.id == entry.id));
    if (_entries.isEmpty) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFDAD5C8),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.slotLabel.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: kPlanningKicker,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        l10n.planningDetailTitle(_entries.length),
                        style: const TextStyle(
                          fontFamily: AppFonts.display,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          letterSpacing: -0.4,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 20,
                      color: Color(0xFF8A8574),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            for (final entry in _entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      MealEntryThumb(entry: entry, size: 48, radius: 11),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mealEntryName(l10n, entry),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: AppFonts.display,
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              mealEntryMeta(l10n, entry),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.canEdit)
                        GestureDetector(
                          onTap: () => _remove(entry),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDEFEA),
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(color: const Color(0xFFF1D9CF)),
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: Color(0xFFC0544A),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if (widget.canAdd && widget.onAdd != null)
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  widget.onAdd!();
                },
                child: CustomPaint(
                  painter: const DashedRRectPainter(
                    color: Color(0xFFC7BFA9),
                    radius: 14,
                  ),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add, size: 17, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context).planningMenuAdd,
                          style: const TextStyle(
                            fontFamily: AppFonts.display,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
