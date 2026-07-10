import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/pricing/price_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../ingredient_prices/domain/ingredient_price.dart';
import '../../../premium/presentation/pages/premium_page.dart';

String _referenceUnitShort(AppLocalizations l10n, PriceReferenceUnit unit) => switch (unit) {
  PriceReferenceUnit.kilogram => l10n.priceReferenceUnitShortKilogram,
  PriceReferenceUnit.litre => l10n.priceReferenceUnitShortLitre,
  PriceReferenceUnit.piece => l10n.priceReferenceUnitShortPiece,
};

/// Bloc "Prix" de la fiche ingrédient (feature prix-estime, écrans 14b/14c/14d) :
/// champ moyen simple en gratuit (avec fourchette Premium verrouillée en
/// aperçu), règle graduée bas/estimation/haut en premium, état vide tant
/// qu'aucun prix n'est saisi — quel que soit le palier.
class IngredientPriceSection extends StatelessWidget {
  const IngredientPriceSection({
    super.key,
    required this.isPremium,
    required this.revealed,
    required this.referenceUnit,
    required this.averagePrice,
    required this.lowPrice,
    required this.highPrice,
    required this.onReveal,
    required this.onReferenceUnitChanged,
    required this.onAveragePriceChanged,
    required this.onRangeChanged,
  });

  final bool isPremium;

  /// true dès qu'un prix existe déjà, ou que l'utilisateur a tapé "Ajouter un prix".
  final bool revealed;
  final PriceReferenceUnit referenceUnit;
  final double? averagePrice;
  final double? lowPrice;
  final double? highPrice;

  final VoidCallback onReveal;
  final ValueChanged<PriceReferenceUnit> onReferenceUnitChanged;
  final ValueChanged<double?> onAveragePriceChanged;

  /// Bas/haut modifiés (glisser ou saisie précise) : la moyenne est recalculée
  /// à `(bas+haut)/2` par l'appelant à chaque changement, cf. doc prix-estime.
  final void Function(double low, double high, double average) onRangeChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.ingredientPriceSectionTitle.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: AppColors.textMuted,
              ),
            ),
            if (!revealed)
              Text(l10n.ingredientPriceUnknownHint, style: _hintStyle)
            else if (isPremium)
              const _ProBadge()
            else
              Text(l10n.ingredientPriceMineHint, style: _hintStyle),
          ],
        ),
        const SizedBox(height: 12),
        _ReferenceUnitPicker(selected: referenceUnit, onChanged: onReferenceUnitChanged),
        const SizedBox(height: 16),
        if (!revealed)
          _PriceEmptyCard(onAdd: onReveal)
        else if (isPremium)
          _RangeSlider(
            low: lowPrice ?? 0,
            high: highPrice ?? 1,
            average: averagePrice ?? (((lowPrice ?? 0) + (highPrice ?? 1)) / 2),
            unitLabel: _referenceUnitShort(l10n, referenceUnit),
            onChanged: onRangeChanged,
          )
        else ...[
          _AveragePriceField(
            value: averagePrice,
            unitLabel: _referenceUnitShort(l10n, referenceUnit),
            onChanged: onAveragePriceChanged,
          ),
          const SizedBox(height: 14),
          _LockedRangePreview(
            onTap: () => Navigator.of(context).push(PremiumPage.route()),
          ),
        ],
      ],
    );
  }
}

const _hintStyle = TextStyle(
  fontSize: 11.5,
  color: AppColors.textMuted,
  fontWeight: FontWeight.w500,
);

class _ReferenceUnitPicker extends StatelessWidget {
  const _ReferenceUnitPicker({required this.selected, required this.onChanged});

