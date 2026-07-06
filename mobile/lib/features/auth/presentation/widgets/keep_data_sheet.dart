import 'package:flutter/material.dart';

import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// Choix proposé après création du compte, quand des données invité existaient.
enum KeepDataChoice { keep, reset }

/// Ouvre la modal "Compte créé — conserver / repartir" (système 1c de la
/// maquette). Renvoie le choix confirmé, ou `null` si l'utilisateur reporte
/// ("Plus tard" / fermeture).
Future<KeepDataChoice?> showKeepDataSheet(BuildContext context) {
  return showModalBottomSheet<KeepDataChoice>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const _KeepDataSheet(),
  );
}

class _KeepDataSheet extends StatefulWidget {
  const _KeepDataSheet();

  @override
  State<_KeepDataSheet> createState() => _KeepDataSheetState();
}

class _KeepDataSheetState extends State<_KeepDataSheet> {
  KeepDataChoice _selected = KeepDataChoice.keep;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.radioIdle,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.check_rounded, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.keepDataTitle,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.keepDataDescription,
              style: const TextStyle(
                fontSize: 14.5,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            _SelectorGroup(
              child: Column(
                children: [
                  _OptionRow(
                    selected: _selected == KeepDataChoice.keep,
                    title: l10n.keepDataKeepTitle,
                    subtitle: l10n.keepDataKeepSubtitle,
                    badge: l10n.keepDataRecommended,
                    onTap: () =>
                        setState(() => _selected = KeepDataChoice.keep),
                  ),
                  _OptionRow(
                    selected: _selected == KeepDataChoice.reset,
                    title: l10n.keepDataResetTitle,
                    subtitle: l10n.keepDataResetSubtitle,
                    onTap: () =>
                        setState(() => _selected = KeepDataChoice.reset),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 54,
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(_selected),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  l10n.keepDataConfirm,
                  style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  l10n.keepDataLater,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
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

/// Conteneur segmenté beige (système 1c).
class _SelectorGroup extends StatelessWidget {
  const _SelectorGroup({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.pill,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        margin: EdgeInsets.only(bottom: badge != null ? 6 : 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? AppColors.card : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    blurRadius: 0,
                    spreadRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            _Radio(selected: selected),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: selected
                          ? AppColors.textPrimary
                          : const Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.radioIdle,
          width: selected ? 6 : 2,
        ),
      ),
    );
  }
}
