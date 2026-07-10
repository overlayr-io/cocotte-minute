import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/pricing/price_calculator.dart';
import '../../../../core/pricing/price_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/action_menu.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../ingredient_prices/data/ingredient_prices_repository.dart';
import '../../../ingredient_prices/domain/ingredient_price.dart';
import '../../../ingredients/domain/ingredient.dart';
import '../../data/shopping_list_repository.dart';
import '../../domain/shopping_list.dart';
import '../bloc/shopping_list_cubit.dart';
import '../widgets/add_free_item_sheet.dart';
import '../widgets/alternative_sheet.dart';
import '../widgets/shopping_aisle.dart';
import '../widgets/shopping_format.dart';

/// Écran 5e — liste générée : progression, vues (par recette / par rayon / A–Z),
/// articles cochables, alternatives (5h), articles libres et export (5f).
class ShoppingListDetailPage extends StatelessWidget {
  const ShoppingListDetailPage({super.key, required this.listId});

  final String listId;

  static Route<void> route(String listId) => MaterialPageRoute<void>(
    builder: (_) => ShoppingListDetailPage(listId: listId),
  );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ShoppingListCubit(
        repository: sl<ShoppingListRepository>(),
        listId: listId,
      ),
      child: const _DetailView(),
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: BlocConsumer<ShoppingListCubit, ShoppingListDetailState>(
        listenWhen: (p, c) => c is ShoppingListDetailGone,
        listener: (context, state) {
          if (state is ShoppingListDetailGone) Navigator.of(context).pop();
        },
        builder: (context, state) {
          if (state is! ShoppingListDetailLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          return _Loaded(state: state);
        },
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.state});
  final ShoppingListDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<ShoppingListCubit>();
    final detail = state.detail;
    final list = detail.list;
    final checked = detail.items.where((i) => i.isChecked).length;
    final total = detail.items.length;
    final freeCount = detail.items.where((i) => i.sources.isEmpty).length;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFDDE6D4), Color(0xFFEAEEE1), AppColors.surface],
          stops: [0, 0.3, 0.55],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  const Spacer(),
                  Builder(
                    builder: (menuContext) => IconButton(
                      icon: const Icon(Icons.more_horiz_rounded,
                          color: AppColors.textPrimary),
                      onPressed: () => _openMenu(
                        menuContext,
                        l10n,
                        cubit,
                        detail,
                        checked,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 40),
                children: [
                  Text(
                    l10n.shoppingListEyebrow,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5C7A4C),
                    ),
                  ),
                  const SizedBox(height: 3),
                  GestureDetector(
                    onTap: () => _renameDialog(context, cubit, list.name),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            list.name,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.edit_outlined,
                            size: 16, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.shoppingDetailSummary(
                      l10n.shoppingItemsCount(total),
                      l10n.shoppingRecipesCount(list.recipeCount),
                      freeCount,
                    ),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _ProgressBar(checked: checked, total: total, l10n: l10n),
                  _ShoppingPriceTotal(items: detail.items),
                  const SizedBox(height: 16),
                  _ViewTabs(current: state.view, onChanged: cubit.setView, l10n: l10n),
                  const SizedBox(height: 16),
                  ..._buildBody(context, l10n, cubit, detail, state.view),
                  const SizedBox(height: 12),
                  _AddItemButton(
                    onTap: () async {
                      final input = await showAddFreeItemSheet(context);
                      if (input != null) {
                        await cubit.addFreeItem(
                          input.label,
                          quantity: input.quantity,
                          unit: input.unit,
                        );
                      }
                    },
                    l10n: l10n,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    ShoppingListCubit cubit,
    ShoppingListDetail detail,
    ShoppingView view,
  ) {
    if (view == ShoppingView.byRecipe) {
      final widgets = <Widget>[];
      for (final recipe in detail.recipes) {
        final items = detail.items
            .where((i) => i.sources.any((s) => s.recipeId == recipe.recipeId))
            .toList();
        if (items.isEmpty) continue;
        widgets.add(
          _GroupCard(
            title: recipe.recipeName,
            subtitle: l10n.shoppingRecipeMeta(
              recipe.servings,
              l10n.shoppingItemsCount(items.length),
            ),
            leading: _RecipeDot(photoUrl: recipe.photoUrl),
            children: [
              for (final item in items)
                _ItemRow(
                  item: item,
                  cubit: cubit,
                  quantityForRecipe: recipe.recipeId,
                ),
            ],
          ),
        );
      }
      final free = detail.items.where((i) => i.sources.isEmpty).toList();
      if (free.isNotEmpty) {
        widgets.add(
          _GroupCard(
            title: l10n.shoppingOtherItems,
            subtitle: l10n.shoppingOtherItemsSubtitle,
            leading: const _CartDot(),
            children: [
              for (final item in free) _ItemRow(item: item, cubit: cubit),
            ],
          ),
        );
      }
      return widgets;
    }

    if (view == ShoppingView.byAisle) {
      // Regroupement par rayon (heuristique nom → rayon, cf. shopping_aisle.dart),
      // avec un petit titre gris par rayon.
      final byAisle = <ShoppingAisle, List<ShoppingListItem>>{};
      for (final item in detail.items) {
        byAisle.putIfAbsent(aisleOf(item.name), () => []).add(item);
      }
      final widgets = <Widget>[];
      for (final aisle in kAisleOrder) {
        final items = byAisle[aisle];
        if (items == null || items.isEmpty) continue;
        items.sort(
          (a, b) =>
              a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
        );
        widgets.add(_SectionLabel(text: aisleLabel(l10n, aisle)));
        widgets.add(
          _PlainCard(
            children: [
              for (final item in items) _ItemRow(item: item, cubit: cubit),
            ],
          ),
        );
      }
      return widgets;
    }

    // A–Z : tout additionné, trié par nom, détail du calcul en sous-titre.
    final items = [...detail.items]..sort(
      (a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
    );
    return [
      _PlainCard(
        children: [
          for (final item in items)
            _ItemRow(item: item, cubit: cubit, showBreakdown: true),
        ],
      ),
    ];
  }

  Future<void> _renameDialog(
    BuildContext context,
    ShoppingListCubit cubit,
    String current,
  ) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l10n.shoppingRename),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty && name != current) {
      await cubit.rename(name);
    }
  }

  /// Menu « … » de la liste (13b) : Partager (vert), Renommer, Vider les cochés,
  /// puis Vider la liste (corail, isolé). [menuContext] est celui du bouton.
  void _openMenu(
    BuildContext menuContext,
    AppLocalizations l10n,
    ShoppingListCubit cubit,
    ShoppingListDetail detail,
    int checked,
  ) {
    showActionMenu(
      context: menuContext,
      items: [
        ActionMenuItem(
          icon: Icons.ios_share_rounded,
          label: l10n.shoppingShareList,
          style: ActionMenuStyle.primary,
          onSelected: () => _shareList(l10n, detail),
        ),
        ActionMenuItem(
          icon: Icons.edit_outlined,
          label: l10n.commonRename,
          onSelected: () => _renameDialog(menuContext, cubit, detail.list.name),
        ),
        ActionMenuItem(
          icon: Icons.remove_done_rounded,
          label: l10n.shoppingClearChecked,
          onSelected: () => _clearChecked(menuContext, l10n, cubit, checked),
        ),
        ActionMenuItem(
          icon: Icons.delete_outline_rounded,
          label: l10n.shoppingClear,
          style: ActionMenuStyle.destructive,
          dividerBefore: true,
          onSelected: () => _clearList(menuContext, l10n, cubit),
        ),
      ],
    );
  }

  /// Partage natif de la liste (texte : articles restant à acheter).
  Future<void> _shareList(
    AppLocalizations l10n,
    ShoppingListDetail detail,
  ) async {
    await SharePlus.instance.share(
      ShareParams(
        text: shoppingListShareText(l10n, detail),
        subject: detail.list.name,
      ),
    );
  }

  Future<void> _clearChecked(
    BuildContext context,
    AppLocalizations l10n,
    ShoppingListCubit cubit,
    int checked,
  ) async {
    if (checked == 0) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.shoppingClearCheckedEmpty)));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l10n.shoppingClearCheckedConfirmTitle),
        content: Text(l10n.shoppingClearCheckedConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (ok == true) await cubit.clearChecked();
  }

  Future<void> _clearList(
    BuildContext context,
    AppLocalizations l10n,
    ShoppingListCubit cubit,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l10n.shoppingClearConfirmTitle),
        content: Text(l10n.shoppingClearConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (ok == true) await cubit.clear();
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.checked, required this.total, required this.l10n});

  final int checked;
  final int total;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final value = total == 0 ? 0.0 : checked / total;
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: const Color(0xFFE7E3D9),
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          l10n.shoppingProgress(checked, total),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

