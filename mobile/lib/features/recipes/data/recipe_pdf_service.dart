import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/i18n/generated/app_localizations.dart';
import '../../ingredients/domain/ingredient.dart';
import '../../ingredients/presentation/widgets/unit_selector.dart';
import '../domain/recipe.dart';

/// Génère un PDF imprimable d'une fiche recette, fidèle à la maquette « Recette
/// Web » : feuille A4 deux colonnes — en-tête (titre + photo), bandeau méta
/// (personnes / prépa / cuisson / repos), puis ingrédients à gauche (cases à
/// cocher) et préparation à droite (étapes numérotées + bannières).
///
/// Exclut volontairement les notions personne / dossier / tag : une fiche ne
/// montre que la recette elle-même. La maquette affiche aussi une tuile
/// « Difficulté » et un encart « Astuce » — absents du modèle de données, ils
/// sont remplacés par « Repos » et omis (cf. docs/features/partage-recette.md).
class RecipePdfService {
  RecipePdfService();

  // --- palette (design system) ---------------------------------------
  static final _ink = PdfColor.fromHex('1F2933');
  static final _stepText = PdfColor.fromHex('33404B');
  static final _muted = PdfColor.fromHex('9CA3AF');
  static final _label = PdfColor.fromHex('A79F8B');
  static final _green = PdfColor.fromHex('6B8E5A');
  static final _greenTint = PdfColor.fromHex('EFF3EC');
  static final _greenDark = PdfColor.fromHex('4B6340');
  static final _pill = PdfColor.fromHex('F1EEE4');
  static final _checkbox = PdfColor.fromHex('D8D2C4');
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

