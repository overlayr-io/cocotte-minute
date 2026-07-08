import 'package:flutter/material.dart';

import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/category.dart';
import 'category_path.dart';

/// Issue de la sheet dossier : enregistrement (nom + emoji + parent) ou demande
/// de suppression (édition uniquement).
sealed class CategorySheetResult {
  const CategorySheetResult();
}

class CategorySaved extends CategorySheetResult {
  const CategorySaved({
    required this.name,
    required this.icon,
    required this.parentCategoryId,
  });

  final String name;
  final String? icon;
  final String? parentCategoryId;
}

class CategoryDeleteRequested extends CategorySheetResult {
  const CategoryDeleteRequested();
}

/// Bottom-sheet de création / édition d'un dossier (maquette 3l adaptée) :
/// picker d'emoji, nom, et — en création — sélecteur de dossier parent
/// pré-rempli selon le contexte. En édition, le parent n'est pas modifiable et
/// un bouton de suppression est proposé.
Future<CategorySheetResult?> showCategoryFormSheet(
  BuildContext context, {
  Category? initial,
  String? parentId,
  required List<Category> allCategories,
}) {
  return showModalBottomSheet<CategorySheetResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CategoryFormSheet(
      initial: initial,
      parentId: initial?.parentCategoryId ?? parentId,
      allCategories: allCategories,
    ),
  );
}

class _CategoryFormSheet extends StatefulWidget {
  const _CategoryFormSheet({
    this.initial,
    required this.parentId,
    required this.allCategories,
  });

  final Category? initial;
  final String? parentId;
  final List<Category> allCategories;

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  late final TextEditingController _nameController;
  late String? _icon;
  late String? _parentId;
  bool _showError = false;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    _icon = widget.initial?.icon;
    _parentId = widget.parentId;
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
      CategorySaved(name: name, icon: _icon, parentCategoryId: _parentId),
    );
  }

  Future<void> _pickParent() async {
    final selected = await showModalBottomSheet<_ParentChoice>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ParentPicker(
        allCategories: widget.allCategories,
        selectedId: _parentId,
      ),
    );
    if (selected != null) {
      setState(() => _parentId = selected.id);
    }
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isEditing
                        ? l10n.categoryEditTitle
                        : l10n.categoryCreateTitle,
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
                    onPressed: () => Navigator.of(context)
                        .pop(const CategoryDeleteRequested()),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: Text(l10n.commonDelete),
                    style:
                        TextButton.styleFrom(foregroundColor: AppColors.danger),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            _Label(l10n.categoryFieldIcon),
            const SizedBox(height: 11),
            _EmojiField(
              initial: _icon,
              onChanged: (emoji) => setState(() => _icon = emoji),
            ),
            const SizedBox(height: 18),
            _Label(l10n.categoryFieldName),
            const SizedBox(height: 7),
            TextField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() => _showError = false),
              decoration: InputDecoration(
                hintText: l10n.categoryNameHint,
                errorText: _showError ? l10n.categoryNameRequired : null,
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
            if (!_isEditing) ...[
              const SizedBox(height: 18),
              _Label(l10n.categoryFieldParent),
              const SizedBox(height: 7),
              _ParentField(
                label: _parentId == null
                    ? l10n.categoryParentRoot
                    : categoryPath(
                        widget.allCategories.firstWhere(
                          (c) => c.id == _parentId,
                        ),
                        widget.allCategories,
                      ),
                onTap: _pickParent,
              ),
            ],
            const SizedBox(height: 24),
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
                  l10n.commonSave,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
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

/// Champ emoji : la pastille est un vrai champ de saisie. La toucher ouvre le
/// clavier système (l'utilisateur bascule sur les emojis et insère celui qu'il
/// veut). On ne conserve que le dernier « caractère » perçu (un seul emoji,
/// gestion des séquences ZWJ via `characters`).
class _EmojiField extends StatefulWidget {
  const _EmojiField({required this.initial, required this.onChanged});

  final String? initial;
  final ValueChanged<String?> onChanged;

  @override
  State<_EmojiField> createState() => _EmojiFieldState();
}

class _EmojiFieldState extends State<_EmojiField> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final chars = value.characters;
    final emoji = chars.isEmpty ? '' : chars.last.toString();
    if (emoji != value) {
      _controller.value = TextEditingValue(
        text: emoji,
        selection: TextSelection.collapsed(offset: emoji.length),
      );
    }
    setState(() {});
    widget.onChanged(emoji.isEmpty ? null : emoji);
  }

  void _clear() {
    _controller.clear();
    setState(() {});
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasEmoji = _controller.text.isNotEmpty;

    return Column(
      children: [
        Center(
          child: GestureDetector(
            onTap: _focusNode.requestFocus,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: SizedBox(
                    width: 56,
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      textAlign: TextAlign.center,
                      showCursor: false,
                      maxLines: 1,
                      autocorrect: false,
                      enableSuggestions: false,
                      style: const TextStyle(fontSize: 34, height: 1.1),
                      decoration: const InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        counterText: '',
                      ),
                      onChanged: _onChanged,
                    ),
                  ),
                ),
                if (!hasEmoji)
                  const IgnorePointer(
                    child: Icon(Icons.folder_outlined,
                        size: 32, color: AppColors.primary),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (hasEmoji)
          TextButton(
            onPressed: _clear,
            style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
            child: Text(l10n.categoryIconClear),
          )
        else
          Text(
            l10n.categoryIconHint,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: AppColors.textMuted,
            ),
          ),
      ],
    );
  }
}

class _ParentField extends StatelessWidget {
  const _ParentField({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

/// Choix retourné par le picker de parent (`id` null = racine).
class _ParentChoice {
  const _ParentChoice(this.id);
  final String? id;
}

class _ParentPicker extends StatelessWidget {
  const _ParentPicker({required this.allCategories, required this.selectedId});

  final List<Category> allCategories;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Parents valides : ceux qui peuvent encore accueillir un sous-dossier.
    final candidates =
        allCategories.where((c) => c.canHaveChildren).toList(growable: false);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
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
          const SizedBox(height: 16),
          Text(
            l10n.categoryFieldParent,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w700,
              fontSize: 19,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                _ParentOption(
                  label: l10n.categoryParentRoot,
                  selected: selectedId == null,
                  onTap: () =>
                      Navigator.of(context).pop(const _ParentChoice(null)),
                ),
                for (final c in candidates)
                  _ParentOption(
                    label: categoryPath(c, allCategories),
                    icon: c.icon,
                    selected: selectedId == c.id,
                    onTap: () =>
                        Navigator.of(context).pop(_ParentChoice(c.id)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ParentOption extends StatelessWidget {
  const _ParentOption({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final String? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: icon != null
                  ? Text(icon!, style: const TextStyle(fontSize: 17))
                  : const Icon(Icons.folder_outlined,
                      size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_rounded,
                  size: 20, color: AppColors.primary),
          ],
        ),
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