/// Total estimé des articles restants (non cochés, hors articles libres) —
/// recalculé en direct à chaque case cochée/décochée ou remplacement par
/// alternative (le prix suit alors l'ingrédient effectivement affiché).
/// État neutre "prix inconnu" si aucun prix n'est connu, plutôt que masqué.
class _ShoppingPriceTotal extends StatelessWidget {
  const _ShoppingPriceTotal({required this.items});

  final List<ShoppingListItem> items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<List<IngredientPrice>>(
      future: sl<IngredientPricesRepository>().fetchMine(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final byId = {for (final p in snapshot.data!) p.ingredientId: p};
        final lines = items.where((i) => !i.isFree && !i.isChecked).map(
              (i) => (
                quantity: i.quantity ?? 0,
                unit: IngredientUnit.fromWire(i.unit ?? 'gramme'),
                ingredientId: i.replacedByAlternativeId ?? i.ingredientId!,
              ),
            );
        final estimate = estimateFromLines(lines, byId);
        if (estimate.totalCount == 0) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.shoppingPriceTotal,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                estimate.isFullyUnknown
                    ? l10n.shoppingPriceUnknown
                    : formatPriceEstimate(estimate.value, isPartial: estimate.isPartial),
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  color: estimate.isFullyUnknown ? AppColors.textMuted : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ViewTabs extends StatelessWidget {
  const _ViewTabs({required this.current, required this.onChanged, required this.l10n});

  final ShoppingView current;
  final ValueChanged<ShoppingView> onChanged;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final tabs = <(ShoppingView, String)>[
      (ShoppingView.byRecipe, l10n.shoppingViewByRecipe),
      (ShoppingView.byAisle, l10n.shoppingViewByAisle),
      (ShoppingView.az, l10n.shoppingViewAz),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (view, label) in tabs) ...[
            GestureDetector(
              onTap: () => onChanged(view),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: view == current ? AppColors.textPrimary : AppColors.card,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: view == current ? AppColors.textPrimary : AppColors.border,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: view == current ? FontWeight.w700 : FontWeight.w600,
                    color: view == current ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.children,
  });

  final String title;
  final String subtitle;
  final Widget leading;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                leading,
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0EEE7)),
          ...children,
        ],
      ),
    );
  }
}

