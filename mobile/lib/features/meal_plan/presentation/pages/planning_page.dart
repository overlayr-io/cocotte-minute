import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/premium/premium_cubit.dart';
import '../../../../core/premium/premium_limit_sheet.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../premium/presentation/pages/premium_page.dart';
import '../../../recipes/data/recipes_repository.dart';
import '../../data/meal_plan_repository.dart';
import '../../data/meal_plan_tray_store.dart';
import '../../domain/meal_plan_entry.dart';
import '../../../../core/widgets/action_menu.dart';
import '../../../recipes/presentation/pages/recipe_detail_page.dart';
import '../../../shopping_list/data/shopping_list_api.dart';
import '../../../shopping_list/data/shopping_list_repository.dart';
import '../bloc/meal_plan_cubit.dart';
import '../widgets/add_entry_sheet.dart';
import '../widgets/meal_entry_visuals.dart';
import '../widgets/planning_boards.dart';
import '../widgets/planning_tray.dart';
import '../widgets/slot_detail_sheet.dart';
import '../widgets/tray_picker_sheet.dart';

/// Onglet Planning : calendrier semaine lundi → dimanche, 3 créneaux par jour
/// (cf. docs/features/planification-repas.md, écrans 1a-1g).
class PlanningPage extends StatelessWidget {
  const PlanningPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MealPlanCubit(
        repository: sl<MealPlanRepository>(),
        recipesRepository: sl<RecipesRepository>(),
        trayStore: sl<MealPlanTrayStore>(),
      )..load(),
      child: const _PlanningView(),
    );
  }
}

class _PlanningView extends StatelessWidget {
  const _PlanningView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isPremium = context.select<PremiumCubit, bool>(
      (c) => c.state.isPremium,
    );

