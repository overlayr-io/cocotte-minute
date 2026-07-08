import 'package:flutter/material.dart';

import '../../../../../core/i18n/generated/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';

/// Dialog de réglage du minuteur (maquette 10f) : durée détectée dans le
/// texte de l'étape (pré-remplie mais ajustable), ou saisie manuelle via les
/// raccourcis 5/10/15/20 min ou les boutons +/-.
///
/// Retourne la durée choisie si l'utilisateur confirme, `null` sinon.
Future<Duration?> showTimerSheet(
  BuildContext context, {
  required Duration? detected,
  String? detectedText,
}) {
  return showDialog<Duration>(
    context: context,
    builder: (_) => TimerSheet(detected: detected, detectedText: detectedText),
  );
}

class TimerSheet extends StatefulWidget {
  const TimerSheet({super.key, this.detected, this.detectedText});

  final Duration? detected;
  final String? detectedText;

  @override
  State<TimerSheet> createState() => _TimerSheetState();
}

class _TimerSheetState extends State<TimerSheet> {
  static const _quickPicks = [
    Duration(minutes: 5),
    Duration(minutes: 10),
    Duration(minutes: 15),
    Duration(minutes: 20),
  ];

  late Duration _selected = widget.detected ?? const Duration(minutes: 10);

  void _adjust(int minutesDelta) {
    setState(() {
      final next = _selected + Duration(minutes: minutesDelta);
      _selected = next.inMinutes < 1 ? const Duration(minutes: 1) : next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final minutes = _selected.inMinutes.remainder(60).toString().padLeft(2, '0');
    final hours = _selected.inHours;
    final display = hours > 0 ? '$hours:$minutes:00' : '$minutes:00';

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.detected != null && widget.detectedText != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBF1DE),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFF1DFB8)),
                ),
                child: Text(
                  l10n.playerTimerSheetDetected(widget.detectedText!),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF9A7327),
                  ),
                ),
              ),
            const SizedBox(height: 14),
            Text(
              l10n.playerTimerSheetTitle,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RoundButton(icon: Icons.remove_rounded, onTap: () => _adjust(-1)),
                SizedBox(
                  width: 140,
                  child: Text(
                    display,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontWeight: FontWeight.w700,
                      fontSize: 44,
                      color: AppColors.textPrimary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                _RoundButton(
                  icon: Icons.add_rounded,
                  filled: true,
                  onTap: () => _adjust(1),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final pick in _quickPicks)
                  _QuickPickChip(
                    duration: pick,
                    selected: _selected == pick,
                    onTap: () => setState(() => _selected = pick),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(l10n.playerTimerSheetCancel),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(_selected),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.timerAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    label: Text(l10n.playerTimerSheetStart),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap, this.filled = false});

  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.primaryTint : AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: filled ? AppColors.primary : AppColors.border, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          width: 52,
          height: 52,
          child: Icon(
            icon,
            size: 22,
            color: filled ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _QuickPickChip extends StatelessWidget {
  const _QuickPickChip({
    required this.duration,
    required this.selected,
    required this.onTap,
  });

  final Duration duration;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.textPrimary : AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(color: selected ? AppColors.textPrimary : AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          child: Text(
            '${duration.inMinutes} min',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