/// Petit titre de rayon (gris, majuscules) au-dessus d'un groupe — vue par rayon.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 2),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: Color(0xFFB0AB9B),
        ),
      ),
    );
  }
}

/// Carte d'articles sans en-tête (vues par rayon / A–Z).
class _PlainCard extends StatelessWidget {
  const _PlainCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.cubit,
    this.quantityForRecipe,
    this.showBreakdown = false,
  });

  final ShoppingListItem item;
  final ShoppingListCubit cubit;
  /// Si fourni, affiche la quantité apportée par cette recette (vue par recette).
  final String? quantityForRecipe;
  /// Vue A–Z : affiche le détail du calcul « X + X + X » sous l'article agrégé.
  final bool showBreakdown;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final double? qty = quantityForRecipe != null
        ? item.sources
              .firstWhere(
                (s) => s.recipeId == quantityForRecipe,
                orElse: () => ShoppingItemSource(recipeId: '', quantity: 0),
              )
              .quantity
        : item.quantity;
    final qtyLabel = shoppingQuantityLabel(l10n, qty, item.unit);

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => cubit.removeItem(item.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 8),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
      ),
      child: InkWell(
        onTap: item.isFree
            ? null
            : () async {
                final choice = await showAlternativeSheet(context, item);
                if (choice != null) {
                  await cubit.setAlternative(
                    item.id,
                    alternativeId: choice.alternativeId,
                    alternativeName: choice.alternativeName,
                  );
                }
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => cubit.setChecked(item.id, !item.isChecked),
                child: _ItemCheck(checked: item.isChecked),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        color: item.isChecked
                            ? const Color(0xFFB0AB9B)
                            : AppColors.textPrimary,
                        decoration:
                            item.isChecked ? TextDecoration.lineThrough : null,
                        decorationColor: AppColors.textSecondary,
                        decorationThickness: 2,
                      ),
                    ),
                    if (item.isReplaced && !item.isChecked)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '↳ ${item.name}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    if (showBreakdown &&
                        item.sources.length >= 2 &&
                        !item.isChecked)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          item.sources
                              .map((s) => shoppingQuantityLabel(
                                    l10n,
                                    s.quantity,
                                    item.unit,
                                  ))
                              .join(' + '),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (!item.isFree && !item.isChecked)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.swap_horiz_rounded,
                      size: 17, color: Color(0xFFC4BEAD)),
                ),
              Text(
                qtyLabel,
                style: TextStyle(
                  fontSize: 12.5,
                  color: item.isChecked
                      ? const Color(0xFFC4BEAD)
                      : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemCheck extends StatelessWidget {
  const _ItemCheck({required this.checked});
  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: checked ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: checked ? null : Border.all(color: AppColors.radioIdle, width: 2),
      ),
      child: checked
          ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
          : null,
    );
  }
}

class _RecipeDot extends StatelessWidget {
  const _RecipeDot({this.photoUrl});
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: AppNetworkImage(photoUrl!, width: 38, height: 38),
      );
    }
    return _fallback();
  }

  Widget _fallback() => Container(
    width: 38,
    height: 38,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(11),
      gradient: const LinearGradient(
        colors: [Color(0xFFC98B6A), Color(0xFFA9603E)],
      ),
    ),
    child: const Icon(Icons.restaurant_rounded, size: 18, color: Colors.white70),
  );
}

class _CartDot extends StatelessWidget {
  const _CartDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.pill,
        borderRadius: BorderRadius.circular(11),
      ),
      child: const Icon(Icons.shopping_cart_outlined,
          size: 18, color: AppColors.textMuted),
    );
  }
}

class _AddItemButton extends StatelessWidget {
  const _AddItemButton({required this.onTap, required this.l10n});
  final VoidCallback onTap;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          backgroundColor: Colors.white.withValues(alpha: 0.55),
          side: const BorderSide(color: Color(0xFFC7BFA9), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onTap,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: Text(
          l10n.shoppingAddItem,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
        ),
      ),
    );
  }
}
