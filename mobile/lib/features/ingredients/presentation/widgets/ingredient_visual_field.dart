import 'package:flutter/material.dart';

import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/image_upload_picker.dart';
import 'emoji_picker_sheet.dart';

/// Sélecteur de visuel d'un ingrédient : bascule entre un emoji et une image
/// (mutuellement exclusifs). Le parent détient l'état ([emoji]/[imageUrl]) et
/// est notifié via [onEmojiChanged] (null = retiré) et [onImageUploaded].
class IngredientVisualField extends StatefulWidget {
  const IngredientVisualField({
    super.key,
    required this.emoji,
    required this.imageUrl,
    required this.onEmojiChanged,
    required this.onImageUploaded,
  });

  final String? emoji;
  final String? imageUrl;
  final ValueChanged<String?> onEmojiChanged;
  final ValueChanged<String> onImageUploaded;

  @override
  State<IngredientVisualField> createState() => _IngredientVisualFieldState();
}

enum _Mode { emoji, image }

class _IngredientVisualFieldState extends State<IngredientVisualField> {
  late _Mode _mode =
      widget.imageUrl != null ? _Mode.image : _Mode.emoji;

  Future<void> _pickEmoji() async {
    final picked = await showEmojiPickerSheet(context);
    if (picked != null) widget.onEmojiChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        _ModeToggle(
          mode: _mode,
          emojiLabel: l10n.ingredientVisualEmoji,
          imageLabel: l10n.ingredientVisualImage,
          onChanged: (m) => setState(() => _mode = m),
        ),
        const SizedBox(height: 16),
        if (_mode == _Mode.emoji)
          _EmojiTile(
            emoji: widget.emoji,
            hint: l10n.ingredientEmojiPick,
            onTap: _pickEmoji,
            onClear:
                widget.emoji != null ? () => widget.onEmojiChanged(null) : null,
          )
        else
          ImageUploadPicker(
            folder: 'ingredients',
            initialUrl: widget.imageUrl,
            onUploaded: widget.onImageUploaded,
            placeholder: const _ImagePlaceholder(),
          ),
      ],
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({
    required this.mode,
    required this.emojiLabel,
    required this.imageLabel,
    required this.onChanged,
  });

  final _Mode mode;
  final String emojiLabel;
  final String imageLabel;
  final ValueChanged<_Mode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _segment(emojiLabel, Icons.emoji_emotions_outlined, _Mode.emoji),
          _segment(imageLabel, Icons.image_outlined, _Mode.image),
        ],
      ),
    );
  }

  Widget _segment(String label, IconData icon, _Mode value) {
    final active = mode == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: active ? Colors.white : AppColors.textMuted,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmojiTile extends StatelessWidget {
  const _EmojiTile({
    required this.emoji,
    required this.hint,
    required this.onTap,
    required this.onClear,
  });

  final String? emoji;
  final String hint;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: const Color(0xFFEAE3D3),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFC9C3B4), width: 2),
            ),
            alignment: Alignment.center,
            child: emoji != null
                ? Text(emoji!, style: const TextStyle(fontSize: 44))
                : const Icon(Icons.add_reaction_outlined,
                    color: Color(0xFFA79F8B), size: 34),
          ),
        ),
        const SizedBox(height: 8),
        if (onClear != null)
          TextButton(
            onPressed: onClear,
            child: Text(
              MaterialLocalizations.of(context).deleteButtonTooltip,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          )
        else
          Text(
            hint,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
      ],
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        color: const Color(0xFFEAE3D3),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFC9C3B4), width: 2),
      ),
      child: const Icon(Icons.eco_outlined, color: Color(0xFFA79F8B), size: 30),
    );
  }
}
