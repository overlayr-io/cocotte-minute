import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/categories_repository.dart';
import '../../domain/category.dart';
import 'category_path.dart';

/// Ouvre le sélecteur de dossiers en drill-down (racine → sous-dossiers) avec
/// sélection multiple par case à cocher, visible à n'importe quel niveau. Les
/// dossiers sont chargés une seule fois puis gardés en mémoire le temps de la
/// navigation ; la sélection est conservée quel que soit le dossier affiché.
///
/// Renvoie le nouvel ensemble choisi, ou `null` si l'utilisateur annule.
Future<Set<String>?> showCategoryDrilldownPicker(
  BuildContext context, {
  required Set<String> initiallySelected,
}) {
  return Navigator.of(context).push<Set<String>>(
    MaterialPageRoute(
      builder: (_) => _CategoryDrilldownPickerPage(
        initiallySelected: initiallySelected,
      ),
    ),
  );
}

class _CategoryDrilldownPickerPage extends StatefulWidget {
  const _CategoryDrilldownPickerPage({required this.initiallySelected});

  final Set<String> initiallySelected;

  @override
  State<_CategoryDrilldownPickerPage> createState() =>
      _CategoryDrilldownPickerPageState();
}

class _CategoryDrilldownPickerPageState
    extends State<_CategoryDrilldownPickerPage> {
  late final Future<List<Category>> _future =
      sl<CategoriesRepository>().fetchMine();

  late final Set<String> _selected = {...widget.initiallySelected};

  /// Fil d'Ariane de la navigation : vide = racine.
  final List<Category> _stack = [];

  Category? get _current => _stack.isEmpty ? null : _stack.last;

  List<Category> _childrenOf(List<Category> all, String? parentId) {
    final children =
        all.where((c) => c.parentCategoryId == parentId).toList();
    children.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return children;
  }

  void _open(Category category) => setState(() => _stack.add(category));

  bool _back() {
    if (_stack.isEmpty) return false;
    setState(() => _stack.removeLast());
    return true;
  }

  void _toggle(String categoryId) {
    setState(() {
      if (!_selected.remove(categoryId)) _selected.add(categoryId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: _stack.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              if (!_back()) Navigator.of(context).pop();
            },
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: Text(_current?.name ?? l10n.categoryDrilldownRootLabel),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(_selected),
              child: Text(l10n.commonDone),
            ),
          ],
        ),
        body: FutureBuilder<List<Category>>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final all = snapshot.data!;
            final children = _childrenOf(all, _current?.id);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_current != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Text(
                      categoryPath(_current!, all),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFA79F8B),
                      ),
                    ),
                  ),
                Expanded(
                  child: children.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              _current == null
                                  ? l10n.categoriesEmpty
                                  : l10n.categoriesEmptyFolder,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: AppColors.textSecondary, height: 1.4),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                          itemCount: children.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 9),
                          itemBuilder: (context, i) {
                            final category = children[i];
                            return _DrilldownRow(
                              category: category,
                              selected: _selected.contains(category.id),
                              hasChildren: category.canHaveChildren,
                              onToggle: () => _toggle(category.id),
                              onOpen: () => _open(category),
                            );
                          },
                        ),
                ),
                if (_selected.isNotEmpty)
                  _SelectionSummary(
                    l10n: l10n,
                    selected: _selected,
                    all: all,
                    onRemove: _toggle,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DrilldownRow extends StatelessWidget {
  const _DrilldownRow({
    required this.category,
    required this.selected,
    required this.hasChildren,
    required this.onToggle,
    required this.onOpen,
  });

  final Category category;
  final bool selected;
  final bool hasChildren;
  final VoidCallback onToggle;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: hasChildren ? onOpen : onToggle,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: onToggle,
                icon: Icon(
                  selected
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  color: selected ? AppColors.primary : const Color(0xFFC4C0B5),
                ),
              ),
              Expanded(
                child: Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (category.recipeCount > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    '${category.recipeCount}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFFA79F8B)),
                  ),
                ),
              if (hasChildren)
                const Icon(Icons.chevron_right_rounded,
                    size: 20, color: Color(0xFFCBC7BB)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionSummary extends StatelessWidget {
  const _SelectionSummary({
    required this.l10n,
    required this.selected,
    required this.all,
    required this.onRemove,
  });

  final AppLocalizations l10n;
  final Set<String> selected;
  final List<Category> all;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final byId = {for (final c in all) c.id: c};
    final items =
        selected.map((id) => byId[id]).whereType<Category>().toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.categoryDrilldownSelectionLabel(items.length),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: Color(0xFFA79F8B),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final category in items)
                Chip(
                  label: Text(category.name),
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                  backgroundColor: AppColors.primaryTint,
                  deleteIcon: const Icon(Icons.close_rounded, size: 16),
                  onDeleted: () => onRemove(category.id),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
