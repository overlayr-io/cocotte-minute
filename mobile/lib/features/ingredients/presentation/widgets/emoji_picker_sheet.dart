import 'package:flutter/material.dart';

import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// Ouvre le sélecteur d'emoji : grille d'emojis alimentaires courants + champ
/// libre pour en taper un au clavier système. Retourne l'emoji choisi, ou null
/// si annulé.
Future<String?> showEmojiPickerSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _EmojiPickerSheet(),
  );
}

/// Palette d'emojis alimentaires courants (cuisine familiale).
const List<String> _foodEmojis = [
  '🥕', '🧅', '🧄', '🥔', '🍅', '🥒', '🫑', '🌶️', '🥬', '🥦',
  '🍆', '🌽', '🥗', '🍄', '🫛', '🫘', '🥜', '🌰', '🫚', '🧂',
  '🍎', '🍏', '🍐', '🍊', '🍋', '🍌', '🍉', '🍇', '🍓', '🫐',
  '🍒', '🍑', '🥭', '🍍', '🥥', '🥝', '🍈', '🫒', '🥑', '🍅',
  '🍞', '🥖', '🥐', '🫓', '🥯', '🧇', '🥞', '🍚', '🍝', '🍜',
  '🥩', '🍗', '🍖', '🥓', '🌭', '🍔', '🧀', '🥚', '🥛', '🧈',
  '🐟', '🦐', '🦀', '🦑', '🐙', '🍤', '🧅', '🍯', '🫙', '🧊',
  '🌿', '🍃', '🌱', '🫐', '☕', '🍵', '🍷', '🧉', '🥤', '🍫',
];

class _EmojiPickerSheet extends StatefulWidget {
  const _EmojiPickerSheet();

  @override
  State<_EmojiPickerSheet> createState() => _EmojiPickerSheetState();
}

class _EmojiPickerSheetState extends State<_EmojiPickerSheet> {
  final _customController = TextEditingController();

  void _submitCustom() {
    final value = _customController.text.characters;
    if (value.isEmpty) return;
    // On ne garde que le premier caractère-emoji (grapheme).
    Navigator.of(context).pop(value.first);
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
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
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
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
              l10n.ingredientEmojiSheetTitle,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customController,
                    textAlign: TextAlign.center,
                    onSubmitted: (_) => _submitCustom(),
                    style: const TextStyle(fontSize: 22),
                    decoration: InputDecoration(
                      hintText: l10n.ingredientEmojiCustomHint,
                      hintStyle: const TextStyle(fontSize: 14),
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
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _submitCustom,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(l10n.commonValidate),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: _foodEmojis.length,
                itemBuilder: (context, i) {
                  final emoji = _foodEmojis[i];
                  return GestureDetector(
                    onTap: () => Navigator.of(context).pop(emoji),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      alignment: Alignment.center,
                      child: Text(emoji, style: const TextStyle(fontSize: 26)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
