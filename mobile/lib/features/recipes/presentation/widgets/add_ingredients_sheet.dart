import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../ingredients/data/ingredients_repository.dart';
import '../../../ingredients/domain/ingredient.dart';
import '../../../ingredients/presentation/widgets/ingredient_form_sheet.dart';
import '../../../ingredients/presentation/widgets/unit_selector.dart';
import '../bloc/add_ingredients_cubit.dart';
import '../bloc/recipe_detail_cubit.dart';
import 'quantity_stepper.dart';

/// Ouvre la feuille d'ajout d'ingrédients (maquettes 8a/8b/8c) et renvoie les
/// lignes sélectionnées (ingrédient + quantité), ou `null` si annulé.
Future<List<RecipeIngredientDraft>?> showAddIngredientsSheet(
  BuildContext context,
) {
  return showModalBottomSheet<List<RecipeIngredientDraft>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider(
      create: (_) =>
          AddIngredientsCubit(repository: sl<IngredientsRepository>())..load(),
      child: FractionallySizedBox(
        heightFactor: 0.92,
        child: const _AddIngredientsSheet(),
      ),
    ),
  );
}

class _AddIngredientsSheet extends StatefulWidget {
  const _AddIngredientsSheet();

  @override
  State<_AddIngredientsSheet> createState() => _AddIngredientsSheetState();
}

class _AddIngredientsSheetState extends State<_AddIngredientsSheet> {
  int _tab = 0; // 0 = mes ingrédients, 1 = catalogue système
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Ingredient> _filter(List<Ingredient> items) {
    if (_query.isEmpty) return items;
    final q = _query.toLowerCase();
    return items.where((i) => i.name.toLowerCase().contains(q)).toList();
  }

  Future<void> _create() async {
    final cubit = context.read<AddIngredientsCubit>();
    final draft = await showCreateIngredientSheet(context);
    if (draft == null) return;
    await cubit.createAndSelect(name: draft.name, unit: draft.unit);
    if (mounted) setState(() => _tab = 0);
  }

  Future<void> _import(Ingredient system) async {
    final cubit = context.read<AddIngredientsCubit>();
    await cubit.importSystem(system);
    // L'ingrédient importé rejoint « mes ingrédients », déjà sélectionné.
    if (mounted) setState(() => _tab = 0);
  }

