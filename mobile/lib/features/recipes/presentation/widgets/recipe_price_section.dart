import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/pricing/price_calculator.dart';
import '../../../../core/pricing/price_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../ingredient_prices/data/ingredient_prices_repository.dart';
import '../../../ingredient_prices/domain/ingredient_price.dart';
import '../../../ingredients/domain/ingredient.dart';
import '../../domain/recipe.dart';
import '../bloc/recipe_detail_cubit.dart';

const _labelStyle = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w700,
  letterSpacing: 0.5,
  color: AppColors.textMuted,
);

const _bigStyle = TextStyle(
  fontFamily: AppFonts.display,
  fontWeight: FontWeight.w700,
  fontSize: 26,
  color: AppColors.textPrimary,
  letterSpacing: -0.4,
);

const _captionStyle = TextStyle(
  fontSize: 12,
  color: AppColors.textMuted,
  fontWeight: FontWeight.w600,
);

String _bracketLabel(AppLocalizations l10n, RecipePriceBracket bracket) => switch (bracket) {
  RecipePriceBracket.under5 => l10n.recipePriceBracketUnder5,
  RecipePriceBracket.from5To10 => l10n.recipePriceBracketFrom5To10,
  RecipePriceBracket.from10To20 => l10n.recipePriceBracketFrom10To20,
  RecipePriceBracket.over20 => l10n.recipePriceBracketOver20,
};

Future<double?> _promptFixedPrice(
  BuildContext context,
  int servings,
  double? current,
) {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController(
    text: current == null ? '' : formatPrice(current).replaceAll(' €', ''),
  );
  return showDialog<double>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.recipePriceFixedInputLabel),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,]'))],
        decoration: InputDecoration(suffixText: '€ · ${l10n.recipePriceForServings(servings)}'),
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
}

/// Bloc "Prix" de la fiche recette (feature prix-estime), inséré juste après la
/// carte Portions : mode calculé (somme des prix ingrédients, avertissement si
/// partiel) ou étiquette (prix fixe saisi), les deux scalant avec les portions
/// choisies. Badge de tranche de prix affiché dès que le prix est entièrement
/// connu (jamais sur un total partiel).
class RecipePriceSection extends StatefulWidget {
  const RecipePriceSection({
    super.key,
    required this.detail,
    required this.scale,
    required this.chosenServings,
  });

  final RecipeDetail detail;
  final double scale;
  final int chosenServings;

  @override
  State<RecipePriceSection> createState() => _RecipePriceSectionState();
}

class _RecipePriceSectionState extends State<RecipePriceSection> {
  late Future<List<IngredientPrice>> _pricesFuture = _loadPrices();

  @override
  void didUpdateWidget(covariant RecipePriceSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Les ingrédients ont pu changer (ajout/retrait/quantité) : recharge
    // (servi par le cache tant qu'aucun prix ingrédient n'a changé ailleurs).
    if (oldWidget.detail.ingredients != widget.detail.ingredients) {
      _pricesFuture = _loadPrices();
    }
  }

  Future<List<IngredientPrice>> _loadPrices() =>
      sl<IngredientPricesRepository>().fetchMine();

  Future<void> _toggleMode(BuildContext context, RecipePriceMode mode) async {
    final cubit = context.read<RecipeDetailCubit>();
    if (mode == RecipePriceMode.fixed && widget.detail.fixedPrice == null) {
      // Première bascule en étiquette : demande le prix de base tout de suite,
      // sinon la carte n'aurait rien à afficher.
      final value =
          await _promptFixedPrice(context, widget.detail.summary.servings, null);
      if (value == null || !context.mounted) return;
      await cubit.updateFields(priceMode: mode, fixedPrice: value);
    } else {
      await cubit.updateFields(priceMode: mode);
    }
  }

