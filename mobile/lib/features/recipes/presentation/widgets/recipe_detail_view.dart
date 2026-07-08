import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/action_menu.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../ingredients/domain/ingredient.dart';
import '../../../ingredients/presentation/widgets/unit_selector.dart';
import '../../../recipe_player/presentation/pages/recipe_player_page.dart';
import '../../../shopping_list/presentation/pages/generate_flow_page.dart';
import '../../domain/recipe.dart';
import '../bloc/recipe_detail_cubit.dart';
import '../pages/recipe_detail_page.dart';
import 'add_ingredients_sheet.dart';
import 'base_recipe_picker_sheet.dart';
import 'category_assign_sheet.dart';
import 'quantity_stepper.dart';
import 'recipe_edit_sheet.dart';
import 'person_assign_sheet.dart';
import 'share_recipe_sheet.dart';
import 'tag_assign_sheet.dart';
import 'steps_content.dart';

const double _kHeroHeight = 300;
// Chevauchement de la fiche par-dessus le bas de la photo (coins arrondis qui
// remontent sur l'image, façon maquette 2d).
const double _kSheetOverlap = 28;

/// Vue de la fiche recette. La photo est fixe en fond ; le titre puis le corps
/// défilent par-dessus (le corps « monte sur l'image »). Même vue pour une
/// recette normale et une recette de base : les sections varient selon `isBase`.
class RecipeDetailView extends StatelessWidget {
  const RecipeDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<RecipeDetailCubit, RecipeDetailState>(
      listenWhen: (_, curr) =>
          curr is RecipeDetailLoaded && (curr.deleted || curr.message != null),
      listener: (context, state) {
        if (state is! RecipeDetailLoaded) return;
        if (state.deleted) {
          Navigator.of(context).pop(true);
          return;
        }
        if (state.message != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message!)));
        }
      },
      // message/deleted sont l'affaire du listener : ne pas reconstruire toute
      // la fiche (photo héro comprise) pour un simple snackbar.
      buildWhen: (previous, current) {
        if (previous is RecipeDetailLoaded && current is RecipeDetailLoaded) {
          return previous.detail != current.detail ||
              previous.busy != current.busy;
        }
        return true;
      },
      builder: (context, state) {
        return switch (state) {
          RecipeDetailError(:final message) => Scaffold(
              appBar: AppBar(),
              body: ErrorView(
                message: message,
                onRetry: () => context.read<RecipeDetailCubit>().load(),
              ),
            ),
          RecipeDetailLoaded(:final detail, :final busy) =>
            _Loaded(detail: detail, busy: busy, l10n: l10n),
          _ => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
        };
      },
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.detail, required this.busy, required this.l10n});

  final RecipeDetail detail;
  final bool busy;
  final AppLocalizations l10n;

  Future<void> _edit(BuildContext context) async {
    final cubit = context.read<RecipeDetailCubit>();
    final result = await showRecipeEditSheet(context, detail: detail);
    if (result == null) return;
    await cubit.updateFields(
      name: result.name,
      description: result.description,
      isBase: result.isBase,
      prepTime: result.prepTime,
      cookTime: result.cookTime,
      restTime: result.restTime,
      servings: result.servings,
    );
  }

  Future<void> _delete(BuildContext context) async {
    final cubit = context.read<RecipeDetailCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.recipeDeleteConfirmTitle),
        content: Text(l10n.recipeDeleteConfirmBody(detail.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed == true) await cubit.delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // Photo fixe en fond, visible uniquement sous la zone transparente.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _kHeroHeight,
            child: _HeroImage(detail: detail),
          ),
          CustomScrollView(
            slivers: [
              // Espace transparent : laisse voir la photo, porte le titre qui
              // défile vers le haut au scroll.
              SliverToBoxAdapter(
                child: SizedBox(
                  height: _kHeroHeight - _kSheetOverlap,
                  child: _HeroTitle(
                    detail: detail,
                    l10n: l10n,
                    onPlay: busy
                        ? null
                        : () => Navigator.of(context)
                            .push(RecipePlayerPage.route(detail.id)),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _Sheet(detail: detail, l10n: l10n),
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _RoundIconButton(
                      icon: Icons.chevron_left_rounded,
                      onTap: () => Navigator.of(context).maybePop(true),
                    ),
                    Builder(
                      builder: (menuContext) => _RoundIconButton(
                        icon: Icons.more_vert_rounded,
                        onTap: busy ? null : () => _openMenu(menuContext),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (busy)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x22000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  /// Menu « … » de la fiche (13b) : action principale en vert, action
  /// destructive isolée en bas. [menuContext] est celui du bouton (ancrage).
  void _openMenu(BuildContext menuContext) {
    showActionMenu(
      context: menuContext,
      items: [
        ActionMenuItem(
          icon: Icons.shopping_cart_outlined,
          label: l10n.recipeMenuAddToShopping,
          style: ActionMenuStyle.primary,
          onSelected: () => _addToShopping(menuContext),
        ),
        ActionMenuItem(
          icon: Icons.edit_outlined,
          label: l10n.commonEdit,
          onSelected: () => _edit(menuContext),
        ),
        ActionMenuItem(
          icon: Icons.ios_share_rounded,
          label: l10n.shareRecipeAction,
          onSelected: () => showShareRecipeSheet(menuContext, detail),
        ),
        ActionMenuItem(
          icon: Icons.folder_outlined,
          label: l10n.recipeMenuAssignFolders,
          dividerBefore: true,
          onSelected: () => showCategoryAssignSheet(
            menuContext,
            cubit: menuContext.read<RecipeDetailCubit>(),
          ),
        ),
        ActionMenuItem(
          icon: Icons.sell_outlined,
          label: l10n.recipeMenuAssignTags,
          onSelected: () => showTagAssignSheet(
            menuContext,
            cubit: menuContext.read<RecipeDetailCubit>(),
          ),
        ),
        ActionMenuItem(
          icon: Icons.person_add_alt_outlined,
          label: l10n.recipeMenuAssignPerson,
          onSelected: () =>
              showPersonAssignSheet(menuContext, recipeId: detail.id),
        ),
        ActionMenuItem(
          icon: Icons.delete_outline_rounded,
          label: l10n.commonDelete,
          style: ActionMenuStyle.destructive,
          dividerBefore: true,
          onSelected: () => _delete(menuContext),
        ),
      ],
    );
  }

  /// Ouvre le flux de génération d'une liste de courses, cette recette
  /// pré-sélectionnée.
  void _addToShopping(BuildContext context) {
    Navigator.of(context).push(
      GenerateFlowPage.route(initialRecipeId: detail.id),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.detail});

  final RecipeDetail detail;

  @override
  Widget build(BuildContext context) {
    final photo = detail.summary.photoUrl;
    return DecoratedBox(
      decoration: BoxDecoration(
        // Placeholder dégradé quand pas de photo (teinte selon le type).
        gradient: photo == null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: detail.isBase
                    ? const [Color(0xFF6B8E5A), Color(0xFF4F6B41)]
                    : const [Color(0xFFC6533F), Color(0xFF7E3322)],
              )
            : null,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Héro plein écran : décodage à la largeur de l'écran.
          if (photo != null)
            AppNetworkImage(photo,
                decodeWidth: MediaQuery.sizeOf(context).width),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x57000000), Color(0x00000000), Color(0xB31F2933)],
                stops: [0, 0.32, 1],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroTitle extends StatelessWidget {
  const _HeroTitle({required this.detail, required this.l10n, this.onPlay});

  final RecipeDetail detail;
  final AppLocalizations l10n;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    final s = detail.summary;
    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (detail.isBase)
                    _Badge(
                      label: l10n.recipeBaseBadge,
                      background: AppColors.primary,
                      foreground: Colors.white,
                      icon: Icons.link_rounded,
                    ),
                  const SizedBox(height: 12),
                  Text(
                    s.name,
                    style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontWeight: FontWeight.w700,
                      fontSize: 28,
                      height: 1.08,
                      letterSpacing: -0.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 16,
                    runSpacing: 6,
                    children: [
                      _MetaItem(icon: Icons.person_outline_rounded, label: l10n.recipeServingsShort(s.servings)),
                      _MetaItem(icon: Icons.schedule_rounded, label: l10n.recipePrepShort(s.prepTime)),
                      _MetaItem(icon: Icons.local_fire_department_outlined, label: l10n.recipeCookShort(s.cookTime)),
                    ],
                  ),
                ],
              ),
            ),
            if (detail.steps.isNotEmpty) ...[
              const SizedBox(width: 12),
              _PlayButton(onTap: onPlay),
            ],
          ],
        ),
      ),
    );
  }
}

