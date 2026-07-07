import 'package:flutter/material.dart';

import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/recipe.dart';
import '../bloc/recipe_detail_cubit.dart';
import 'import_steps_sheet.dart';
import 'step_banner.dart';
import 'step_editor_sheet.dart';
import 'step_ingredients_sheet.dart';

/// Contenu de l'onglet « Étapes » : état vide (9c) ou liste réordonnable (9b).
class StepsContent extends StatefulWidget {
  const StepsContent({
    super.key,
    required this.detail,
    required this.cubit,
  });

  final RecipeDetail detail;
  final RecipeDetailCubit cubit;

  @override
  State<StepsContent> createState() => _StepsContentState();
}

class _StepsContentState extends State<StepsContent> {
  late List<RecipeStep> _steps = [...widget.detail.steps];

  @override
  void didUpdateWidget(StepsContent old) {
    super.didUpdateWidget(old);
    // Resync après un rechargement de la fiche (ajout/suppression/édition/reorder).
    if (old.detail.steps != widget.detail.steps) {
      _steps = [...widget.detail.steps];
    }
  }

  String get _recipeId => widget.detail.id;

  /// Nombre d'étapes « feuilles » affichées (texte + sous-étapes des références).
  int get _leafCount => _steps.fold(0, (acc, s) {
        return acc + (s is RecipeBaseRefStep ? s.steps.length : 1);
      });

  Future<void> _import() async {
    final descriptions = await showImportStepsSheet(context);
    if (descriptions == null || descriptions.isEmpty) return;
    await widget.cubit.importSteps(descriptions);
  }

  Future<void> _addOneByOne() async {
    await showStepEditorSheet(
      context,
      cubit: widget.cubit,
      recipeId: _recipeId,
      recipeIngredients: widget.detail.ingredients,
      addStartNumber: _leafCount + 1,
      alreadyAdded: _leafCount,
    );
  }

  Future<void> _editStep(RecipeTextStep step, int number) async {
    await showStepEditorSheet(
      context,
      cubit: widget.cubit,
      recipeId: _recipeId,
      recipeIngredients: widget.detail.ingredients,
      edit: step,
      editNumber: number,
    );
  }

