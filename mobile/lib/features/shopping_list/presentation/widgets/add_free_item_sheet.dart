import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// Saisie d'un article libre (hors recette).
class FreeItemInput {
  const FreeItemInput({required this.label, this.quantity, this.unit});
  final String label;
  final double? quantity;
  final String? unit;
}

Future<FreeItemInput?> showAddFreeItemSheet(BuildContext context) {
  return showModalBottomSheet<FreeItemInput>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const _AddFreeItemSheet(),
  );
}

class _AddFreeItemSheet extends StatefulWidget {
  const _AddFreeItemSheet();

  @override
  State<_AddFreeItemSheet> createState() => _AddFreeItemSheetState();
}

class _AddFreeItemSheetState extends State<_AddFreeItemSheet> {
  final _label = TextEditingController();
  final _qty = TextEditingController();
  final _unit = TextEditingController();

  @override
  void dispose() {
    _label.dispose();
    _qty.dispose();
    _unit.dispose();
    super.dispose();
  }

  void _submit() {
    final label = _label.text.trim();
    if (label.isEmpty) return;
    final qty = double.tryParse(_qty.text.trim().replaceAll(',', '.'));
    final unit = _unit.text.trim();
    Navigator.of(context).pop(
      FreeItemInput(
        label: label,
        quantity: qty,
        unit: unit.isEmpty ? null : unit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 22,
        right: 22,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
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
            l10n.shoppingAddItemTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _label,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: _dec(l10n.shoppingAddItemHint),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _qty,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: _dec(l10n.shoppingAddItemQtyHint),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _unit,
                  decoration: _dec('g / ml / x'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
              ),
              onPressed: _submit,
              child: Text(l10n.shoppingAddItem),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: AppColors.card,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
  );
}
