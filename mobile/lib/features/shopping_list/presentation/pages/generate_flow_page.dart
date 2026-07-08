import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../recipes/data/recipes_repository.dart';
import '../../../recipes/domain/recipe.dart';
import '../../data/shopping_list_repository.dart';
import '../bloc/generate_shopping_list_cubit.dart';
import '../widgets/shopping_format.dart';
import 'shopping_list_detail_page.dart';

/// Assistant de génération d'une liste de courses (écrans 5b → 5d).
class GenerateFlowPage extends StatelessWidget {
  const GenerateFlowPage({super.key, this.hasActive = false});

  final bool hasActive;

  static Route<void> route({bool hasActive = false}) => MaterialPageRoute<void>(
    builder: (_) => GenerateFlowPage(hasActive: hasActive),
  );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GenerateShoppingListCubit(
        recipesRepository: sl<RecipesRepository>(),
        shoppingRepository: sl<ShoppingListRepository>(),
      ),
      child: _GenerateView(hasActive: hasActive),
    );
  }
}

class _GenerateView extends StatelessWidget {
  const _GenerateView({required this.hasActive});

  final bool hasActive;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: BlocConsumer<GenerateShoppingListCubit, GenerateState>(
          listenWhen: (p, c) =>
              p.generatedListId != c.generatedListId ||
              p.actionError != c.actionError,
          listener: (context, state) {
            if (state.generatedListId != null) {
              Navigator.of(context).pushReplacement(
                ShoppingListDetailPage.route(state.generatedListId!),
              );
            } else if (state.actionError != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.actionError!)));
            }
          },
          builder: (context, state) {
            switch (state.phase) {
              case GeneratePhase.loadingRecipes:
                return const Center(child: CircularProgressIndicator());
              case GeneratePhase.error:
                return _ErrorView(message: state.errorMessage ?? '');
              case GeneratePhase.ready:
                if (state.recipes.isEmpty) {
                  return _NoRecipes(l10n: l10n);
                }
                return _Wizard(l10n: l10n, hasActive: hasActive);
            }
          },
        ),
      ),
    );
  }
}

class _Wizard extends StatelessWidget {
  const _Wizard({required this.l10n, required this.hasActive});

  final AppLocalizations l10n;
  final bool hasActive;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GenerateShoppingListCubit>();
    final state = context.watch<GenerateShoppingListCubit>().state;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _SquareButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: () => state.step > 1
                        ? cubit.back()
                        : Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n.shoppingStepLabel(state.step, 3),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _StepBar(step: state.step),
            ],
          ),
        ),
        Expanded(
          child: switch (state.step) {
            1 => _StepRecipes(l10n: l10n, hasActive: hasActive),
            2 => _StepServings(l10n: l10n),
            _ => _StepPantry(l10n: l10n),
          },
        ),
      ],
    );
  }
}

