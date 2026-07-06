import 'package:flutter/material.dart';

import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/ingredient.dart';

/// Libellé i18n d'une unité de mesure.
String unitLabel(AppLocalizations l10n, IngredientUnit unit) {
  return switch (unit) {
    IngredientUnit.gramme => l10n.unitGramme,
    IngredientUnit.milligramme => l10n.unitMilligramme,
    IngredientUnit.piece => l10n.unitPiece,
    IngredientUnit.cuillereCafe => l10n.unitCuillereCafe,
    IngredientUnit.cuillereSoupe => l10n.unitCuillereSoupe,
  };
}

/// Sélecteur d'unité sous forme de puces (une seule sélectionnée).
class UnitSelector extends StatelessWidget {
  const UnitSelector({super.key, required this.selected, required this.onChanged});

  final IngredientUnit selected;
  final ValueChanged<IngredientUnit> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final unit in IngredientUnit.values)
          _UnitChip(
            label: unitLabel(l10n, unit),
            selected: unit == selected,
            onTap: () => onChanged(unit),
          ),
      ],
    );
  }
}

class _UnitChip extends StatelessWidget {
  const _UnitChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.card,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