class _Sheet extends StatefulWidget {
  const _Sheet({required this.detail, required this.l10n});

  final RecipeDetail detail;
  final AppLocalizations l10n;

  @override
  State<_Sheet> createState() => _SheetState();
}

class _SheetState extends State<_Sheet> {
  /// Portions choisies pour l'affichage (local, éphémère) : fait varier les
  /// quantités affichées sans jamais modifier les données stockées. Repart de
  /// `servings` à chaque ouverture de la fiche.
  late int _portions = widget.detail.summary.servings;

  /// Onglet du segment : 0 = Ingrédients, 1 = Étapes.
  int _tab = 0;

  RecipeDetail get detail => widget.detail;
  AppLocalizations get l10n => widget.l10n;

  /// Base des quantités = `servings` de la recette (jamais 0 : défaut 1).
  int get _base =>
      detail.summary.servings <= 0 ? 1 : detail.summary.servings;

  Future<void> _addIngredients() async {
    final cubit = context.read<RecipeDetailCubit>();
    final drafts = await showAddIngredientsSheet(context);
    if (drafts == null || drafts.isEmpty) return;
    await cubit.addIngredients(drafts);
  }

  Future<void> _editLine(RecipeIngredientLine line) async {
    final cubit = context.read<RecipeDetailCubit>();
    final action = await showModalBottomSheet<_LineAction>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _EditLineSheet(line: line, l10n: l10n),
    );
    if (action == null) return;
    if (action.remove) {
      await cubit.removeIngredient(line.id);
    } else if (action.quantity != null && action.quantity != line.quantity) {
      await cubit.updateIngredientQuantity(line.id, action.quantity!);
    }
  }

  Future<void> _addComponent() async {
    final cubit = context.read<RecipeDetailCubit>();
    final picked = await showBaseRecipePicker(context, excludeRecipeId: detail.id);
    if (picked == null) return;
    await cubit.addComponent(picked.id);
  }

  Future<void> _removeComponent(RecipeSummary component) async {
    final cubit = context.read<RecipeDetailCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.recipeComponentRemove),
        content: Text(l10n.recipeDeleteConfirmBody(component.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed == true) await cubit.removeComponent(component.id);
  }

  @override
  Widget build(BuildContext context) {
    final scale = _portions / _base;
    return Container(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height - _kHeroHeight,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CreatorRow(l10n: l10n),
          if (detail.description != null && detail.description!.isNotEmpty) ...[
            const SizedBox(height: 15),
            Text(
              detail.description!,
              style: const TextStyle(
                  fontSize: 14, height: 1.55, color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 18),
          if (_tab == 0) ...[
            _PortionsCard(
              portions: _portions,
              l10n: l10n,
              onChanged: (v) => setState(() => _portions = v),
            ),
            const SizedBox(height: 16),
          ],
          _IngredientsStepsSegment(
            selected: _tab,
            l10n: l10n,
            onChanged: (i) => setState(() => _tab = i),
          ),
          const SizedBox(height: 12),
          if (_tab == 0)
            ..._ingredientsTab(context, l10n, scale)
          else
            StepsContent(
              detail: detail,
              cubit: context.read<RecipeDetailCubit>(),
            ),
        ],
      ),
    );
  }

  List<Widget> _ingredientsTab(
    BuildContext context,
    AppLocalizations l10n,
    double scale,
  ) {
    return [
      if (detail.ingredients.isEmpty)
        _EmptyHint(message: l10n.recipeIngredientsEmpty)
      else
        for (final ing in detail.ingredients)
          _IngredientRow(
            ingredient: ing,
            scale: scale,
            onTap: () => _editLine(ing),
          ),
      const SizedBox(height: 14),
      _AddIngredientsButton(
        label: l10n.recipeIngredientsAddCta,
        onTap: _addIngredients,
      ),
      _SectionHeader(
          title: l10n.recipeComponentsSection, count: detail.components.length),
      for (final comp in detail.components)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _RecipeLinkCard(
            recipe: comp,
            subtitle: l10n.recipeBaseBadge,
            onTap: () => _openRecipe(context, comp.id),
            onRemove: () => _removeComponent(comp),
          ),
        ),
      _AddIngredientsButton(
        label: l10n.recipeComponentsAddCta,
        onTap: _addComponent,
      ),
      if (detail.isBase && detail.usedIn.isNotEmpty) ...[
        _SectionHeader(
            title: l10n.recipeUsedInSection,
            count: detail.usedIn.length,
            accent: true),
        for (final parent in detail.usedIn)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _RecipeLinkCard(
              recipe: parent,
              onTap: () => _openRecipe(context, parent.id),
            ),
          ),
      ],
    ];
  }

  Future<void> _openRecipe(BuildContext context, String id) async {
    final cubit = context.read<RecipeDetailCubit>();
    await Navigator.of(context).push(RecipeDetailPage.route(id));
    // Au retour, recharge (le graphe de composition a pu changer).
    await cubit.load();
  }
}