  void _confirm(AddIngredientsReady state) {
    final drafts = [
      for (final entry in state.selection.entries)
        (ingredientId: entry.key, quantity: entry.value),
    ];
    Navigator.of(context).pop(drafts);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      clipBehavior: Clip.antiAlias,
      child: BlocConsumer<AddIngredientsCubit, AddIngredientsState>(
        listenWhen: (_, curr) =>
            curr is AddIngredientsReady && curr.message != null,
        listener: (context, state) {
          if (state is AddIngredientsReady && state.message != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.message!)));
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              const _DragHandle(),
              _Header(title: l10n.addIngredientsTitle),
              Expanded(
                child: switch (state) {
                  AddIngredientsError(:final message) => ErrorView(
                    message: message,
                    onRetry: () => context.read<AddIngredientsCubit>().load(),
                  ),
                  AddIngredientsReady() => _body(context, state, l10n),
                  _ => const Center(child: CircularProgressIndicator()),
                },
              ),
              if (state is AddIngredientsReady)
                _StickyCta(
                  count: state.selection.length,
                  onPressed: state.selection.isEmpty
                      ? null
                      : () => _confirm(state),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _body(
    BuildContext context,
    AddIngredientsReady state,
    AppLocalizations l10n,
  ) {
    final isMine = _tab == 0;
    final items = _filter(isMine ? state.mine : state.system);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
          child: _SearchField(
            controller: _searchController,
            hint: l10n.addIngredientsSearchHint,
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
          child: _UnderlineTabs(
            index: _tab,
            labels: [l10n.ingredientsTabMine, l10n.addIngredientsTabCatalog],
            onChanged: (i) => setState(() => _tab = i),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
            children: [
              if (!isMine)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10, left: 2, right: 2),
                  child: Text(
                    l10n.addIngredientsCatalogInfo,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: Color(0xFF8A8574),
                    ),
                  ),
                ),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Text(
                    _query.isNotEmpty
                        ? l10n.ingredientsNoSearchResult
                        : l10n.addIngredientsEmptyMine,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                )
              else
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: isMine
                        ? _SelectableRow(
                            ingredient: item,
                            quantity: state.selection[item.id],
                            onToggle: () => context
                                .read<AddIngredientsCubit>()
                                .toggle(item),
                            onQuantity: (q) => context
                                .read<AddIngredientsCubit>()
                                .setQuantity(item.id, q),
                          )
                        : _ImportRow(
                            ingredient: item,
                            busy: state.busyImportId == item.id,
                            onImport: () => _import(item),
                          ),
                  ),
              if (isMine) ...[
                const SizedBox(height: 2),
                _DashedButton(
                  label: l10n.addIngredientsCreateCta,
                  onTap: _create,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// --- header / chrome -------------------------------------------------------

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
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
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 6, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w700,
                fontSize: 22,
                letterSpacing: -0.4,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          _CircleButton(
            icon: Icons.close_rounded,
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEAE6DA),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 19, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _StickyCta extends StatelessWidget {
  const _StickyCta({required this.count, required this.onPressed});

  final int count;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        22,
        12,
        22,
        12 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: Color(0xFFECE8DE))),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: FilledButton(
          onPressed: onPressed,
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
            l10n.addIngredientsCta(count),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

// --- rows ------------------------------------------------------------------

class _SelectableRow extends StatelessWidget {
  const _SelectableRow({
    required this.ingredient,
    required this.quantity,
    required this.onToggle,
    required this.onQuantity,
  });

  final Ingredient ingredient;

  /// Non-null si l'ingrédient est sélectionné (= sa quantité).
  final double? quantity;
  final VoidCallback onToggle;
  final ValueChanged<double> onQuantity;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selected = quantity != null;
    return Material(
      color: selected ? AppColors.card : AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? const Color(0xFFCFE0C2) : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              _Avatar(imageUrl: ingredient.imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ingredient.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      unitDescription(l10n, ingredient.unit),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (selected)
                QuantityStepper(
                  quantity: quantity!,
                  unit: ingredient.unit,
                  onChanged: onQuantity,
                )
              else
                const _AddCircle(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImportRow extends StatelessWidget {
  const _ImportRow({
    required this.ingredient,
    required this.busy,
    required this.onImport,
  });

  final Ingredient ingredient;
  final bool busy;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final imported = ingredient.alreadyImported;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: imported ? const Color(0xFFF4F2EB) : AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _Avatar(imageUrl: ingredient.imageUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ingredient.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  unitDescription(l10n, ingredient.unit),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (imported)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_rounded, size: 16, color: Color(0xFF8A8574)),
                const SizedBox(width: 4),
                Text(
                  l10n.ingredientsAlreadyImported,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8A8574),
                  ),
                ),
              ],
            )
          else
            OutlinedButton(
              onPressed: busy ? null : onImport,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF5C7A4C),
                side: const BorderSide(color: AppColors.primary, width: 1.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              ),
              child: busy
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.download_rounded, size: 15),
                        const SizedBox(width: 5),
                        Text(
                          l10n.ingredientsImport,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(13),
        image: imageUrl != null
            ? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover)
            : null,
      ),
      child: imageUrl == null
          ? const Icon(Icons.eco_outlined, size: 20, color: AppColors.primary)
          : null,
    );
  }
}

class _AddCircle extends StatelessWidget {
  const _AddCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD8D3C6), width: 1.6),
      ),
      child: const Icon(Icons.add_rounded, size: 18, color: Color(0xFFB7B0A0)),
    );
  }
}

// --- atoms -----------------------------------------------------------------

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.card,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}

class _UnderlineTabs extends StatelessWidget {
  const _UnderlineTabs({
    required this.index,
    required this.labels,
    required this.onChanged,
  });

  final int index;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE7E3D8))),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            GestureDetector(
              onTap: () => onChanged(i),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(right: 22, bottom: 10),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: i == index
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: i == index
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: i == index
                          ? AppColors.textPrimary
                          : const Color(0xFFA79F8B),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DashedButton extends StatelessWidget {
  const _DashedButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: Color(0xFFC4BEAD), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
