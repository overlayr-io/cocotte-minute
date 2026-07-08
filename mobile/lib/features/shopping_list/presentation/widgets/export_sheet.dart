import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/shopping_list.dart';
import 'shopping_format.dart';

/// Feuille 5f — exporter la liste : PDF (à venir) ou conversion en note (copie
/// du texte dans le presse-papiers). Le partage direct (lien, réseaux) est hors
/// périmètre v1 : on se limite à l'export.
Future<void> showExportSheet(BuildContext context, ShoppingListDetail detail) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _ExportSheet(detail: detail),
  );
}

class _ExportSheet extends StatelessWidget {
  const _ExportSheet({required this.detail});
  final ShoppingListDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8D3C7),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.shoppingExportTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            _ExportTile(
              icon: Icons.picture_as_pdf_outlined,
              iconColor: const Color(0xFFE1584A),
              iconBg: const Color(0xFFFBE9E6),
              title: l10n.shoppingExportPdf,
              subtitle: l10n.shoppingExportPdfSubtitle,
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.shoppingExportPdfSoon)),
                );
              },
            ),
            const SizedBox(height: 10),
            _ExportTile(
              icon: Icons.sticky_note_2_outlined,
              iconColor: const Color(0xFFB98A3E),
              iconBg: const Color(0xFFF1EAD6),
              title: l10n.shoppingExportNote,
              subtitle: l10n.shoppingExportNoteSubtitle,
              onTap: () async {
                await Clipboard.setData(
                  ClipboardData(text: _asText(l10n)),
                );
                if (!context.mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.shoppingExportCopied)),
                );
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.pill,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 17, color: Color(0xFF8A7A4E)),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      l10n.shoppingExportHint,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Représentation texte de la liste (articles à acheter uniquement).
  String _asText(AppLocalizations l10n) {
    final buffer = StringBuffer()
      ..writeln(detail.list.name)
      ..writeln();
    for (final item in detail.items.where((i) => !i.isChecked)) {
      final qty = shoppingQuantityLabel(l10n, item.quantity, item.unit);
      buffer.writeln(qty.isEmpty ? '- ${item.displayName}' : '- ${item.displayName} · $qty');
    }
    return buffer.toString().trimRight();
  }
}

class _ExportTile extends StatelessWidget {
  const _ExportTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFC4BEAD)),
          ],
        ),
      ),
    );
  }
}