    return BlocConsumer<MealPlanCubit, MealPlanState>(
      listener: (context, state) {
        final cubit = context.read<MealPlanCubit>();
        if (state.premiumLimit != null) {
          final error = state.premiumLimit!;
          cubit.acknowledge();
          showPremiumLimitSheet(context, error: error);
        } else if (state.removedEntry != null) {
          final entry = state.removedEntry!;
          cubit.acknowledge();
          _showUndoSnackBar(context, l10n, entry);
        } else if (state.actionError != null) {
          final message = state.actionError!;
          cubit.acknowledge();
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(message),
                duration: const Duration(seconds: 3),
              ),
            );
        }
      },
      builder: (context, state) {
        final cubit = context.read<MealPlanCubit>();

        if (state.status == MealPlanStatus.loading ||
            state.status == MealPlanStatus.initial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == MealPlanStatus.error) {
          return ErrorView(
            message: state.loadError ?? '',
            onRetry: cubit.load,
          );
        }

        final week = state.visibleWeek;
        final readonly = !isPremium && !week.isFreeEditable;

        final boardData = PlanningBoardData(
          week: week,
          entriesOf: state.slotEntries,
          readonly: readonly,
          selectMode: state.selectMode,
          selectedSlots: state.selectedSlots,
          onToggleSelect: cubit.toggleSlotSelected,
          onAddToSlot: (day, slot) => _openAddSheet(context, day, slot),
          onDropRecipe: (day, slot, recipe) =>
              cubit.addRecipe(day: day, slot: slot, recipeId: recipe.id),
          onTapSlot: (cellContext, day, slot) =>
              _onTapSlot(cellContext, context, day, slot, isPremium, readonly),
        );

        final emptyHook =
            state.visibleEntries.isEmpty && !readonly && !state.selectMode
            ? const _FirstUseHook()
            : null;

        return Scaffold(
          backgroundColor: AppColors.surface,
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state.selectMode)
                  const _SelectModeAppBar()
                else
                  _PlanningAppBar(readonly: readonly),
                if (state.layout == PlanningLayout.grid)
                  const PlanningGridHeader(),
                Expanded(
                  child: state.weekLoading
                      ? const Center(child: CircularProgressIndicator())
                      : state.layout == PlanningLayout.grid
                      ? PlanningGridBoard(data: boardData, header: emptyHook)
                      : PlanningBlocksBoard(data: boardData, header: emptyHook),
                ),
                if (!state.selectMode && !readonly)
                  PlanningTray(
                    recipes: state.tray,
                    onManage: () => _openTrayPicker(context),
                  ),
                if (state.selectMode)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                    child: _SelectFab(
                      count: state.selectedRecipeCount,
                      onPressed: state.selectedRecipeCount == 0
                          ? null
                          : () => _addSelectionToShopping(context, isPremium),
                    ),
                  ),
                // Espace pour la barre de navigation flottante du shell.
                const SizedBox(height: 90),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Tap sur un créneau rempli : menu contextuel (3a) pour une entrée seule,
  /// sheet détail (1g) pour un créneau multi-recettes.
  void _onTapSlot(
    BuildContext cellContext,
    BuildContext pageContext,
    String day,
    MealSlot slot,
    bool isPremium,
    bool readonly,
  ) {
    final cubit = pageContext.read<MealPlanCubit>();
    final l10n = AppLocalizations.of(pageContext);
    final entries = cubit.state.slotEntries(day, slot);
    if (entries.isEmpty) return;

    if (entries.length > 1) {
      final locale = Localizations.localeOf(pageContext).toString();
      final date = DateTime.parse(day);
      showSlotDetailSheet(
        pageContext,
        slotLabel:
            '${longWeekday(locale, date)} ${date.day} · ${mealSlotLabel(l10n, slot)}',
        entries: entries,
        canEdit: !readonly,
        canAdd: isPremium && !readonly,
        onRemove: cubit.removeEntry,
        onAdd: () => _openAddSheet(pageContext, day, slot),
      );
      return;
    }

    final entry = entries.first;
    showActionMenu(
      context: cellContext,
      items: [
        if (entry.type == MealEntryType.recipe && entry.recipe != null)
          ActionMenuItem(
            icon: Icons.visibility_outlined,
            label: l10n.planningMenuView,
            onSelected: () => Navigator.of(
              pageContext,
            ).push(RecipeDetailPage.route(entry.recipe!.id)),
          ),
        if (isPremium && !readonly)
          ActionMenuItem(
            icon: Icons.add,
            label: l10n.planningMenuAdd,
            style: ActionMenuStyle.primary,
            onSelected: () => _openAddSheet(pageContext, day, slot),
          ),
        if (!readonly)
          ActionMenuItem(
            icon: Icons.delete_outline,
            label: l10n.planningMenuRemove,
            style: ActionMenuStyle.destructive,
            onSelected: () => cubit.removeEntry(entry),
          ),
      ],
    );
  }

  /// « + » sur un créneau vide → sheet de choix (2a/2c) puis ajout.
  Future<void> _openAddSheet(
    BuildContext context,
    String day,
    MealSlot slot,
  ) async {
    final cubit = context.read<MealPlanCubit>();
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final date = DateTime.parse(day);
    final slotLabel =
        '${longWeekday(locale, date)} ${date.day} · ${mealSlotLabel(l10n, slot)}';

    final choice = await showAddEntrySheet(context, slotLabel: slotLabel);
    switch (choice) {
      case AddRecipeChoice(:final recipe):
        await cubit.addRecipe(day: day, slot: slot, recipeId: recipe.id);
      case AddEatingOutChoice():
        await cubit.addEatingOut(day: day, slot: slot);
      case AddNoteChoice(:final text):
        await cubit.addNote(day: day, slot: slot, text: text);
      case null:
        break;
    }
  }

  /// Bouton flottant 4a : envoie les recettes des créneaux cochés vers la
  /// liste de courses. Gratuit : remplace la liste active (confirmation si
  /// non vide, 4b). Premium : crée toujours une nouvelle liste dédiée (4c).
  Future<void> _addSelectionToShopping(
    BuildContext context,
    bool isPremium,
  ) async {
    final cubit = context.read<MealPlanCubit>();
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final recipes = cubit.selectedRecipes().values.toList();
    if (recipes.isEmpty) return;
    final weekLabel = cubit.state.visibleWeek.label(locale);
    final shopping = sl<ShoppingListRepository>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      if (!isPremium) {
        final lists = await shopping.watchActiveLists().first;
        final active = lists.isEmpty ? null : lists.first;
        if (active != null && active.itemCount > 0) {
          if (!context.mounted) return;
          final confirmed = await _showReplaceDialog(context, l10n);
          if (confirmed != true) return;
        }
        if (active != null) await shopping.clear(active.id);
      }
      await shopping.generate(
        name: l10n.planningShoppingName(weekLabel),
        recipes: [for (final r in recipes) (recipeId: r.id, servings: r.servings)],
        pantryIngredientIds: const [],
      );
      cubit.exitSelectMode();
      _showShoppingToast(
        messenger,
        title: isPremium
            ? l10n.planningListCreatedTitle(weekLabel)
            : l10n.planningListUpdatedTitle,
        subtitle: isPremium
            ? l10n.planningListCreatedSub
            : l10n.planningListUpdatedSub(weekLabel),
      );
    } on ShoppingListApiException catch (e) {
      if (!context.mounted) return;
      if (e.premiumLimit != null) {
        showPremiumLimitSheet(context, error: e.premiumLimit!);
      } else {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(e.message),
              duration: const Duration(seconds: 3),
            ),
          );
      }
    }
  }

  /// Dialog « Remplacer la liste en cours ? » (écran 4b).
  Future<bool?> _showReplaceDialog(BuildContext context, AppLocalizations l10n) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFBEEE9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.shopping_cart_outlined,
                  size: 24,
                  color: Color(0xFFC0544A),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.planningReplaceTitle,
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  letterSpacing: -0.4,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.planningReplaceBody,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(
                            color: Color(0xFFE3DECF),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          l10n.commonCancel,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                            color: Color(0xFF3F4650),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: FilledButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFC0544A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          l10n.planningReplaceConfirm,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Toast de succès (4c) : fond vert sombre + coche dorée, titre + sous-titre.
  void _showShoppingToast(
    ScaffoldMessengerState messenger, {
    required String title,
    required String subtitle,
  }) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 96),
          backgroundColor: const Color(0xFF2E3B2A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: const Color(0xFFD9C48A).withValues(alpha: 0.25),
            ),
          ),
          duration: const Duration(milliseconds: 2600),
          content: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.premiumGold, AppColors.premiumGoldDark],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.check, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }

  Future<void> _openTrayPicker(BuildContext context) async {
    final cubit = context.read<MealPlanCubit>();
    final ids = await showTrayPickerSheet(
      context,
      initialIds: [for (final r in cubit.state.tray) r.id],
    );
    if (ids != null) await cubit.setTray(ids);
  }

  void _showUndoSnackBar(
    BuildContext context,
    AppLocalizations l10n,
    MealPlanEntry entry,
  ) {
    final cubit = context.read<MealPlanCubit>();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 96),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          backgroundColor: AppColors.textPrimary,
          duration: const Duration(milliseconds: 4000),
          // Sans `persist: false`, Flutter rend le snackbar persistant dès
          // qu'il porte une `action` (persist = persist ?? action != null) et
          // ignore la `duration` : le toast restait affiché indéfiniment.
          persist: false,
          content: Text(
            entry.type == MealEntryType.recipe
                ? l10n.planningRemovedSnackRecipe
                : l10n.planningRemovedSnackOther,
          ),
          action: SnackBarAction(
            label: l10n.planningUndo,
            textColor: const Color(0xFF8CB47A),
            onPressed: cubit.undoRemove,
          ),
        ),
      );
  }
}