  final PriceReferenceUnit selected;
  final ValueChanged<PriceReferenceUnit> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9A927E),
            ),
            children: [
              TextSpan(text: l10n.ingredientPriceReferenceUnitLabel),
              TextSpan(
                text: ' · ${l10n.ingredientPriceReferenceUnitHint}',
                style: const TextStyle(color: Color(0xFFB7AF9C)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _UnitChip(
                label: l10n.priceReferenceUnitKilogram,
                selected: selected == PriceReferenceUnit.kilogram,
                onTap: () => onChanged(PriceReferenceUnit.kilogram),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _UnitChip(label: l10n.priceReferenceUnitLitre, selected: false, disabled: true),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _UnitChip(
                label: l10n.priceReferenceUnitPiece,
                selected: selected == PriceReferenceUnit.piece,
                onTap: () => onChanged(PriceReferenceUnit.piece),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _UnitChip extends StatelessWidget {
  const _UnitChip({
    required this.label,
    required this.selected,
    this.disabled = false,
    this.onTap,
  });

  final String label;
  final bool selected;
  final bool disabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color textColor = selected
        ? Colors.white
        : disabled
            ? const Color(0xFFC7C1B2)
            : const Color(0xFF5C6470);
    return Material(
      color: selected ? AppColors.primary : AppColors.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppColors.primary : const Color(0xFFE4DFD3)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _AveragePriceField extends StatefulWidget {
  const _AveragePriceField({
    required this.value,
    required this.unitLabel,
    required this.onChanged,
  });

  final double? value;
  final String unitLabel;
  final ValueChanged<double?> onChanged;

  @override
  State<_AveragePriceField> createState() => _AveragePriceFieldState();
}

class _AveragePriceFieldState extends State<_AveragePriceField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value == null ? '' : formatPrice(widget.value!).replaceAll(' €', ''),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.ingredientPriceAverageLabel,
          style: const TextStyle(
            fontSize: 12.5,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 17),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.primary, width: 1.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,]'))],
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (text) => widget.onChanged(parsePriceInput(text)),
                ),
              ),
              Text(
                '€ / ${widget.unitLabel}',
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF8A8574),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LockedRangePreview extends StatelessWidget {
  const _LockedRangePreview({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFECE8DE)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.premiumGold, AppColors.premiumGoldDark],
                  ),
                  boxShadow: AppShadows.glow(AppColors.premiumGoldDark),
                ),
                child: const Icon(Icons.lock_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(height: 9),
              Text(
                l10n.ingredientPriceLockedCta,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.premiumGoldDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriceEmptyCard extends StatelessWidget {
  const _PriceEmptyCard({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFBFAF6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD8D2C4), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1EEE4),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.sell_outlined, color: Color(0xFFB0A88E), size: 21),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.ingredientPriceEmptyTitle,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.ingredientPriceEmptyBody,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFFA79F8B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(l10n.ingredientPriceAddCta, style: const TextStyle(fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF5C7A4C),
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProBadge extends StatelessWidget {
  const _ProBadge();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.premiumGold, AppColors.premiumGoldDark]),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 10, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            l10n.premiumBadge.toUpperCase(),
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Règle graduée bas → estimation → haut (écran 14c). Glisser un point ajuste
/// sa valeur ; un tap ouvre une saisie précise (3 décimales, cf. doc) — le
/// glisser seul ne peut pas garantir cette précision sur un petit écran.
class _RangeSlider extends StatelessWidget {
  const _RangeSlider({
    required this.low,
    required this.high,
    required this.average,
    required this.unitLabel,
    required this.onChanged,
  });

  final double low;
  final double high;
  final double average;
  final String unitLabel;
  final void Function(double low, double high, double average) onChanged;

  double get _axisMax {
    if (high <= 0) return 1;
    final raw = high * 1.4;
    return (raw * 10).ceil() / 10;
  }

  Future<void> _editPrecise(BuildContext context, {required bool isLow}) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(
      text: formatPrice(isLow ? low : high).replaceAll(' €', ''),
    );
    final result = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.ingredientPriceDialogTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,]'))],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(parsePriceInput(controller.text)),
            child: Text(l10n.commonValidate),
          ),
        ],
      ),
    );
    if (result == null || !context.mounted) return;
    if (isLow) {
      if (result > high) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.ingredientPriceRangeInvalid)));
        return;
      }
      final newLow = result < 0 ? 0.0 : result;
      onChanged(newLow, high, (newLow + high) / 2);
    } else {
      if (result < low) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.ingredientPriceRangeInvalid)));
        return;
      }
      onChanged(low, result, (low + result) / 2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.ingredientPriceEstimateLabel,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      formatPrice(average),
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w700,
                        fontSize: 34,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '/ $unitLabel',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF8A8574),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Text(
              l10n.ingredientPriceEstimateFormulaHint,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFFA79F8B),
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final axisMax = _axisMax;
            double xFor(double v) => (v.clamp(0, axisMax) / axisMax) * width;
            double valueFor(double x) => (x / width).clamp(0.0, 1.0) * axisMax;

            void dragHandle(DragUpdateDetails details, {required bool isLow}) {
              final box = context.findRenderObject() as RenderBox;
              final local = box.globalToLocal(details.globalPosition);
              final v = valueFor(local.dx);
              if (isLow) {
                final newLow = v.clamp(0.0, high);
                onChanged(newLow, high, (newLow + high) / 2);
              } else {
                final newHigh = v < low ? low : v;
                onChanged(low, newHigh, (low + newHigh) / 2);
              }
            }

            void dragEstimate(DragUpdateDetails details) {
              final box = context.findRenderObject() as RenderBox;
              final local = box.globalToLocal(details.globalPosition);
              final v = valueFor(local.dx).clamp(low, high);
              onChanged(low, high, v);
            }

            return SizedBox(
              height: 92,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: xFor(average),
                    top: 0,
                    child: FractionalTranslation(
                      translation: const Offset(-0.5, 0),
                      child: _EstimateBubble(value: average),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 36,
                    height: 40,
                    child: _TrackBackground(fillFrom: xFor(low), fillTo: xFor(high)),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 82,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(formatPrice(0), style: _axisLabelStyle),
                        Text(formatPrice(axisMax), style: _axisLabelStyle),
                      ],
                    ),
                  ),
                  Positioned(
                    left: xFor(average),
                    top: 30,
                    child: FractionalTranslation(
                      translation: const Offset(-0.5, 0),
                      child: GestureDetector(
                        onPanUpdate: dragEstimate,
                        child: const _EstimateHandle(),
                      ),
                    ),
                  ),
                  Positioned(
                    left: xFor(low),
                    top: 46,
                    child: FractionalTranslation(
                      translation: const Offset(-0.5, 0),
                      child: GestureDetector(
                        onPanUpdate: (d) => dragHandle(d, isLow: true),
                        child: const _HandleDot(),
                      ),
                    ),
                  ),
                  Positioned(
                    left: xFor(high),
                    top: 46,
                    child: FractionalTranslation(
                      translation: const Offset(-0.5, 0),
                      child: GestureDetector(
                        onPanUpdate: (d) => dragHandle(d, isLow: false),
                        child: const _HandleDot(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _StatBox(
                label: l10n.ingredientPriceLowLabel,
                value: low,
                onTap: () => _editPrecise(context, isLow: true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatBox(
                label: l10n.ingredientPriceHighLabel,
                value: high,
                onTap: () => _editPrecise(context, isLow: false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        _HintBox(text: l10n.ingredientPriceSliderHint),
      ],
    );
  }
}

const _axisLabelStyle = TextStyle(
  fontSize: 10.5,
  color: Color(0xFFB7AF9C),
  fontWeight: FontWeight.w600,
);

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value, required this.onTap});

  final String label;
  final double value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: const Color(0xFFE4DFD3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: Color(0xFF9A927E),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formatPrice(value),
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HintBox extends StatelessWidget {
  const _HintBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EEE4),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFA79F8B)),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, height: 1.45, color: Color(0xFF8A8574)),
            ),
          ),
        ],
      ),
    );
  }
}

class _HandleDot extends StatelessWidget {
  const _HandleDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: AppColors.primary, width: 3),
        boxShadow: const [BoxShadow(color: Color(0x4D1F2933), blurRadius: 8, offset: Offset(0, 3))],
      ),
    );
  }
}

class _EstimateHandle extends StatelessWidget {
  const _EstimateHandle();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 62,
      child: Center(
        child: Container(
          width: 3,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.premiumGold, AppColors.premiumGoldDark],
            ),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}

class _EstimateBubble extends StatelessWidget {
  const _EstimateBubble({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.premiumGold, AppColors.premiumGoldDark]),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            formatPrice(value),
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              color: Colors.white,
            ),
          ),
        ),
        CustomPaint(size: const Size(10, 6), painter: _TrianglePainter(AppColors.premiumGoldDark)),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  _TrianglePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) => oldDelegate.color != color;
}

class _TrackBackground extends StatelessWidget {
  const _TrackBackground({required this.fillFrom, required this.fillTo});

  final double fillFrom;
  final double fillTo;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFEDEAE2),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        Positioned(
          left: fillFrom,
          width: (fillTo - fillFrom).clamp(0, double.infinity),
          top: 0,
          bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ],
    );
  }
}
