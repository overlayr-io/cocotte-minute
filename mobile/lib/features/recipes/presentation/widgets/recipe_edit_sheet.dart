import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/recipe.dart';

/// Valeurs éditées renvoyées par la sheet d'édition de la fiche.
class RecipeEdited {
  const RecipeEdited({
    required this.name,
    required this.description,
    required this.isBase,
    required this.prepTime,
    required this.cookTime,
    required this.restTime,
    required this.servings,
  });

  final String name;
  final String description;
  final bool isBase;
  final int prepTime;
  final int cookTime;
  final int restTime;
  final int servings;
}

/// Édite les champs de base d'une recette (maquette : menu ⋮ → Modifier). Le
/// toggle « recette de base » est verrouillé si la recette est déjà utilisée
/// comme composant (le serveur refuserait de toute façon le retour arrière).
Future<RecipeEdited?> showRecipeEditSheet(
  BuildContext context, {
  required RecipeDetail detail,
}) {
  return showModalBottomSheet<RecipeEdited>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _RecipeEditSheet(detail: detail),
  );
}

class _RecipeEditSheet extends StatefulWidget {
  const _RecipeEditSheet({required this.detail});

  final RecipeDetail detail;

  @override
  State<_RecipeEditSheet> createState() => _RecipeEditSheetState();
}

class _RecipeEditSheetState extends State<_RecipeEditSheet> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _prep;
  late final TextEditingController _cook;
  late final TextEditingController _rest;
  late int _servings;
  late bool _isBase;
  bool _showNameError = false;

  @override
  void initState() {
    super.initState();
    final s = widget.detail.summary;
    _name = TextEditingController(text: s.name);
    _description = TextEditingController(text: widget.detail.description ?? '');
    _prep = TextEditingController(text: s.prepTime.toString());
    _cook = TextEditingController(text: s.cookTime.toString());
    _rest = TextEditingController(text: s.restTime.toString());
    _servings = s.servings;
    _isBase = s.isBase;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _prep.dispose();
    _cook.dispose();
    _rest.dispose();
    super.dispose();
  }

  int _parse(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _showNameError = true);
      return;
    }
    Navigator.of(context).pop(
      RecipeEdited(
        name: name,
        description: _description.text.trim(),
        isBase: _isBase,
        prepTime: _parse(_prep),
        cookTime: _parse(_cook),
        restTime: _parse(_rest),
        servings: _servings < 1 ? 1 : _servings,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDAD5C8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                l10n.recipeEditTitle,
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  letterSpacing: -0.4,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 18),
              _Label(l10n.recipeFieldName),
              const SizedBox(height: 7),
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) {
                  if (_showNameError) setState(() => _showNameError = false);
                },
                decoration: _decoration(
                  hint: l10n.recipeNameHint,
                  error: _showNameError ? l10n.recipeNameRequired : null,
                ),
              ),
              const SizedBox(height: 16),
              _Label(l10n.recipeFieldDescription),
              const SizedBox(height: 7),
              TextField(
                controller: _description,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: _decoration(hint: l10n.recipeDescriptionHint),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _TimeField(label: l10n.recipeFieldPrep, controller: _prep)),
                  const SizedBox(width: 10),
                  Expanded(child: _TimeField(label: l10n.recipeFieldCook, controller: _cook)),
                  const SizedBox(width: 10),
                  Expanded(child: _TimeField(label: l10n.recipeFieldRest, controller: _rest)),
                ],
              ),
              const SizedBox(height: 16),
              _Label(l10n.recipeFieldServings),
              const SizedBox(height: 7),
              _ServingsStepper(
                value: _servings,
                onChanged: (v) => setState(() => _servings = v),
              ),
              const SizedBox(height: 16),
              _BaseSwitchRow(
                value: _isBase,
                locked: widget.detail.isLocked,
                onChanged: (v) => setState(() => _isBase = v),
                l10n: l10n,
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  child: Text(
                    l10n.commonSave,
                    style: const TextStyle(
                        fontSize: 15.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration({required String hint, String? error}) {
    OutlineInputBorder border(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c),
        );
    return InputDecoration(
      hintText: hint,
      errorText: error,
      filled: true,
      fillColor: AppColors.card,
      enabledBorder: border(AppColors.border),
      focusedBorder: border(AppColors.primary),
      errorBorder: border(AppColors.danger),
      focusedErrorBorder: border(AppColors.danger),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AppColors.card,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
      ],
    );
  }
}

class _ServingsStepper extends StatelessWidget {
  const _ServingsStepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepButton(
          icon: Icons.remove_rounded,
          onTap: value > 1 ? () => onChanged(value - 1) : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            '$value',
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        _StepButton(icon: Icons.add_rounded, onTap: () => onChanged(value + 1)),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : AppColors.card,
          shape: BoxShape.circle,
          border: enabled ? null : Border.all(color: AppColors.divider),
        ),
        child: Icon(icon,
            size: 18, color: enabled ? Colors.white : AppColors.textMuted),
      ),
    );
  }
}

class _BaseSwitchRow extends StatelessWidget {
  const _BaseSwitchRow({
    required this.value,
    required this.locked,
    required this.onChanged,
    required this.l10n,
  });

  final bool value;
  final bool locked;
  final ValueChanged<bool> onChanged;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.recipeBaseToggleTitle,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                ),
                Text(
                  locked
                      ? l10n.recipeBaseLockedHint
                      : l10n.recipeBaseToggleSubtitle,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: locked ? null : onChanged,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: AppColors.textMuted,
      ),
    );
  }
}