/// En-tête du mode sélection vers les courses (écran 4a).
class _SelectModeAppBar extends StatelessWidget {
  const _SelectModeAppBar();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<MealPlanCubit>();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      decoration: const BoxDecoration(
        color: kPlanningHeaderBg,
        border: Border(bottom: BorderSide(color: kPlanningHairline)),
      ),
      child: Row(
        children: [
          _RoundIconButton(
            icon: Icons.close,
            color: AppColors.textPrimary,
            onTap: cubit.exitSelectMode,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.planningSelectTitle,
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  l10n.planningSelectSubtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
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

/// Bouton flottant récapitulatif du mode sélection (écran 4a).
class _SelectFab extends StatelessWidget {
  const _SelectFab({required this.count, required this.onPressed});

  final int count;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final disabled = onPressed == null;
    return SizedBox(
      height: 56,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: const Color(0xFFC9C3B4),
          disabledForegroundColor: Colors.white,
          elevation: disabled ? 0 : 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_cart_outlined, size: 20),
            const SizedBox(width: 9),
            Text(
              l10n.planningSelectCta(count),
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w700,
                fontSize: 15.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// En-tête : titre, bascule Grille/Blocs, panier, navigation de semaine et
/// bandeau lecture seule (design 1a / 1f).
class _PlanningAppBar extends StatelessWidget {
  const _PlanningAppBar({required this.readonly});

  final bool readonly;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<MealPlanCubit>();
    final state = context.watch<MealPlanCubit>().state;

    return Container(
      color: kPlanningHeaderBg,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.navPlanning,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8A7A4E),
                      ),
                    ),
                    Text(
                      l10n.planningTitle,
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w700,
                        fontSize: 23,
                        height: 1.05,
                        letterSpacing: -0.4,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              _LayoutToggle(layout: state.layout, onChanged: cubit.setLayout),
              const SizedBox(width: 10),
              _RoundIconButton(
                icon: Icons.shopping_cart_outlined,
                color: AppColors.primaryDark,
                tooltip: l10n.planningCartTooltip,
                onTap: cubit.enterSelectMode,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _WeekNav(state: state, onSelect: cubit.selectWeek),
          if (readonly) ...[
            const SizedBox(height: 10),
            const _ReadonlyBanner(),
          ],
        ],
      ),
    );
  }
}

class _WeekNav extends StatelessWidget {
  const _WeekNav({required this.state, required this.onSelect});

  final MealPlanState state;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final week = state.visibleWeek;
    final canPrev = state.weekIndex > 0;
    final canNext = state.weekIndex < state.weeks.length - 1;
    final sub = switch (week.offset) {
      0 => l10n.planningWeekCurrent,
      1 => l10n.planningWeekNext,
      _ => l10n.planningWeekOther,
    };

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.pill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _NavChevron(
            icon: Icons.chevron_left,
            enabled: canPrev,
            onTap: () => onSelect(state.weekIndex - 1),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  week.label(locale),
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  sub.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: week.offset == 0
                        ? AppColors.primaryDark
                        : const Color(0xFFA79F8B),
                  ),
                ),
              ],
            ),
          ),
          _NavChevron(
            icon: Icons.chevron_right,
            enabled: canNext,
            onTap: () => onSelect(state.weekIndex + 1),
          ),
        ],
      ),
    );
  }
}