/// Sélecteur de portions : fait varier les quantités affichées (scaling local).
class _PortionsCard extends StatelessWidget {
  const _PortionsCard({
    required this.portions,
    required this.l10n,
    required this.onChanged,
  });

  final int portions;
  final AppLocalizations l10n;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.group_rounded, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.recipeServingsSectionTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  l10n.recipeServingsScaleHint,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          _IntStepper(
            value: portions,
            min: 1,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _IntStepper extends StatelessWidget {
  const _IntStepper({
    required this.value,
    required this.min,
    required this.onChanged,
  });

  final int value;
  final int min;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F1EA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SquareButton(
            icon: Icons.remove_rounded,
            background: Colors.white,
            foreground: AppColors.textPrimary,
            elevated: true,
            onTap: value > min ? () => onChanged(value - 1) : null,
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 30),
            alignment: Alignment.center,
            child: Text(
              '$value',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          _SquareButton(
            icon: Icons.add_rounded,
            background: AppColors.primary,
            foreground: Colors.white,
            onTap: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.elevated = false,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap == null ? const Color(0xFFEDEAE1) : background,
      borderRadius: BorderRadius.circular(9),
      elevation: elevated && onTap != null ? 1 : 0,
      shadowColor: AppColors.textPrimary.withValues(alpha: 0.2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: SizedBox(
          width: 30,
          height: 30,
          child: Icon(
            icon,
            size: 18,
            color: onTap == null ? AppColors.textMuted : foreground,
          ),
        ),
      ),
    );
  }
}

/// Segment « Ingrédients | Étapes » (bascule locale de l'onglet actif).
class _IngredientsStepsSegment extends StatelessWidget {
  const _IngredientsStepsSegment({
    required this.selected,
    required this.l10n,
    required this.onChanged,
  });

  final int selected;
  final AppLocalizations l10n;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.pill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _tab(l10n.recipeIngredientsSection, 0),
          _tab(l10n.recipeStepsTab, 1),
        ],
      ),
    );
  }

  Widget _tab(String label, int index) {
    final active = selected == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: active ? FontWeight.w700 : FontWeight.w600,
              color: active ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _AddIngredientsButton extends StatelessWidget {
  const _AddIngredientsButton({required this.label, required this.onTap});

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

/// Action retournée par la feuille d'édition d'une ligne d'ingrédient.
class _LineAction {
  const _LineAction({this.quantity, this.remove = false});

  final double? quantity;
  final bool remove;
}

class _EditLineSheet extends StatefulWidget {
  const _EditLineSheet({required this.line, required this.l10n});

  final RecipeIngredientLine line;
  final AppLocalizations l10n;

  @override
  State<_EditLineSheet> createState() => _EditLineSheetState();
}

class _EditLineSheetState extends State<_EditLineSheet> {
  late double _quantity = widget.line.quantity;

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final unit = IngredientUnit.fromWire(widget.line.unit);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
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
            const SizedBox(height: 18),
            Text(
              widget.line.name,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w700,
                fontSize: 20,
                letterSpacing: -0.3,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.recipeIngredientQuantityTitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                QuantityStepper(
                  quantity: _quantity,
                  unit: unit,
                  onChanged: (q) => setState(() => _quantity = q),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () => Navigator.of(context)
                    .pop(_LineAction(quantity: _quantity)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  l10n.commonSave,
                  style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton.icon(
                onPressed: () =>
                    Navigator.of(context).pop(const _LineAction(remove: true)),
                icon: const Icon(Icons.delete_outline_rounded, size: 19),
                label: Text(l10n.recipeIngredientRemove),
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatorRow extends StatelessWidget {
  const _CreatorRow({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    // La fiche est toujours celle de l'utilisateur courant (liste "mes recettes").
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.primaryTint,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 11),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.recipeCreatorLabel,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            Text(
              l10n.recipeCreatorSelf,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          ],
        ),
      ],
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    required this.ingredient,
    required this.scale,
    required this.onTap,
  });

  final RecipeIngredientLine ingredient;

  /// Facteur de mise à l'échelle (portions / servings) appliqué à l'affichage.
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unit = IngredientUnit.fromWire(ingredient.unit);
    final shownQuantity = (ingredient.quantity * scale * 100).round() / 100;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 2),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.pill,
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: ingredient.imageUrl != null
                  ? AppNetworkImage(ingredient.imageUrl!, width: 40, height: 40)
                  : const Icon(Icons.egg_alt_outlined,
                      size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                ingredient.name,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              formatQuantityWithUnit(l10n, shownQuantity, unit),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4B5563),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeLinkCard extends StatelessWidget {
  const _RecipeLinkCard({
    required this.recipe,
    this.subtitle,
    required this.onTap,
    this.onRemove,
  });

  final RecipeSummary recipe;
  final String? subtitle;
  final VoidCallback onTap;

  /// Si fourni, affiche un bouton de retrait à la place du chevron.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accentTint,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.restaurant_rounded,
                    size: 20, color: AppColors.accent),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.link_rounded,
                                size: 13, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              subtitle!,
                              style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close_rounded,
                      size: 20, color: AppColors.danger),
                  tooltip: AppLocalizations.of(context).recipeComponentRemove,
                  visualDensity: VisualDensity.compact,
                )
              else
                const Icon(Icons.chevron_right_rounded,
                    size: 20, color: Color(0xFFC4C0B5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count, this.accent = false});

  final String title;
  final int count;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 12),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: accent ? AppColors.accentTint : AppColors.primaryTint,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: accent ? AppColors.accent : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: const TextStyle(fontSize: 13.5, height: 1.45, color: AppColors.textMuted),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: foreground),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: foreground),
          ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.white),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
        ),
      ],
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Tooltip(
      message: l10n.recipePlayCta,
      child: Material(
        color: AppColors.accent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: const SizedBox(
            width: 44,
            height: 44,
            child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: AppColors.textPrimary, size: 22),
        ),
      ),
    );
  }
}
