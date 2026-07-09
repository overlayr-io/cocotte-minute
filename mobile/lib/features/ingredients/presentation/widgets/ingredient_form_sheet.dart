import 'package:flutter/material.dart';

import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/ingredient.dart';
import 'ingredient_visual_field.dart';
import 'unit_selector.dart';

/// Données saisies pour créer un ingrédient (emoji et image exclusifs).
typedef IngredientDraft = ({
  String name,
  IngredientUnit unit,
  String? imageUrl,
  String? emoji,
});

/// Bottom-sheet de création d'un ingrédient custom (nom + unité + image).
Future<IngredientDraft?> showCreateIngredientSheet(BuildContext context) {
  return showModalBottomSheet<IngredientDraft>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _IngredientFormSheet(),
  );
}

class _IngredientFormSheet extends StatefulWidget {
  const _IngredientFormSheet();

  @override
  State<_IngredientFormSheet> createState() => _IngredientFormSheetState();
}

class _IngredientFormSheetState extends State<_IngredientFormSheet> {
  final _nameController = TextEditingController();
  IngredientUnit _unit = IngredientUnit.gramme;
  String? _imageUrl;
  String? _emoji;
  bool _showError = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _showError = true);
      return;
    }
    Navigator.of(context).pop(
      (name: name, unit: _unit, imageUrl: _imageUrl, emoji: _emoji),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
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
              l10n.ingredientCreateTitle,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w700,
                fontSize: 22,
                letterSpacing: -0.4,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 18),
            IngredientVisualField(
              emoji: _emoji,
              imageUrl: _imageUrl,
              onEmojiChanged: (emoji) => setState(() {
                _emoji = emoji;
                _imageUrl = null;
              }),
              onImageUploaded: (url) => setState(() {
                _imageUrl = url;
                _emoji = null;
              }),
            ),
            const SizedBox(height: 18),
            _Label(l10n.ingredientFieldName),
            const SizedBox(height: 7),
            TextField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) {
                if (_showError) setState(() => _showError = false);
              },
              decoration: InputDecoration(
                hintText: l10n.ingredientNameHint,
                errorText: _showError ? l10n.ingredientNameRequired : null,
                filled: true,
                fillColor: AppColors.card,
                enabledBorder: _border(AppColors.border),
                focusedBorder: _border(AppColors.primary),
                errorBorder: _border(AppColors.danger),
                focusedErrorBorder: _border(AppColors.danger),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
            _Label(l10n.ingredientFieldUnit),
            const SizedBox(height: 9),
            UnitSelector(
              selected: _unit,
              onChanged: (u) => setState(() => _unit = u),
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
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  l10n.ingredientCreateAction,
                  style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color),
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

