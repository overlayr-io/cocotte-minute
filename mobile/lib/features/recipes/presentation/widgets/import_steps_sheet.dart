import 'package:flutter/material.dart';

import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// Découpe un texte en étapes : chaque bloc séparé par une ligne vide → 1 étape.
List<String> splitStepsText(String text) {
  return text
      .split(RegExp(r'\n\s*\n'))
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .toList();
}

/// Feuille d'import texte (maquette 9d). Renvoie la liste des descriptions
/// détectées, ou `null` si annulé.
Future<List<String>?> showImportStepsSheet(BuildContext context) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ImportStepsSheet(),
  );
}

class _ImportStepsSheet extends StatefulWidget {
  const _ImportStepsSheet();

  @override
  State<_ImportStepsSheet> createState() => _ImportStepsSheetState();
}

class _ImportStepsSheetState extends State<_ImportStepsSheet> {
  final _controller = TextEditingController();
  List<String> _steps = const [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FractionallySizedBox(
      heightFactor: 0.88,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8D3C6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 4, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.recipeStepsImportTitle,
                        style: const TextStyle(
                          fontFamily: AppFonts.display,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          letterSpacing: -0.3,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Material(
                      color: const Color(0xFFEAE6DA),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        customBorder: const CircleBorder(),
                        child: const SizedBox(
                          width: 34,
                          height: 34,
                          child: Icon(Icons.close_rounded,
                              size: 19, color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF0E4),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                size: 16, color: Color(0xFF5C7A4C)),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                l10n.recipeStepsImportHint,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  height: 1.45,
                                  color: Color(0xFF4B6340),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          autofocus: true,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          keyboardType: TextInputType.multiline,
                          onChanged: (v) =>
                              setState(() => _steps = splitStepsText(v)),
                          style: const TextStyle(
                              fontSize: 14, height: 1.55, color: Color(0xFF33404B)),
                          decoration: InputDecoration(
                            hintText: l10n.recipeStepsImportPlaceholder,
                            filled: true,
                            fillColor: AppColors.card,
                            alignLabelWithHint: true,
                            contentPadding: const EdgeInsets.all(15),
                            enabledBorder: _border(AppColors.border),
                            focusedBorder: _border(AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE7EFE0),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_outline_rounded,
                                size: 15, color: Color(0xFF5C7A4C)),
                            const SizedBox(width: 6),
                            Text(
                              l10n.recipeStepsDetected(_steps.length),
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF4B6340),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: Color(0xFFECE8DE))),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: _steps.isEmpty
                        ? null
                        : () => Navigator.of(context).pop(_steps),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFE7C9C4),
                      disabledForegroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      l10n.recipeStepsImportCta(_steps.length),
                      style:
                          const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: 1.5),
      );
}