class _NavChevron extends StatelessWidget {
  const _NavChevron({required this.icon, required this.enabled, required this.onTap});

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.35,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: enabled ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Icon(icon, size: 22, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _LayoutToggle extends StatelessWidget {
  const _LayoutToggle({required this.layout, required this.onChanged});

  final PlanningLayout layout;
  final ValueChanged<PlanningLayout> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.pill,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          _segment(
            icon: Icons.grid_view_rounded,
            selected: layout == PlanningLayout.grid,
            tooltip: l10n.planningLayoutGrid,
            onTap: () => onChanged(PlanningLayout.grid),
          ),
          const SizedBox(width: 2),
          _segment(
            icon: Icons.table_rows_rounded,
            selected: layout == PlanningLayout.blocks,
            tooltip: l10n.planningLayoutBlocks,
            onTap: () => onChanged(PlanningLayout.blocks),
          ),
        ],
      ),
    );
  }

  Widget _segment({
    required IconData icon,
    required bool selected,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 32,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 17,
            color: selected ? AppColors.textPrimary : const Color(0xFFA79F8B),
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// Bandeau lecture seule (gratuit hors T/T+1, écran 1f).
class _ReadonlyBanner extends StatelessWidget {
  const _ReadonlyBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EEDF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEADFC4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, size: 18, color: Color(0xFF9A7327)),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              l10n.planningReadonlyBanner,
              style: const TextStyle(
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8A6E27),
              ),
            ),
          ),
          const SizedBox(width: 9),
          GestureDetector(
            onTap: () => Navigator.of(context).push(PremiumPage.route()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFB8862F),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                l10n.planningReadonlyCta,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Accroche première utilisation (semaine vierge, écran 1e).
class _FirstUseHook extends StatelessWidget {
  const _FirstUseHook();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEEF3E9), AppColors.surface],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE7D2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.planningEmptyTitle,
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w700,
                    fontSize: 15.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.planningEmptyBody,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: Color(0xFF5B6470),
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
