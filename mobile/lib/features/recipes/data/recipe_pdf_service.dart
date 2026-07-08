import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/i18n/generated/app_localizations.dart';
import '../../ingredients/domain/ingredient.dart';
import '../../ingredients/presentation/widgets/unit_selector.dart';
import '../domain/recipe.dart';

/// Génère un PDF imprimable d'une fiche recette, fidèle au design Cocotte
/// Minute (hero, ingrédients, étapes numérotées, bannières, sous-recettes).
///
/// Exclut volontairement les notions personne / dossier / tag : une fiche ne
/// montre que la recette elle-même.
class RecipePdfService {
  RecipePdfService();

  // --- palette (design system) ---------------------------------------
  static final _ink = PdfColor.fromHex('1F2933');
  static final _stepText = PdfColor.fromHex('374151');
  static final _qty = PdfColor.fromHex('4B5563');
  static final _muted = PdfColor.fromHex('9CA3AF');
  static final _green = PdfColor.fromHex('6B8E5A');
  static final _greenTint = PdfColor.fromHex('EFF3EC');
  static final _greenDark = PdfColor.fromHex('4B6340');
  static final _surface = PdfColor.fromHex('F7F6F2');
  static final _pill = PdfColor.fromHex('F1EEE4');
  static final _separator = PdfColor.fromHex('EAE7DE');
  static final _cardBorder = PdfColor.fromHex('ECEAE3');
  static final _white = PdfColors.white;

  // Cache des polices (variable = un seul master, réutilisé titres + corps).
  static pw.Font? _display;
  static pw.Font? _body;

