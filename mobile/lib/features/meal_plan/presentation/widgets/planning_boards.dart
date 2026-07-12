import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../recipes/domain/recipe.dart';
import '../../domain/meal_plan_entry.dart';
import '../../domain/meal_plan_week.dart';
import 'meal_entry_visuals.dart';

/// Fond des en-têtes / surfaces claires du planning (maquette).
const kPlanningHeaderBg = Color(0xFFFCFBF8);
const kPlanningHairline = Color(0xFFEFE9DC);
const kPlanningDashIdle = Color(0xFFCFC8B6);
const kPlanningDashDisabled = Color(0xFFDCD6C7);
const kPlanningLabelMuted = Color(0xFF9A927E);
const kPlanningDayMuted = Color(0xFFB0A892);

typedef SlotTap = void Function(String day, MealSlot slot);
typedef EntryTap = void Function(BuildContext cellContext, String day, MealSlot slot);
typedef RecipeDrop = void Function(String day, MealSlot slot, RecipeSummary recipe);

/// Paramètres partagés des deux mises en page du calendrier (grille / blocs).
class PlanningBoardData {
  const PlanningBoardData({
    required this.week,
    required this.entriesOf,
    required this.readonly,
    required this.selectMode,
    required this.selectedSlots,
    this.onAddToSlot,
    this.onTapSlot,
    this.onToggleSelect,
    this.onDropRecipe,
  });

  final MealPlanWeek week;
  final List<MealPlanEntry> Function(String day, MealSlot slot) entriesOf;
  final bool readonly;
  final bool selectMode;
  final Set<String> selectedSlots;

  /// « + » sur un créneau vide (ouvre la sheet d'ajout).
  final SlotTap? onAddToSlot;

  /// Tap sur un créneau rempli (menu contextuel ou détail multi-recettes).
  final EntryTap? onTapSlot;

  /// Coche/décoche en mode sélection (clé `day|slot`).
  final void Function(String slotKey)? onToggleSelect;

  /// Dépôt d'une recette glissée depuis le bandeau « À planifier ».
  final RecipeDrop? onDropRecipe;

  bool get interactive => !readonly && !selectMode;
}

/// Variation A — grille 7 jours × 3 créneaux (écran 1a).
class PlanningGridBoard extends StatelessWidget {
  const PlanningGridBoard({super.key, required this.data, this.header});

  final PlanningBoardData data;

  /// Contenu optionnel affiché au-dessus des lignes (accroche 1e).
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final today = dayKey(DateTime.now());
    return ListView(
      padding: const EdgeInsets.only(bottom: 12),
      children: [
        ?header,
        for (var d = 0; d < 7; d++) _buildDayRow(context, d, today),
      ],
    );
  }

  Widget _buildDayRow(BuildContext context, int dayIndex, String today) {
    final date = data.week.dayAt(dayIndex);
    final day = dayKey(date);
    final isToday = day == today;
    final locale = Localizations.localeOf(context).toString();
    final letters = shortWeekday(locale, date);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: isToday ? AppColors.primary.withValues(alpha: 0.07) : null,
        border: const Border(
          bottom: BorderSide(color: Color(0xFFF1EDE3)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  letters,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: isToday ? AppColors.primaryDark : kPlanningDayMuted,
                  ),
                ),
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    height: 1,
                    color: isToday ? AppColors.primaryDark : AppColors.textPrimary,
                  ),
                ),
                if (isToday)
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
          for (final slot in MealSlot.values) ...[
            const SizedBox(width: 7),
            Expanded(child: _GridSlotCell(data: data, day: day, slot: slot)),
          ],
        ],
      ),
    );
  }
}

