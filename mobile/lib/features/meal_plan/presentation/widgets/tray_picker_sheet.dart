import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../recipes/data/recipes_repository.dart';
import '../../../recipes/domain/recipe.dart';
import 'add_entry_sheet.dart';

/// Sheet « Recettes à planifier » : coche/décoche les recettes gardées dans le
/// bandeau. Retourne la nouvelle liste d'ids (ordre de sélection), ou null si
/// fermée sans validation… la sélection est renvoyée aussi à la fermeture.
Future<List<String>?> showTrayPickerSheet(
  BuildContext context, {
  required List<String> initialIds,
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TrayPickerSheet(initialIds: initialIds),
  );
}

class _TrayPickerSheet extends StatefulWidget {
  const _TrayPickerSheet({required this.initialIds});

  final List<String> initialIds;

  @override
  State<_TrayPickerSheet> createState() => _TrayPickerSheetState();
}

class _TrayPickerSheetState extends State<_TrayPickerSheet> {
  List<RecipeSummary>? _recipes;
  bool _loadFailed = false;
  late final List<String> _selected = [...widget.initialIds];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final recipes = await sl<RecipesRepository>().fetchMine();
      if (mounted) setState(() => _recipes = recipes);
    } on Object {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  void _toggle(String id) {
    setState(() {
      if (!_selected.remove(id)) _selected.add(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.8,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDAD5C8),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.planningPickerKicker.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: kPlanningKicker,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              l10n.planningPickerTitle,
                              style: const TextStyle(
                                fontFamily: AppFonts.display,
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                                letterSpacing: -0.4,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(_selected),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          l10n.planningPickerDone(_selected.length),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.planningPickerBody,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: Color(0xFF8A8574),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: _loadFailed
                  ? Center(
                      child: Text(
                        l10n.planningNoRecipeFound,
                        style: const TextStyle(
                          color: Color(0xFFA79F8B),
                          fontSize: 13.5,
                        ),
                      ),
                    )
                  : _recipes == null
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: _recipes!.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final recipe = _recipes![index];
                        final on = _selected.contains(recipe.id);
                        return _PickRow(
                          recipe: recipe,
                          selected: on,
                          onTap: () => _toggle(recipe.id),
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

class _PickRow extends StatelessWidget {
  const _PickRow({
    required this.recipe,
    required this.selected,
    required this.onTap,
  });

  final RecipeSummary recipe;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final total = recipe.prepTime + recipe.cookTime + recipe.restTime;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF3F7EF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: recipe.photoUrl != null
                  ? AppNetworkImage(recipe.photoUrl!, width: 46, height: 46)
                  : Container(
                      width: 46,
                      height: 46,
                      color: AppColors.primaryTint,
                      child: const Icon(
                        Icons.restaurant_menu,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${l10n.recipeServingsShort(recipe.servings)} · ${l10n.searchMinutesShort(total)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.primary : Colors.white,
                border: Border.all(
                  color: selected ? AppColors.primary : const Color(0xFFD6D2C6),
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 15, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