  Future<Uint8List> build(RecipeDetail detail, AppLocalizations l10n) async {
    _display ??= pw.Font.ttf(
      await rootBundle.load('assets/fonts/BricolageGrotesque-Variable.ttf'),
    );
    _body ??= pw.Font.ttf(
      await rootBundle.load('assets/fonts/HankenGrotesk-Variable.ttf'),
    );

    final photo = await _loadPhoto(detail.summary.photoUrl);

    final doc = pw.Document(
      title: detail.name,
      author: 'Cocotte Minute',
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        theme: pw.ThemeData.withFont(base: _body!, bold: _body!),
        footer: (context) => _footer(context, l10n),
        build: (context) => [
          _hero(detail, l10n, photo),
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(40, 22, 40, 8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if ((detail.description ?? '').trim().isNotEmpty) ...[
                  pw.Text(
                    detail.description!.trim(),
                    style: pw.TextStyle(
                      font: _body,
                      fontSize: 12,
                      lineSpacing: 3,
                      color: PdfColor.fromHex('6B7280'),
                    ),
                  ),
                  pw.SizedBox(height: 18),
                ],
                _servingsLine(detail, l10n),
                pw.SizedBox(height: 22),
                _ingredients(detail, l10n),
                pw.SizedBox(height: 24),
                _steps(detail, l10n),
                if (detail.components.isNotEmpty) ...[
                  pw.SizedBox(height: 24),
                  _components(detail, l10n),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  Future<pw.ImageProvider?> _loadPhoto(String? url) async {
    if (url == null || url.isEmpty) return null;
    try {
      return await networkImage(url);
    } catch (_) {
      return null; // hors ligne / erreur : on retombe sur le bandeau coloré.
    }
  }

  // --- hero -----------------------------------------------------------

  pw.Widget _hero(
    RecipeDetail detail,
    AppLocalizations l10n,
    pw.ImageProvider? photo,
  ) {
    final overlay = pw.Container(
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          begin: pw.Alignment.topCenter,
          end: pw.Alignment.bottomCenter,
          colors: [
            PdfColor(0.12, 0.16, 0.20, 0.0),
            PdfColor(0.12, 0.16, 0.20, 0.0),
            PdfColor(0.12, 0.16, 0.20, 0.82),
          ],
          stops: const [0.0, 0.34, 1.0],
        ),
      ),
    );

    return pw.Container(
      height: 250,
      width: double.infinity,
      decoration: pw.BoxDecoration(
        color: photo == null ? _green : null,
        image: photo != null
            ? pw.DecorationImage(image: photo, fit: pw.BoxFit.cover)
            : null,
      ),
      child: pw.Stack(
        children: [
          pw.Positioned.fill(child: overlay),
          pw.Padding(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                _typeBadge(detail, l10n),
                pw.SizedBox(height: 10),
                pw.Text(
                  detail.name,
                  style: pw.TextStyle(
                    font: _display,
                    fontSize: 30,
                    color: _white,
                    letterSpacing: -0.5,
                  ),
                ),
                pw.SizedBox(height: 8),
                _metaTimes(detail, l10n),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _typeBadge(RecipeDetail detail, AppLocalizations l10n) {
    if (detail.isBase) {
      return _pillWidget(
        l10n.pdfBaseBadge,
        bg: _green,
        fg: _white,
      );
    }
    return _pillWidget(
      l10n.pdfRecipeBadge,
      bg: PdfColor(1, 1, 1, 0.92),
      fg: _ink,
    );
  }

  pw.Widget _metaTimes(RecipeDetail detail, AppLocalizations l10n) {
    final parts = <String>[];
    final prep = _duration(detail.summary.prepTime);
    final cook = _duration(detail.summary.cookTime);
    final rest = _duration(detail.summary.restTime);
    if (prep != null) parts.add(l10n.pdfPrep(prep));
    if (cook != null) parts.add(l10n.pdfCook(cook));
    if (rest != null) parts.add(l10n.pdfRest(rest));
    if (parts.isEmpty) return pw.SizedBox();
    return pw.Text(
      parts.join('   ·   '),
      style: pw.TextStyle(font: _body, fontSize: 12, color: _white),
    );
  }

  // --- portions -------------------------------------------------------

  pw.Widget _servingsLine(RecipeDetail detail, AppLocalizations l10n) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: pw.BoxDecoration(
        color: _surface,
        borderRadius: pw.BorderRadius.circular(14),
        border: pw.Border.all(color: _cardBorder),
      ),
      child: pw.Row(
        children: [
          pw.Text(
            '${detail.summary.servings}',
            style: pw.TextStyle(font: _display, fontSize: 20, color: _green),
          ),
          pw.SizedBox(width: 8),
          pw.Text(
            l10n.pdfServingsSuffix(detail.summary.servings),
            style: pw.TextStyle(font: _body, fontSize: 13, color: _qty),
          ),
        ],
      ),
    );
  }

  // --- ingrédients ----------------------------------------------------

  pw.Widget _ingredients(RecipeDetail detail, AppLocalizations l10n) {
    final lines = detail.ingredients;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle(l10n.pdfSectionIngredients),
        pw.SizedBox(height: 10),
        if (lines.isEmpty)
          pw.Text(
            l10n.pdfNoIngredients,
            style: pw.TextStyle(font: _body, fontSize: 12, color: _muted),
          )
        else
          for (var i = 0; i < lines.length; i++)
            _ingredientRow(lines[i], l10n, last: i == lines.length - 1),
      ],
    );
  }

  pw.Widget _ingredientRow(
    RecipeIngredientLine line,
    AppLocalizations l10n, {
    required bool last,
  }) {
    final unit = IngredientUnit.fromWire(line.unit);
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 9),
      decoration: pw.BoxDecoration(
        border: last
            ? null
            : pw.Border(bottom: pw.BorderSide(color: _separator)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            width: 8,
            height: 8,
            decoration: pw.BoxDecoration(color: _green, shape: pw.BoxShape.circle),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Text(
              line.name,
              style: pw.TextStyle(font: _body, fontSize: 12.5, color: _ink),
            ),
          ),
          pw.Text(
            formatQuantityWithUnit(l10n, line.quantity, unit),
            style: pw.TextStyle(
              font: _body,
              fontSize: 12.5,
              fontWeight: pw.FontWeight.bold,
              color: _qty,
            ),
          ),
        ],
      ),
    );
  }

  // --- étapes ---------------------------------------------------------

  pw.Widget _steps(RecipeDetail detail, AppLocalizations l10n) {
    final steps = detail.steps;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle(l10n.pdfSectionSteps),
        pw.SizedBox(height: 12),
        if (steps.isEmpty)
          pw.Text(
            l10n.pdfNoSteps,
            style: pw.TextStyle(font: _body, fontSize: 12, color: _muted),
          )
        else
          for (var i = 0; i < steps.length; i++) ...[
            _stepRow(i + 1, steps[i], l10n),
            if (i != steps.length - 1) pw.SizedBox(height: 14),
          ],
      ],
    );
  }

  pw.Widget _stepRow(int number, RecipeStep step, AppLocalizations l10n) {
    final content = switch (step) {
      RecipeTextStep(:final description, :final banner) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              description,
              style: pw.TextStyle(
                font: _body,
                fontSize: 12.5,
                lineSpacing: 3,
                color: _stepText,
              ),
            ),
            if (banner != null) ...[
              pw.SizedBox(height: 10),
              _banner(banner, l10n),
            ],
          ],
        ),
      RecipeBaseRefStep(:final baseRecipeName, :final steps) =>
        _baseRefBlock(baseRecipeName, steps, l10n),
    };

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _numberBadge('$number'),
        pw.SizedBox(width: 12),
        pw.Expanded(child: content),
      ],
    );
  }

  pw.Widget _baseRefBlock(
    String name,
    List<ExpandedStep> subSteps,
    AppLocalizations l10n,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('F7FAF5'),
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColor.fromHex('CBD5C0')),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  name,
                  style: pw.TextStyle(
                    font: _display,
                    fontSize: 13,
                    color: _greenDark,
                  ),
                ),
              ),
              _pillWidget(l10n.pdfRefBadge, bg: _greenTint, fg: _green, small: true),
            ],
          ),
          for (var i = 0; i < subSteps.length; i++) ...[
            pw.SizedBox(height: 8),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _letterBadge(String.fromCharCode(97 + i)),
                pw.SizedBox(width: 9),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        subSteps[i].description,
                        style: pw.TextStyle(
                          font: _body,
                          fontSize: 11.5,
                          lineSpacing: 2,
                          color: PdfColor.fromHex('5A6B4E'),
                        ),
                      ),
                      if (subSteps[i].banner != null) ...[
                        pw.SizedBox(height: 6),
                        _banner(subSteps[i].banner!, l10n),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _banner(StepBanner banner, AppLocalizations l10n) {
    final (bg, border, fg, label) = switch (banner.type) {
      StepBannerType.info => (
          PdfColor.fromHex('EAF0F5'),
          PdfColor.fromHex('D8E4EE'),
          PdfColor.fromHex('2C5A82'),
          l10n.pdfBannerTip,
        ),
      StepBannerType.warning => (
          PdfColor.fromHex('FEF6E7'),
          PdfColor.fromHex('F7E6C0'),
          PdfColor.fromHex('8A5A00'),
          l10n.pdfBannerWarning,
        ),
      StepBannerType.danger => (
          PdfColor.fromHex('FBEAEA'),
          PdfColor.fromHex('F5D0D0'),
          PdfColor.fromHex('9B3838'),
          l10n.pdfBannerDanger,
        ),
      StepBannerType.learn => (
          PdfColor.fromHex('F7FAF5'),
          PdfColor.fromHex('CBD5C0'),
          _greenDark,
          l10n.pdfBannerLearn,
        ),
    };
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: border),
      ),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label — ',
              style: pw.TextStyle(
                font: _body,
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: fg,
              ),
            ),
            pw.TextSpan(
              text: banner.text,
              style: pw.TextStyle(
                font: _body,
                fontSize: 11,
                lineSpacing: 2,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- sous-recettes --------------------------------------------------

  pw.Widget _components(RecipeDetail detail, AppLocalizations l10n) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            _sectionTitle(l10n.pdfSectionSubRecipes),
            pw.SizedBox(width: 8),
            _pillWidget('${detail.components.length}',
                bg: _greenTint, fg: _green, small: true),
          ],
        ),
        pw.SizedBox(height: 10),
        for (final c in detail.components) ...[
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 8),
            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: pw.BoxDecoration(
              color: _white,
              borderRadius: pw.BorderRadius.circular(14),
              border: pw.Border.all(color: _cardBorder),
            ),
            child: pw.Row(
              children: [
                pw.Container(
                  width: 34,
                  height: 34,
                  decoration: pw.BoxDecoration(
                    color: _pill,
                    borderRadius: pw.BorderRadius.circular(11),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      c.name.isNotEmpty ? c.name.substring(0, 1).toUpperCase() : '?',
                      style: pw.TextStyle(font: _display, fontSize: 15, color: _green),
                    ),
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        c.name,
                        style: pw.TextStyle(font: _body, fontSize: 12.5, fontWeight: pw.FontWeight.bold, color: _ink),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        l10n.pdfBaseBadge,
                        style: pw.TextStyle(font: _body, fontSize: 10, color: _green),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // --- primitives -----------------------------------------------------

  pw.Widget _sectionTitle(String text) => pw.Text(
        text,
        style: pw.TextStyle(font: _display, fontSize: 17, color: _ink),
      );

  pw.Widget _numberBadge(String n) => pw.Container(
        width: 26,
        height: 26,
        decoration: pw.BoxDecoration(color: _green, shape: pw.BoxShape.circle),
        child: pw.Center(
          child: pw.Text(
            n,
            style: pw.TextStyle(font: _body, fontSize: 12, fontWeight: pw.FontWeight.bold, color: _white),
          ),
        ),
      );

  pw.Widget _letterBadge(String letter) => pw.Container(
        width: 20,
        height: 20,
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('DCE6D3'),
          shape: pw.BoxShape.circle,
        ),
        child: pw.Center(
          child: pw.Text(
            letter,
            style: pw.TextStyle(font: _body, fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('5A6B4E')),
          ),
        ),
      );

  pw.Widget _pillWidget(
    String text, {
    required PdfColor bg,
    required PdfColor fg,
    bool small = false,
  }) =>
      pw.Container(
        padding: pw.EdgeInsets.symmetric(
          horizontal: small ? 8 : 11,
          vertical: small ? 3 : 5,
        ),
        decoration: pw.BoxDecoration(
          color: bg,
          borderRadius: pw.BorderRadius.circular(999),
        ),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            font: _body,
            fontSize: small ? 9 : 11,
            fontWeight: pw.FontWeight.bold,
            color: fg,
          ),
        ),
      );

  pw.Widget _footer(pw.Context context, AppLocalizations l10n) => pw.Container(
        padding: const pw.EdgeInsets.fromLTRB(40, 8, 40, 20),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Cocotte Minute',
              style: pw.TextStyle(font: _display, fontSize: 11, color: _ink),
            ),
            pw.Text(
              '${context.pageNumber} / ${context.pagesCount}',
              style: pw.TextStyle(font: _body, fontSize: 10, color: _muted),
            ),
          ],
        ),
      );

  /// « 90 » → « 1 h 30 », « 45 » → « 45 min », « 0 » → null.
  String? _duration(int minutes) {
    if (minutes <= 0) return null;
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h h' : '$h h $m';
  }
}
