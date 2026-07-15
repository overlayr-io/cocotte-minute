import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../recipes/data/recipes_repository.dart';
import '../../../recipes/domain/recipe.dart';
import 'add_entry_sheet.dart';

/// Nombre max de recettes renvoyées par la recherche (limite de requête).
const _kTraySearchLimit = 10;

/// Sheet « Recettes à planifier » : coche/décoche les recettes gardées dans le
/// bandeau. Panneau redimensionnable (glisser vers le haut = plus grand) avec
/// une barre de recherche par nom (requête serveur limitée à 10). Retourne la
/// nouvelle liste d'ids sélectionnés.
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
  final _searchController = TextEditingController();
  Timer? _debounce;

  List<RecipeSummary>? _recipes;
  bool _loadFailed = false;
  bool _searching = false;
  late final List<String> _selected = [...widget.initialIds];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Requête serveur `GET /recipes?q=&limit=10` (filtre `ilike` sur le nom).
  /// Query vide → 10 recettes les plus récentes.
  Future<void> _load({String? query}) async {
    setState(() => _searching = true);
    try {
      final recipes = await sl<RecipesRepository>().fetchMine(
        q: query,
        limit: _kTraySearchLimit,
      );
      if (!mounted) return;
      setState(() {
        _recipes = recipes;
        _loadFailed = false;
        _searching = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _loadFailed = _recipes == null; // n'écrase pas une liste déjà affichée
        _searching = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final q = value.trim();
      _load(query: q.isEmpty ? null : q);
    });
  }

  void _toggle(String id) {
    setState(() {
      if (!_selected.remove(id)) _selected.add(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Panneau redimensionnable : s'ouvre à ~60 % et se tire jusqu'à 92 %.
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                _buildSearchField(context),
                const SizedBox(height: 10),
                Expanded(child: _buildList(context, scrollController)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
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
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE3DECF), width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, size: 20, color: AppColors.textMuted),
            const SizedBox(width: 9),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l10n.planningSearchHint,
                  border: InputBorder.none,
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 14.5),
              ),
            ),
            if (_searching)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (_searchController.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
                child: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, ScrollController scrollController) {
    final l10n = AppLocalizations.of(context);
    if (_recipes == null && !_loadFailed) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadFailed || (_recipes?.isEmpty ?? true)) {
      return Center(
        child: Text(
          l10n.planningNoRecipeFound,
          style: const TextStyle(color: Color(0xFFA79F8B), fontSize: 13.5),
        ),
      );
    }
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: _recipes!.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final recipe = _recipes![index];
        return _PickRow(
          recipe: recipe,
          selected: _selected.contains(recipe.id),
          onTap: () => _toggle(recipe.id),
        );
      },
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
