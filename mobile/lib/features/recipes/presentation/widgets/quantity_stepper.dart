import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../ingredients/domain/ingredient.dart';
import '../../../ingredients/presentation/widgets/unit_selector.dart';

const Color _kStepperBg = Color(0xFFF3F1EA);

/// Stepper de quantité : −/+ par pas dépendant de l'unité (jamais 1 par 1 sur
/// les petites unités), et saisie clavier décimale en touchant le nombre.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.unit,
    required this.onChanged,
  });

  final double quantity;
  final IngredientUnit unit;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final step = unit.quantityStep;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _kStepperBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            // Blanc + ombre légère, comme la maquette (bouton "moins").
            background: Colors.white,
            foreground: AppColors.textPrimary,
            elevated: true,
            onTap: () {
              final next = quantity - step;
              onChanged(next < step ? step : _round(next));
            },
          ),
          GestureDetector(
            onTap: () async {
              final value = await promptQuantity(
                context,
                current: quantity,
                unit: unit,
              );
              if (value != null) onChanged(value);
            },
            child: Container(
              constraints: const BoxConstraints(minWidth: 52),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text.rich(
                TextSpan(
                  text: formatQuantity(quantity),
                  children: [
                    TextSpan(
                      text: ' ${unitShort(l10n, unit)}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            background: AppColors.primary,
            foreground: Colors.white,
            onTap: () => onChanged(_round(quantity + step)),
          ),
        ],
      ),
    );
  }

  // Évite les artefacts flottants (0.30000000000001) après addition de pas.
  double _round(double v) => (v * 100).round() / 100;
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.elevated = false,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(9),
      elevation: elevated ? 1 : 0,
      shadowColor: AppColors.textPrimary.withValues(alpha: 0.2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: SizedBox(
          width: 30,
          height: 30,
          child: Icon(icon, size: 18, color: foreground),
        ),
      ),
    );
  }
}

/// Saisie clavier d'une quantité décimale (touche le nombre du stepper).
Future<double?> promptQuantity(
  BuildContext context, {
  required double current,
  required IngredientUnit unit,
}) {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController(text: formatQuantity(current));
  return showDialog<double>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l10n.recipeIngredientQuantityTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          decoration: InputDecoration(
            suffixText: unitShort(l10n, unit),
            filled: true,
            fillColor: AppColors.card,
            enabledBorder: _dialogBorder(AppColors.border),
            focusedBorder: _dialogBorder(AppColors.primary),
          ),
          onSubmitted: (_) => _submit(dialogContext, controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => _submit(dialogContext, controller.text),
            child: Text(l10n.commonSave),
          ),
        ],
      );
    },
  );
}

void _submit(BuildContext context, String raw) {
  final value = double.tryParse(raw.trim().replaceAll(',', '.'));
  if (value == null || value <= 0) {
    Navigator.of(context).pop();
    return;
  }
  Navigator.of(context).pop((value * 100).round() / 100);
}

OutlineInputBorder _dialogBorder(Color color) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(12),
  borderSide: BorderSide(color: color),
);