    final doc = pw.Document(title: detail.name, author: 'Cocotte Minute');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(40, 40, 40, 24),
        theme: pw.ThemeData.withFont(base: _body!, bold: _body!),
        footer: (context) => _footer(context, l10n),
        build: (context) => [
          _header(detail, l10n, photo),
          pw.SizedBox(height: 24),
          _metaRow(detail, l10n),
          pw.SizedBox(height: 28),
          // Deux colonnes qui paginent (Partitions = SpanningWidget) : ingrédients
          // étroits à gauche, préparation large à droite.
          pw.Partitions(
            children: [
              pw.Partition(
                width: 185,
                child: _ingredientsColumn(detail, l10n),
              ),
              // Gouttière (Partition exige un SpanningWidget : Column vide).
              pw.Partition(width: 28, child: pw.Column(children: const [])),
              pw.Partition(child: _stepsColumn(detail, l10n)),
            ],
          ),
          if (detail.components.isNotEmpty) ...[
            pw.SizedBox(height: 26),
            _components(detail, l10n),
          ],
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
      return null; // hors ligne / erreur : on retombe sur un bloc coloré.
    }
  }

  // --- en-tête (titre + photo) ---------------------------------------

  pw.Widget _header(
    RecipeDetail detail,
    AppLocalizations l10n,
    pw.ImageProvider? photo,
  ) {
    final description = (detail.description ?? '').trim();
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                (detail.isBase ? l10n.pdfBaseBadge : l10n.pdfRecipeBadge)
                    .toUpperCase(),
                style: pw.TextStyle(
                  font: _body,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _green,
                  letterSpacing: 1.6,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                detail.name,
                style: pw.TextStyle(
                  font: _display,
                  fontSize: 28,
                  color: _ink,
                  letterSpacing: -0.6,
                ),
              ),
              if (description.isNotEmpty) ...[
                pw.SizedBox(height: 12),
                pw.Text(
                  description,
                  style: pw.TextStyle(
                    font: _body,
                    fontSize: 11.5,
                    lineSpacing: 3,
                    color: PdfColor.fromHex('6B7280'),
                  ),
                ),
              ],
            ],
          ),
        ),
        pw.SizedBox(width: 26),
        pw.Container(
          width: 176,
          height: 132,
          decoration: pw.BoxDecoration(
            color: photo == null ? _greenTint : null,
            borderRadius: pw.BorderRadius.circular(16),
            image: photo != null
                ? pw.DecorationImage(image: photo, fit: pw.BoxFit.cover)
                : null,
          ),
        ),
      ],
    );
  }

  // --- bandeau méta (personnes / prépa / cuisson / repos) ------------

  pw.Widget _metaRow(RecipeDetail detail, AppLocalizations l10n) {
    final tiles = <pw.Widget>[
      _metaTile('${detail.summary.servings}', l10n.recipeFieldServings),
    ];
    final prep = _duration(detail.summary.prepTime);
    final cook = _duration(detail.summary.cookTime);
    final rest = _duration(detail.summary.restTime);
    if (prep != null) tiles.add(_metaTile(prep, l10n.pdfMetaPrep));
    if (cook != null) tiles.add(_metaTile(cook, l10n.pdfMetaCook));
    if (rest != null) tiles.add(_metaTile(rest, l10n.pdfMetaRest));

    final cells = <pw.Widget>[];
    for (var i = 0; i < tiles.length; i++) {
      if (i > 0) {
        cells.add(pw.Container(width: 1, height: 40, color: _cardBorder));
      }
      cells.add(pw.Expanded(child: tiles[i]));
    }

    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _white,
        borderRadius: pw.BorderRadius.circular(16),
        border: pw.Border.all(color: _cardBorder),
      ),
      child: pw.Row(children: cells),
    );
  }

  pw.Widget _metaTile(String value, String label) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 15, vertical: 13),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(font: _display, fontSize: 16, color: _ink),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label.toUpperCase(),
          style: pw.TextStyle(
            font: _body,
            fontSize: 8.5,
            fontWeight: pw.FontWeight.bold,
            color: _label,
            letterSpacing: 0.5,
          ),
        ),
      ],
    ),
  );

  // --- ingrédients (colonne gauche) ----------------------------------

  pw.Column _ingredientsColumn(RecipeDetail detail, AppLocalizations l10n) {
    final lines = detail.ingredients;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionHeader(l10n.pdfSectionIngredients, lines.length),
        if (lines.isEmpty)
          pw.Text(
            l10n.pdfNoIngredients,
            style: pw.TextStyle(font: _body, fontSize: 11.5, color: _muted),
          )
        else
          for (final line in lines) _ingredientCheckRow(line, l10n),
      ],
    );
  }

  pw.Widget _ingredientCheckRow(
    RecipeIngredientLine line,
    AppLocalizations l10n,
  ) {
    final unit = IngredientUnit.fromWire(line.unit);
    final qty = formatQuantityWithUnit(l10n, line.quantity, unit);
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 11),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 11,
            height: 11,
            margin: const pw.EdgeInsets.only(top: 1.5),
            decoration: pw.BoxDecoration(
              borderRadius: pw.BorderRadius.circular(3),
              border: pw.Border.all(color: _checkbox, width: 1.2),
            ),
          ),
          pw.SizedBox(width: 9),
          pw.Expanded(
            child: pw.RichText(
              text: pw.TextSpan(
                style: pw.TextStyle(font: _body, fontSize: 11.5, lineSpacing: 2),
                children: [
                  pw.TextSpan(
                    text: qty,
                    style: pw.TextStyle(
                      font: _body,
                      fontWeight: pw.FontWeight.bold,
                      color: _greenDark,
                    ),
                  ),
                  pw.TextSpan(
                    text: ' ${line.name}',
                    style: pw.TextStyle(font: _body, color: _ink),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- préparation (colonne droite) ----------------------------------

  pw.Column _stepsColumn(RecipeDetail detail, AppLocalizations l10n) {
    final steps = detail.steps;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionHeader(l10n.pdfSectionSteps, steps.length),
        if (steps.isEmpty)
          pw.Text(
            l10n.pdfNoSteps,
            style: pw.TextStyle(font: _body, fontSize: 11.5, color: _muted),
          )
        else
          for (var i = 0; i < steps.length; i++) ...[
            _stepRow(i + 1, steps[i], l10n),
            if (i != steps.length - 1) pw.SizedBox(height: 16),
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
              fontSize: 12,
              lineSpacing: 3,
              color: _stepText,
            ),
          ),
          if (banner != null) ...[
            pw.SizedBox(height: 9),
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
        pw.SizedBox(width: 13),
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
        PdfColor.fromHex('FBF1DE'),
        PdfColor.fromHex('F1DFB8'),
        PdfColor.fromHex('8A5A12'),
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
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: pw.BorderRadius.circular(11),
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

  // --- sous-recettes (pleine largeur, sous les colonnes) -------------

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
        pw.SizedBox(height: 12),
        for (final c in detail.components)
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
                        style: pw.TextStyle(
                          font: _body,
                          fontSize: 12.5,
                          fontWeight: pw.FontWeight.bold,
                          color: _ink,
                        ),
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
    );
  }

  // --- primitives -----------------------------------------------------

  /// Titre de section (colonne) : nom + compteur + filet vert, façon maquette.
  pw.Widget _sectionHeader(String title, int count) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(font: _display, fontSize: 18, color: _ink),
          ),
          pw.SizedBox(width: 7),
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 2),
            child: pw.Text(
              '$count',
              style: pw.TextStyle(font: _body, fontSize: 11, color: _muted),
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 10),
      pw.Container(
        width: 30,
        height: 3,
        decoration: pw.BoxDecoration(
          color: _green,
          borderRadius: pw.BorderRadius.circular(2),
        ),
      ),
      pw.SizedBox(height: 15),
    ],
  );

  pw.Widget _sectionTitle(String text) => pw.Text(
    text,
    style: pw.TextStyle(font: _display, fontSize: 17, color: _ink),
  );

  pw.Widget _numberBadge(String n) => pw.Container(
    width: 28,
    height: 28,
    decoration: pw.BoxDecoration(color: _ink, shape: pw.BoxShape.circle),
    child: pw.Center(
      child: pw.Text(
        n,
        style: pw.TextStyle(
          font: _display,
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
          color: _white,
        ),
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
        style: pw.TextStyle(
          font: _body,
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromHex('5A6B4E'),
        ),
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
    padding: const pw.EdgeInsets.only(top: 8),
    decoration: pw.BoxDecoration(
      border: pw.Border(top: pw.BorderSide(color: _cardBorder)),
    ),
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