  Future<void> _removeBaseRef(RecipeBaseRefStep step) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _RemoveRefSheet(name: step.baseRecipeName),
    );
    if (confirmed == true) {
      await widget.cubit.removeStep(step.id);
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final moved = _steps.removeAt(oldIndex);
      _steps.insert(newIndex, moved);
    });
    widget.cubit.reorderSteps(_steps.map((s) => s.id).toList());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_steps.isEmpty) {
      return _EmptyState(onPaste: _import, onOneByOne: _addOneByOne);
    }

    // Numérotation globale continue calculée à l'affichage (résiste au reorder).
    var counter = 0;
    final numbers = <int>[];
    for (final s in _steps) {
      numbers.add(counter + 1);
      counter += s is RecipeBaseRefStep ? s.steps.length : 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReorderableListView.builder(
          shrinkWrap: true,
          primary: false,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: _steps.length,
          onReorder: _onReorder,
          itemBuilder: (context, i) {
            final step = _steps[i];
            return _StepItem(
              key: ValueKey(step.id),
              index: i,
              startNumber: numbers[i],
              step: step,
              isLast: i == _steps.length - 1,
              onEditText: (n) => _editStep(step as RecipeTextStep, n),
              onRemoveRef: () => _removeBaseRef(step as RecipeBaseRefStep),
              onShowIngredients: (n) {
                final text = step as RecipeTextStep;
                showStepIngredientsModal(
                  context,
                  number: n,
                  description: text.description,
                  ingredients: text.ingredients,
                );
              },
            );
          },
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _addOneByOne,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(l10n.recipeStepsAddCta,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: Color(0xFFC4BEAD), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ),
        ),
      ],
    );
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({
    super.key,
    required this.index,
    required this.startNumber,
    required this.step,
    required this.isLast,
    required this.onEditText,
    required this.onRemoveRef,
    required this.onShowIngredients,
  });

  final int index;
  final int startNumber;
  final RecipeStep step;
  final bool isLast;
  final void Function(int number) onEditText;
  final VoidCallback onRemoveRef;
  final void Function(int number) onShowIngredients;

  @override
  Widget build(BuildContext context) {
    final s = step;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (s is RecipeTextStep)
          _textStep(context, s)
        else if (s is RecipeBaseRefStep)
          _baseRefStep(context, s),
        if (!isLast) const Divider(height: 1, thickness: 1, color: Color(0xFFEEEAE0)),
      ],
    );
  }

  Widget _grip() => ReorderableDragStartListener(
        index: index,
        child: const Padding(
          padding: EdgeInsets.only(left: 6, top: 2),
          child: Icon(Icons.drag_indicator_rounded, size: 20, color: Color(0xFFCBC7BB)),
        ),
      );

  Widget _textStep(BuildContext context, RecipeTextStep step) {
    final l10n = AppLocalizations.of(context);
    return InkWell(
      onTap: () => onEditText(startNumber),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _NumberGutter(number: startNumber, big: true),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.description,
                    style: const TextStyle(
                        fontSize: 14.5, height: 1.5, color: Color(0xFF33404B)),
                  ),
                  if (step.banner != null) StepBannerBox(banner: step.banner!),
                  if (step.ingredients.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: GestureDetector(
                        onTap: () => onShowIngredients(startNumber),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.shopping_basket_outlined,
                                size: 15, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              l10n.recipeStepIngredientsChip(step.ingredients.length),
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            _grip(),
          ],
        ),
      ),
    );
  }

  Widget _baseRefStep(BuildContext context, RecipeBaseRefStep step) {
    final l10n = AppLocalizations.of(context);
    // Numérotation continue des sous-étapes figées.
    var n = startNumber;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.link_rounded, size: 15, color: Color(0xFF5C7A4C)),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: onRemoveRef,
                  child: Text(
                    l10n.recipeStepBaseRefLabel(step.baseRecipeName),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF5C7A4C),
                    ),
                  ),
                ),
              ),
              _grip(),
            ],
          ),
          const SizedBox(height: 12),
          for (final sub in step.steps) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _NumberGutter(number: n++, big: false),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sub.description,
                          style: const TextStyle(
                              fontSize: 14, height: 1.5, color: Color(0xFF3F4E37)),
                        ),
                        if (sub.banner != null) StepBannerBox(banner: sub.banner!),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          Row(
            children: [
              const Icon(Icons.lock_outline_rounded, size: 12, color: Color(0xFFA9B79A)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  l10n.recipeStepFrozenNote,
                  style: const TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFFA9B79A),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NumberGutter extends StatelessWidget {
  const _NumberGutter({required this.number, required this.big});

  final int number;
  final bool big;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      child: Text(
        '$number',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: AppFonts.display,
          fontWeight: FontWeight.w700,
          height: 1,
          fontSize: big ? 30 : 28,
          color: big ? const Color(0xFFD3CEBF) : const Color(0xFFB7C6A8),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onPaste, required this.onOneByOne});

  final VoidCallback onPaste;
  final VoidCallback onOneByOne;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFEFEBE0),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.receipt_long_outlined,
                size: 26, color: Color(0xFFA79F8B)),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.recipeStepsEmptyTitle,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.recipeStepsEmptyBody,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          _EntryButton(
            filled: true,
            icon: Icons.content_paste_rounded,
            title: l10n.recipeStepsPasteTitle,
            subtitle: l10n.recipeStepsPasteSubtitle,
            onTap: onPaste,
          ),
          const SizedBox(height: 12),
          _EntryButton(
            filled: false,
            icon: Icons.add_rounded,
            title: l10n.recipeStepsOneByOneTitle,
            subtitle: l10n.recipeStepsOneByOneSubtitle,
            onTap: onOneByOne,
          ),
        ],
      ),
    );
  }
}

class _EntryButton extends StatelessWidget {
  const _EntryButton({
    required this.filled,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool filled;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final titleColor = filled ? Colors.white : AppColors.textPrimary;
    final subColor = filled ? Colors.white.withValues(alpha: 0.85) : AppColors.textMuted;
    return Material(
      color: filled ? AppColors.accent : AppColors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: filled ? null : Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: filled
                      ? Colors.white.withValues(alpha: 0.22)
                      : const Color(0xFFEAF0E4),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon,
                    size: 20, color: filled ? Colors.white : const Color(0xFF5C7A4C)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: titleColor,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12.5, color: subColor),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: filled ? Colors.white : const Color(0xFFCBC7BB)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RemoveRefSheet extends StatelessWidget {
  const _RemoveRefSheet({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(14),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.link_off_rounded, size: 19),
              label: Text(l10n.recipeStepRemoveRef),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.commonCancel,
                  style: const TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}