/// Ligne d'en-têtes de colonnes Matin / Midi / Soir (vue grille).
class PlanningGridHeader extends StatelessWidget {
  const PlanningGridHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(50, 8, 16, 8),
      decoration: const BoxDecoration(
        color: kPlanningHeaderBg,
        border: Border(bottom: BorderSide(color: kPlanningHairline)),
      ),
      child: Row(
        children: [
          for (final slot in MealSlot.values)
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(mealSlotIcon(slot), size: 15, color: const Color(0xFFA79F8B)),
                  const SizedBox(width: 5),
                  Text(
                    mealSlotLabel(l10n, slot).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: kPlanningLabelMuted,
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

class _GridSlotCell extends StatelessWidget {
  const _GridSlotCell({required this.data, required this.day, required this.slot});

  final PlanningBoardData data;
  final String day;
  final MealSlot slot;

  String get _slotKey => '$day|${slot.wire}';

  @override
  Widget build(BuildContext context) {
    final entries = data.entriesOf(day, slot);
    final cell = _buildCell(context, entries);
    if (data.onDropRecipe == null || !data.interactive) return cell;
    return DragTarget<RecipeSummary>(
      onAcceptWithDetails: (details) => data.onDropRecipe!(day, slot, details.data),
      builder: (context, candidates, _) =>
          candidates.isNotEmpty ? const PlanningDropHint(minHeight: 78) : cell,
    );
  }

  Widget _buildCell(BuildContext context, List<MealPlanEntry> entries) {
    final l10n = AppLocalizations.of(context);
    if (entries.isEmpty) {
      if (data.selectMode) {
        return _dashed(
          color: const Color(0xFFE0DACB),
          fill: Colors.white.withValues(alpha: 0.35),
          child: const SizedBox(height: 78),
        );
      }
      final enabled = data.interactive && data.onAddToSlot != null;
      return GestureDetector(
        onTap: enabled ? () => data.onAddToSlot!(day, slot) : null,
        child: _dashed(
          color: data.readonly ? kPlanningDashDisabled : kPlanningDashIdle,
          fill: Colors.white.withValues(alpha: data.readonly ? 0.25 : 0.5),
          child: SizedBox(
            height: 78,
            child: Center(
              child: data.readonly
                  ? null
                  : Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEEF2E9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, size: 16, color: AppColors.primary),
                    ),
            ),
          ),
        ),
      );
    }

    final first = entries.first;
    final extra = entries.length - 1;
    final multi = extra > 0;
    final checked = data.selectedSlots.contains(_slotKey);

    final card = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFECEAE3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              MealEntryThumb(entry: first, size: 54, width: double.infinity, radius: 0),
              if (multi)
                Positioned(
                  top: 5,
                  left: 5,
                  child: Row(
                    children: [
                      for (var i = 0; i < entries.length && i < 3; i++)
                        Container(
                          transform: Matrix4.translationValues(i * -7.0, 0, 0),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 1.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: MealEntryThumb(entry: entries[i], size: 18, radius: 4.5),
                        ),
                    ],
                  ),
                ),
              if (multi)
                Positioned(
                  top: 6,
                  right: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.premiumGold, AppColors.premiumGoldDark],
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${entries.length}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(7, 6, 7, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mealEntryName(l10n, first),
                  maxLines: multi ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                    height: 1.12,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (multi)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      l10n.planningMoreOthers(extra),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFB0862E),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTap: () {
        if (data.selectMode) {
          data.onToggleSelect?.call(_slotKey);
        } else if (data.onTapSlot != null) {
          data.onTapSlot!(context, day, slot);
        }
      },
      child: Opacity(
        opacity: data.readonly && !data.selectMode ? 0.62 : 1,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Effet « paquet de cartes » derrière un créneau multi-recettes.
            if (multi) ...[
              Positioned(
                top: -5,
                left: 5,
                right: 5,
                bottom: 5,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEE8DB),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: const Color(0xFFE4DDCB)),
                  ),
                ),
              ),
              Positioned(
                top: -2.5,
                left: 2.5,
                right: 2.5,
                bottom: 2.5,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F1E7),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: const Color(0xFFE9E2D0)),
                  ),
                ),
              ),
            ],
            card,
            if (data.selectMode)
              Positioned(top: 5, left: 5, child: _SelectCheck(checked: checked)),
          ],
        ),
      ),
    );
  }

  Widget _dashed({required Color color, required Color fill, required Widget child}) {
    return CustomPaint(
      painter: DashedRRectPainter(color: color, radius: 13),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(13),
        ),
        child: child,
      ),
    );
  }
}

/// Variation B — un bloc par jour, créneaux empilés (écran 1b).
class PlanningBlocksBoard extends StatelessWidget {
  const PlanningBlocksBoard({super.key, required this.data, this.header});

