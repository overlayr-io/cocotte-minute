import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../recipes/data/recipes_repository.dart';
import '../../../recipes/domain/recipe.dart';

/// Feuille de sélection multiple de recettes (pour « Ses recettes ») : liste
/// des recettes du compte moins celles déjà associées ([excludeIds]), filtrable
/// par un champ texte simple. Retourne les ids sélectionnés, ou null si annulé.
Future<List<String>?> showRecipePickSheet(
  BuildContext context, {
  required Set<String> excludeIds,
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _RecipePickSheet(excludeIds: excludeIds),
  );
}

class _RecipePickSheet extends StatefulWidget {
  const _RecipePickSheet({required this.excludeIds});

  final Set<String> excludeIds;

  @override
  State<_RecipePickSheet> createState() => _RecipePickSheetState();
}

class _RecipePickSheetState extends State<_RecipePickSheet> {
  List<RecipeSummary>? _recipes;
  String? _error;
  String _query = '';
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final all = await sl<RecipesRepository>().fetchMine();
      if (!mounted) return;
      setState(() {
        _recipes = all
            .where((r) => !widget.excludeIds.contains(r.id))
            .toList();
      });
    } on RecipesRepositoryException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  List<RecipeSummary> get _filtered {
    final q = _query.trim().toLowerCase();
    final recipes = _recipes ?? const [];
    if (q.isEmpty) return recipes;
    return recipes.where((r) => r.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: EdgeInsets.only(
            left: 22,
            right: 22,
            top: 10,
            // Laisse le champ visible quand le clavier est ouvert.
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8D3C6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.personRecipesPickTitle,
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  letterSpacing: -0.3,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: l10n.personRecipesPickSearchHint,
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
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
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(child: _body(l10n, scrollController)),
              SafeArea(
                top: false,
                minimum: const EdgeInsets.only(top: 8, bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: _selected.isEmpty
                        ? null
                        : () => Navigator.of(context).pop(_selected.toList()),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      l10n.personRecipesPickAdd(_selected.length),
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _body(AppLocalizations l10n, ScrollController scrollController) {
    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
      );
    }
    if (_recipes == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final filtered = _filtered;
    if (filtered.isEmpty) {
      return Center(
        child: Text(
          l10n.personRecipesPickEmpty,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
      );
    }
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final recipe = filtered[i];
        final selected = _selected.contains(recipe.id);
        return Material(
          color: selected ? AppColors.primaryTint : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => setState(() {
              selected ? _selected.remove(recipe.id) : _selected.add(recipe.id);
            }),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      recipe.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 22,
                    color:
                        selected ? AppColors.primary : const Color(0xFFC4C0B5),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