  Future<void> _editFixedPrice(BuildContext context) async {
    final cubit = context.read<RecipeDetailCubit>();
    final value = await _promptFixedPrice(
      context,
      widget.detail.summary.servings,
      widget.detail.fixedPrice,
    );
    if (value == null || !context.mounted) return;
    await cubit.updateFields(priceMode: RecipePriceMode.fixed, fixedPrice: value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detail = widget.detail;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.recipePriceSectionTitle.toUpperCase(), style: _labelStyle),
              _ModeToggle(
                mode: detail.priceMode,
                onChanged: (m) => _toggleMode(context, m),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (detail.priceMode == RecipePriceMode.fixed)
            _FixedPriceContent(
              detail: detail,
              scale: widget.scale,
              chosenServings: widget.chosenServings,
              onTap: () => _editFixedPrice(context),
            )
          else
            FutureBuilder<List<IngredientPrice>>(
              future: _pricesFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(
                    height: 34,
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                final byId = {
                  for (final p in snapshot.data!) p.ingredientId: p,
                };
                final estimate = estimateFromLines(
                  detail.ingredients.map(
                    (line) => (
                      quantity: line.quantity,
                      unit: IngredientUnit.fromWire(line.unit),
                      ingredientId: line.id,
                    ),
                  ),
                  byId,
                );
                return _CalculatedPriceContent(
                  estimate: estimate,
                  scale: widget.scale,
                  chosenServings: widget.chosenServings,
                  bracket: estimate.isPartial ? null : detail.priceBracket,
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});

  final RecipePriceMode mode;
  final ValueChanged<RecipePriceMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: AppColors.pill, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeChip(
            label: l10n.recipePriceModeCalculated,
            selected: mode == RecipePriceMode.calculated,
            onTap: () => onChanged(RecipePriceMode.calculated),
          ),
          _ModeChip(
            label: l10n.recipePriceModeFixed,
            selected: mode == RecipePriceMode.fixed,
            onTap: () => onChanged(RecipePriceMode.fixed),
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _CalculatedPriceContent extends StatelessWidget {
  const _CalculatedPriceContent({
    required this.estimate,
    required this.scale,
    required this.chosenServings,
    required this.bracket,
  });

  final PriceEstimate estimate;
  final double scale;
  final int chosenServings;
  final RecipePriceBracket? bracket;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scaledValue = estimate.value * scale;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    formatPriceEstimate(scaledValue, isPartial: estimate.isPartial),
                    style: _bigStyle,
                  ),
                  if (estimate.isPartial) ...[
                    const SizedBox(width: 8),
                    _WarningIcon(tooltip: l10n.recipePriceMissingTooltip),
                  ],
                ],
              ),
              if (bracket != null) ...[
                const SizedBox(height: 8),
                _BracketBadge(bracket: bracket!),
              ],
            ],
          ),
        ),
        Text(l10n.recipePriceForServings(chosenServings), style: _captionStyle),
      ],
    );
  }
}

class _FixedPriceContent extends StatelessWidget {
  const _FixedPriceContent({
    required this.detail,
    required this.scale,
    required this.chosenServings,
    required this.onTap,
  });

  final RecipeDetail detail;
  final double scale;
  final int chosenServings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final base = detail.fixedPrice;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  base == null ? l10n.recipePriceFixedInputLabel : formatPrice(base * scale),
                  style: _bigStyle,
                ),
                if (base != null && detail.priceBracket != null) ...[
                  const SizedBox(height: 8),
                  _BracketBadge(bracket: detail.priceBracket!),
                ],
              ],
            ),
          ),
          Text(l10n.recipePriceForServings(chosenServings), style: _captionStyle),
        ],
      ),
    );
  }
}

class _WarningIcon extends StatelessWidget {
  const _WarningIcon({required this.tooltip});

  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      triggerMode: TooltipTriggerMode.tap,
      child: Container(
        width: 20,
        height: 20,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFFBF3DE),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFEBD9A8)),
        ),
        child: const Text(
          'i',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.premiumGoldDark,
          ),
        ),
      ),
    );
  }
}

class _BracketBadge extends StatelessWidget {
  const _BracketBadge({required this.bracket});

  final RecipePriceBracket bracket;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _bracketLabel(l10n, bracket),
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primary),
      ),
    );
  }
}