  final PlanningBoardData data;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final today = dayKey(DateTime.now());
    final locale = Localizations.localeOf(context).toString();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      children: [
        ?header,
        for (var d = 0; d < 7; d++)
          _buildDayBlock(context, l10n, locale, d, today),
      ],
    );
  }

  Widget _buildDayBlock(
    BuildContext context,
    AppLocalizations l10n,
    String locale,
    int dayIndex,
    String today,
  ) {
    final date = data.week.dayAt(dayIndex);
    final day = dayKey(date);
    final isToday = day == today;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: kPlanningHeaderBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECEAE3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(
              gradient: isToday
                  ? const LinearGradient(
                      colors: [Color(0xFFEEF3E9), kPlanningHeaderBg],
                    )
                  : null,
              color: isToday ? null : const Color(0xFFF5F2EA),
              border: const Border(bottom: BorderSide(color: kPlanningHairline)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text.rich(
                  TextSpan(
                    text: longWeekday(locale, date),
                    style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontWeight: FontWeight.w700,
                      fontSize: 15.5,
                      color: AppColors.textPrimary,
                    ),
                    children: [
                      TextSpan(
                        text: '  ${date.day}',
                        style: const TextStyle(
                          color: Color(0xFFA79F8B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3EDDB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      l10n.planningToday.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
            child: Column(
              children: [
                for (final slot in MealSlot.values)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: slot == MealSlot.values.last ? 0 : 10,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 60,
                          child: Column(
                            children: [
                              Icon(
                                mealSlotIcon(slot),
                                size: 18,
                                color: const Color(0xFFA79F8B),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                mealSlotLabel(l10n, slot).toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                  color: kPlanningLabelMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: _WideSlotCell(data: data, day: day, slot: slot)),
                      ],
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

class _WideSlotCell extends StatelessWidget {
  const _WideSlotCell({required this.data, required this.day, required this.slot});

  final PlanningBoardData data;
  final String day;
  final MealSlot slot;

  String get _slotKey => '$day|${slot.wire}';

  @override
  Widget build(BuildContext context) {
    final entries = data.entriesOf(day, slot);
    final cell = _buildCell(context, entries);
    if (data.onDropRecipe == null || !data.interactive) return cell;
    return DragTarget<RecipeSummary>(
      onAcceptWithDetails: (details) => data.onDropRecipe!(day, slot, details.data),
      builder: (context, candidates, _) =>
          candidates.isNotEmpty ? const PlanningDropHint(minHeight: 56) : cell,
    );
  }

  Widget _buildCell(BuildContext context, List<MealPlanEntry> entries) {
    final l10n = AppLocalizations.of(context);
    if (entries.isEmpty) {
      if (data.selectMode) {
        return CustomPaint(
          painter: const DashedRRectPainter(color: Color(0xFFE0DACB), radius: 14),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      }
      final enabled = data.interactive && data.onAddToSlot != null;
      return GestureDetector(
        onTap: enabled ? () => data.onAddToSlot!(day, slot) : null,
        child: CustomPaint(
          painter: DashedRRectPainter(
            color: data.readonly ? kPlanningDashDisabled : kPlanningDashIdle,
            radius: 14,
          ),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: data.readonly ? 0.3 : 0.55),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: data.readonly
                  ? const Text(
                      '—',
                      style: TextStyle(color: Color(0xFFB0AB9B), fontSize: 12.5),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add, size: 17, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          l10n.planningAdd,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Color(0xFF8CA47C),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      );
    }

    final first = entries.first;
    final multi = entries.length > 1;
    final checked = data.selectedSlots.contains(_slotKey);

    final content = multi
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final e in entries.take(2))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      MealEntryThumb(entry: e, size: 34, radius: 9),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          mealEntryName(l10n, e),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppFonts.display,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (entries.length > 2)
                Padding(
                  padding: const EdgeInsets.only(left: 43),
                  child: Text(
                    l10n.planningMoreOthers(entries.length - 2),
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFB0862E),
                    ),
                  ),
                ),
            ],
          )
        : Row(
            children: [
              MealEntryThumb(entry: first, size: 46, radius: 11),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mealEntryName(l10n, first),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mealEntryMeta(l10n, first),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (data.selectMode) _SelectCheck(checked: checked, size: 24),
            ],
          );

    return GestureDetector(
      onTap: () {
        if (data.selectMode) {
          data.onToggleSelect?.call(_slotKey);
        } else if (data.onTapSlot != null) {
          data.onTapSlot!(context, day, slot);
        }
      },
      child: Opacity(
        opacity: data.readonly && !data.selectMode ? 0.62 : 1,
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFECEAE3)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withValues(alpha: 0.1),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: content,
            ),
            if (multi)
              Positioned(
                top: 9,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.premiumGold, AppColors.premiumGoldDark],
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    l10n.planningSlotCount(entries.length),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            if (data.selectMode && multi)
              Positioned(bottom: 8, right: 8, child: _SelectCheck(checked: checked, size: 24)),
          ],
        ),
      ),
    );
  }
}

/// État « Déposer ici » d'un créneau survolé pendant le drag (écran 1c).
class PlanningDropHint extends StatelessWidget {
  const PlanningDropHint({super.key, required this.minHeight});

  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CustomPaint(
      painter: const DashedRRectPainter(
        color: AppColors.primary,
        radius: 13,
        strokeWidth: 2.5,
        dash: 7,
        gap: 5,
      ),
      child: Container(
        constraints: BoxConstraints(minHeight: minHeight),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, size: 18, color: AppColors.primary),
            const SizedBox(height: 3),
            Text(
              l10n.planningDropHere.toUpperCase(),
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectCheck extends StatelessWidget {
  const _SelectCheck({required this.checked, this.size = 22});

  final bool checked;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: checked ? AppColors.primary : Colors.white.withValues(alpha: 0.7),
        border: Border.all(
          color: checked ? AppColors.primary : Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.25),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: checked
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
    );
  }
}

/// « LUN » / « MAR » … depuis la locale (design 1a).
String shortWeekday(String locale, DateTime date) {
  final raw = DateFormat.E(locale).format(date).replaceAll('.', '');
  return (raw.length > 3 ? raw.substring(0, 3) : raw).toUpperCase();
}

/// « Lundi » / « Mardi » … capitalisé (design 1b).
String longWeekday(String locale, DateTime date) {
  final raw = DateFormat.EEEE(locale).format(date);
  return raw.isEmpty ? raw : raw[0].toUpperCase() + raw.substring(1);
}
