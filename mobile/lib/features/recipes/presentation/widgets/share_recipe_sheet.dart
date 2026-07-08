import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/recipe_pdf_service.dart';
import '../../data/recipes_repository.dart';
import '../../domain/recipe.dart';

/// Ouvre la feuille modale « Partager la recette » (export PDF A4, copie du lien
/// de partage public, partage du lien via la feuille OS). Fidèle au design validé.
Future<void> showShareRecipeSheet(BuildContext context, RecipeDetail detail) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _ShareRecipeSheet(detail: detail),
  );
}

class _ShareRecipeSheet extends StatefulWidget {
  const _ShareRecipeSheet({required this.detail});

  final RecipeDetail detail;

  @override
  State<_ShareRecipeSheet> createState() => _ShareRecipeSheetState();
}

class _ShareRecipeSheetState extends State<_ShareRecipeSheet> {
  bool _busy = false;

  RecipesRepository get _repo => sl<RecipesRepository>();

  Future<void> _exportPdf() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      final bytes = await RecipePdfService().build(widget.detail, l10n);
      final safeName =
          widget.detail.name.replaceAll(RegExp(r'[^\w\s-]'), ' ').trim();
      navigator.pop();
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'Cocotte Minute - $safeName.pdf',
      );
    } catch (_) {
      if (mounted) setState(() => _busy = false);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.pdfExportError)));
    }
  }

  Future<void> _copyLink() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      final url = await _repo.createShareLink(widget.detail.id);
      await Clipboard.setData(ClipboardData(text: url));
      navigator.pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.shareCopyLinkDone)));
    } catch (e) {
      if (mounted) setState(() => _busy = false);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(_errorMessage(e, l10n))));
    }
  }

  Future<void> _shareLink() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      final url = await _repo.createShareLink(widget.detail.id);
      navigator.pop();
      await SharePlus.instance.share(
        ShareParams(text: url, subject: widget.detail.name),
      );
    } catch (e) {
      if (mounted) setState(() => _busy = false);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(_errorMessage(e, l10n))));
    }
  }

  String _errorMessage(Object e, AppLocalizations l10n) =>
      e is RecipesRepositoryException ? e.message : l10n.shareLinkError;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(14),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                l10n.shareRecipeTitle,
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                widget.detail.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 8),
            if (_busy)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            _sectionLabel(l10n.shareSectionExport),
            _card([
              _ShareRow(
                icon: Icons.picture_as_pdf_outlined,
                iconColor: AppColors.accent,
                iconBackground: AppColors.accentTint,
                title: l10n.pdfExportAction,
                subtitle: l10n.shareExportPdfSubtitle,
                onTap: _busy ? null : _exportPdf,
              ),
            ]),
            const SizedBox(height: 6),
            _sectionLabel(l10n.shareSectionShare),
            _card([
              _ShareRow(
                icon: Icons.link_rounded,
                iconColor: AppColors.primary,
                iconBackground: AppColors.primaryTint,
                title: l10n.shareCopyLink,
                subtitle: l10n.shareCopyLinkSubtitle,
                onTap: _busy ? null : _copyLink,
              ),
              const Divider(height: 1, color: AppColors.border, indent: 62),
              _ShareRow(
                icon: Icons.ios_share_rounded,
                iconColor: AppColors.primary,
                iconBackground: AppColors.primaryTint,
                title: l10n.shareVia,
                subtitle: l10n.shareViaSubtitle,
                onTap: _busy ? null : _shareLink,
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.7,
        color: AppColors.textMuted,
      ),
    ),
  );

  Widget _card(List<Widget> children) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: children),
  );
}

class _ShareRow extends StatelessWidget {
  const _ShareRow({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
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
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.divider,
            ),
          ],
        ),
      ),
    );
  }
}