class _StepBar extends StatelessWidget {
  const _StepBar({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 1; i <= 3; i++) ...[
          Expanded(
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                color: i <= step ? AppColors.primary : const Color(0xFFE3DECF),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          if (i < 3) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

// --- Étape 1 : choix des recettes (5b) ---------------------------------------

class _StepRecipes extends StatelessWidget {
  const _StepRecipes({required this.l10n, required this.hasActive});

  final AppLocalizations l10n;
  final bool hasActive;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GenerateShoppingListCubit>();
    final state = context.watch<GenerateShoppingListCubit>().state;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
            children: [
              Text(
                l10n.shoppingStep1Title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.shoppingStep1Subtitle,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              for (final recipe in state.recipes) ...[
                _RecipeSelectTile(
                  recipe: recipe,
                  selected: state.selectedIds.contains(recipe.id),
                  onTap: () => cubit.toggleRecipe(recipe),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
        _BottomBar(
          child: FilledButton(
            style: _primaryButtonStyle(),
            onPressed: state.selectedCount == 0 ? null : cubit.next,
            child: Text(l10n.shoppingContinueWithCount(state.selectedCount)),
          ),
        ),
      ],
    );
  }
}

class _RecipeSelectTile extends StatelessWidget {
  const _RecipeSelectTile({
    required this.recipe,
    required this.selected,
    required this.onTap,
  });

  final RecipeSummary recipe;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF3F7EF) : AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            _RecipeThumb(photoUrl: recipe.photoUrl, size: 56),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                recipe.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.primary : Colors.transparent,
                border: selected
                    ? null
                    : Border.all(color: AppColors.radioIdle, width: 2),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// --- Étape 2 : nombre de parts (5c) ------------------------------------------

class _StepServings extends StatelessWidget {
  const _StepServings({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GenerateShoppingListCubit>();
    final state = context.watch<GenerateShoppingListCubit>().state;
    final selected =
        state.recipes.where((r) => state.selectedIds.contains(r.id)).toList();
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
            children: [
              Text(
                l10n.shoppingStep2Title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.shoppingStep2Subtitle,
                style: const TextStyle(fontSize: 13.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: 18),
              for (final recipe in selected) ...[
                _ServingsCard(
                  recipe: recipe,
                  value: state.servings[recipe.id] ?? recipe.servings,
                  onChanged: (v) => cubit.setServings(recipe.id, v),
                  l10n: l10n,
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                decoration: BoxDecoration(
                  color: AppColors.pill,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF8A7A4E)),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        l10n.shoppingTotalServings(
                          state.totalServings,
                          selected.length,
                        ),
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _BottomBar(
          child: FilledButton(
            style: _primaryButtonStyle(),
            onPressed: cubit.next,
            child: Text(l10n.shoppingContinue),
          ),
        ),
      ],
    );
  }
}

class _ServingsCard extends StatelessWidget {
  const _ServingsCard({
    required this.recipe,
    required this.value,
    required this.onChanged,
    required this.l10n,
  });

  final RecipeSummary recipe;
  final int value;
  final ValueChanged<int> onChanged;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _RecipeThumb(photoUrl: recipe.photoUrl, size: 50),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.shoppingBaseServings(recipe.servings),
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          _Stepper(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundStep(
          icon: Icons.remove_rounded,
          filled: false,
          onTap: value > 1 ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 34,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _RoundStep(
          icon: Icons.add_rounded,
          filled: true,
          onTap: () => onChanged(value + 1),
        ),
      ],
    );
  }
}

class _RoundStep extends StatelessWidget {
  const _RoundStep({required this.icon, required this.filled, this.onTap});

  final IconData icon;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: filled
          ? (enabled ? AppColors.primary : AppColors.radioIdle)
          : Colors.white,
      shape: filled
          ? const CircleBorder()
          : const CircleBorder(
              side: BorderSide(color: AppColors.divider, width: 1.5),
            ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            icon,
            size: 18,
            color: filled ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

// --- Étape 3 : placard (5d) --------------------------------------------------

class _StepPantry extends StatelessWidget {
  const _StepPantry({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GenerateShoppingListCubit>();
    final state = context.watch<GenerateShoppingListCubit>().state;
    if (state.loadingIngredients) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
            children: [
              Text(
                l10n.shoppingStep3Title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.shoppingStep3Subtitle,
                style: const TextStyle(fontSize: 13.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: 10),
              for (final ing in state.ingredients)
                _PantryRow(
                  ingredient: ing,
                  inStock: state.pantryIds.contains(ing.id),
                  onTap: () => cubit.togglePantry(ing.id),
                  l10n: l10n,
                ),
            ],
          ),
        ),
        _BottomBar(
          child: FilledButton.icon(
            style: _primaryButtonStyle(),
            onPressed: state.generating
                ? null
                : () => cubit.generate(l10n.shoppingDefaultListName),
            icon: state.generating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.auto_awesome_rounded, size: 20),
            label: Text(l10n.shoppingGenerateWithCount(state.itemsToBuy)),
          ),
        ),
      ],
    );
  }
}

class _PantryRow extends StatelessWidget {
  const _PantryRow({
    required this.ingredient,
    required this.inStock,
    required this.onTap,
    required this.l10n,
  });

  final PantryIngredient ingredient;
  final bool inStock;
  final VoidCallback onTap;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF0EEE7))),
        ),
        child: Row(
          children: [
            _CheckBox(checked: inStock),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ingredient.name,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: inStock ? const Color(0xFFB0AB9B) : AppColors.textPrimary,
                      decoration: inStock ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    shoppingQuantityLabel(l10n, ingredient.quantity, ingredient.unit),
                    style: TextStyle(
                      fontSize: 12,
                      color: inStock ? const Color(0xFFC4BEAD) : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (inStock)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  l10n.shoppingInStock,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// --- widgets partagés du flow ------------------------------------------------

class _CheckBox extends StatelessWidget {
  const _CheckBox({required this.checked});
  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: checked ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: checked
            ? null
            : Border.all(color: AppColors.radioIdle, width: 2),
      ),
      child: checked
          ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
          : null,
    );
  }
}

class _RecipeThumb extends StatelessWidget {
  const _RecipeThumb({required this.photoUrl, required this.size});
  final String? photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size < 54 ? 13 : 14);
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.network(
          photoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _placeholder(radius),
        ),
      );
    }
    return _placeholder(radius);
  }

  Widget _placeholder(BorderRadius radius) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      borderRadius: radius,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF7D9C6A), Color(0xFF5E7F4F)],
      ),
    ),
    child: const Icon(Icons.restaurant_rounded, color: Colors.white70, size: 22),
  );
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
      child: SizedBox(width: double.infinity, height: 56, child: child),
    );
  }
}

ButtonStyle _primaryButtonStyle() => FilledButton.styleFrom(
  backgroundColor: AppColors.accent,
  foregroundColor: Colors.white,
  disabledBackgroundColor: const Color(0xFFF3B7B0),
  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
);

class _NoRecipes extends StatelessWidget {
  const _NoRecipes({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _SquareButton(
              icon: Icons.chevron_left_rounded,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.menu_book_outlined, size: 48, color: AppColors.textMuted),
                  const SizedBox(height: 14),
                  Text(
                    l10n.shoppingNoRecipesTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.shoppingNoRecipesBody,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<GenerateShoppingListCubit>();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 44, color: AppColors.textMuted),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: cubit.retry,
              child: Text(l10n.commonRetry),
            ),
          ],
        ),
      ),
    );
  }
}
