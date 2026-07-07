import 'package:flutter/material.dart';

import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/tag.dart';
import 'tag_colors.dart';

/// Issue de la bottom-sheet de tag : enregistrement (nom + couleur) ou demande
/// de suppression (édition uniquement).
sealed class TagSheetResult {
  const TagSheetResult();
}

class TagSaved extends TagSheetResult {
  const TagSaved({required this.name, required this.color});

  final String name;
  final String color;
}

class TagDeleteRequested extends TagSheetResult {
  const TagDeleteRequested();
}

/// Bottom-sheet de création / édition d'un tag (nom + couleur), calquée sur la
/// coque de la sheet d'ajout de personne (maquette 3l) : ancrée en bas, poignée,
/// coins hauts arrondis. En édition, un bouton de suppression est proposé.
Future<TagSheetResult?> showTagFormSheet(BuildContext context, {Tag? initial}) {
  return showModalBottomSheet<TagSheetResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TagFormSheet(initial: initial),
  );
}

class _TagFormSheet extends StatefulWidget {
  const _TagFormSheet({this.initial});

  final Tag? initial;

  @override
  State<_TagFormSheet> createState() => _TagFormSheetState();
}

class _TagFormSheetState extends State<_TagFormSheet> {
  late final TextEditingController _nameController;
  late Color _color;
  bool _showError = false;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    _color = widget.initial != null
        ? TagColors.parse(widget.initial!.color)
        : TagColors.fallback;
  }

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
      TagSaved(name: name, color: TagColors.toHex(_color)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final previewName =
        _nameController.text.trim().isEmpty ? l10n.tagPreviewPlaceholder : _nameController.text.trim();

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
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isEditing ? l10n.tagEditTitle : l10n.tagCreateTitle,
                    style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      letterSpacing: -0.4,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (_isEditing)
                  TextButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pop(const TagDeleteRequested()),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: Text(l10n.commonDelete),
                    style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            _Label(l10n.tagFieldName),
            const SizedBox(height: 7),
            TextField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() => _showError = false),
              decoration: InputDecoration(
                hintText: l10n.tagNameHint,
                errorText: _showError ? l10n.tagNameRequired : null,
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
            const SizedBox(height: 18),
            _Label(l10n.tagFieldColor),
            const SizedBox(height: 11),
            _ColorPicker(
              selected: _color,
              onChanged: (c) => setState(() => _color = c),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Text(
                  l10n.tagPreview,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 10),
                _TagChip(name: previewName, color: _color),
              ],
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
                  _isEditing ? l10n.commonSave : l10n.tagCreateAction,
                  style:
                      const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
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

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({required this.selected, required this.onChanged});

  final Color selected;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final color in TagColors.options)
          GestureDetector(
            onTap: () => onChanged(color),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: color.toARGB32() == selected.toARGB32()
                    ? [BoxShadow(color: color, spreadRadius: 2)]
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: TagColors.tint(color),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
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
