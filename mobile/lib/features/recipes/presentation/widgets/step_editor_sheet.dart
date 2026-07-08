import 'package:flutter/material.dart';

import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/recipe.dart';
import '../bloc/recipe_detail_cubit.dart';
import 'base_recipe_picker_sheet.dart';
import 'step_banner.dart';
import 'step_ingredients_sheet.dart';

/// Feuille de composition (maquette 9e) et d'édition (9f) d'une étape.
/// Pilote directement le [RecipeDetailCubit] (add/next reste ouvert).
Future<void> showStepEditorSheet(
  BuildContext context, {
  required RecipeDetailCubit cubit,
  required String recipeId,
  required List<RecipeIngredientLine> recipeIngredients,
  RecipeTextStep? edit,
  int editNumber = 1,
  int addStartNumber = 1,
  int alreadyAdded = 0,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _StepEditorSheet(
      cubit: cubit,
      recipeId: recipeId,
      recipeIngredients: recipeIngredients,
      edit: edit,
      editNumber: editNumber,
      addStartNumber: addStartNumber,
      alreadyAdded: alreadyAdded,
    ),
  );
}

class _StepEditorSheet extends StatefulWidget {
  const _StepEditorSheet({
    required this.cubit,
    required this.recipeId,
    required this.recipeIngredients,
    required this.edit,
    required this.editNumber,
    required this.addStartNumber,
    required this.alreadyAdded,
  });

  final RecipeDetailCubit cubit;
  final String recipeId;
  final List<RecipeIngredientLine> recipeIngredients;
  final RecipeTextStep? edit;
  final int editNumber;
  final int addStartNumber;
  final int alreadyAdded;

  @override
  State<_StepEditorSheet> createState() => _StepEditorSheetState();
}

class _StepEditorSheetState extends State<_StepEditorSheet> {
  late final _descController =
      TextEditingController(text: widget.edit?.description ?? '');
  late final _bannerTextController =
      TextEditingController(text: widget.edit?.banner?.text ?? '');
  late StepBannerType? _bannerType = widget.edit?.banner?.type;
  late final Set<String> _ingredientIds = {
    ...?widget.edit?.ingredients.map((i) => i.id),
  };

  late int _number = widget.addStartNumber;
  late int _added = widget.alreadyAdded;
  bool _busy = false;
  bool _descError = false;

  bool get _isAdd => widget.edit == null;

  @override
  void dispose() {
    _descController.dispose();
    _bannerTextController.dispose();
    super.dispose();
  }

  StepBanner? _banner() => _bannerType == null
      ? null
      : StepBanner(type: _bannerType!, text: _bannerTextController.text.trim());

  bool _validate() {
    final desc = _descController.text.trim();
    if (desc.isEmpty) {
      setState(() => _descError = true);
      return false;
    }
    if (_bannerType != null && _bannerTextController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context).recipeStepBannerTextHint)));
      return false;
    }
    return true;
  }

  Future<void> _addAndNext() async {
    if (!_validate()) return;
    setState(() => _busy = true);
    await widget.cubit.addTextStep(
      description: _descController.text.trim(),
      banner: _banner(),
      ingredientIds: _ingredientIds.toList(),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _number++;
      _added++;
      _descController.clear();
      _bannerTextController.clear();
      _bannerType = null;
      _ingredientIds.clear();
    });
  }

  Future<void> _finishAdd() async {
    if (_descController.text.trim().isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    if (!_validate()) return;
    setState(() => _busy = true);
    await widget.cubit.addTextStep(
      description: _descController.text.trim(),
      banner: _banner(),
      ingredientIds: _ingredientIds.toList(),
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _save() async {
    if (!_validate()) return;
    setState(() => _busy = true);
    await widget.cubit.updateStep(
      widget.edit!.id,
      description: _descController.text.trim(),
      banner: _banner(),
      ingredientIds: _ingredientIds.toList(),
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    setState(() => _busy = true);
    await widget.cubit.removeStep(widget.edit!.id);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickBaseRef() async {
    final base =
        await showBaseRecipePicker(context, excludeRecipeId: widget.recipeId);
    if (base == null || !mounted) return;
    setState(() => _busy = true);
    await widget.cubit.addBaseRefStep(base.id);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickIngredients() async {
    final result = await showStepIngredientsSheet(
      context,
      recipeIngredients: widget.recipeIngredients,
      selected: _ingredientIds,
    );
    if (result != null) {
      setState(() {
        _ingredientIds
          ..clear()
          ..addAll(result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FractionallySizedBox(
      heightFactor: 0.92,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _handle(),
              _header(l10n),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
                  children: [
                    _label(l10n.recipeStepFieldDescription),
                    const SizedBox(height: 8),
                    _descriptionField(l10n),
                    const SizedBox(height: 20),
                    if (_bannerType != null)
                      _bannerEditor(l10n)
                    else
                      _optionButtons(l10n),
                    const SizedBox(height: 20),
                    _ingredientsSection(l10n),
                  ],
                ),
              ),
              _footer(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _handle() => Padding(
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

  Widget _header(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 4, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isAdd
                      ? l10n.recipeStepAddTitle(_number)
                      : l10n.recipeStepEditTitle(widget.editNumber),
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    letterSpacing: -0.3,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (_isAdd)
                  Text(
                    l10n.recipeStepAlreadyAdded(_added),
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                  ),
              ],
            ),
          ),
          Material(
            color: const Color(0xFFEAE6DA),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 34,
                height: 34,
                child: Icon(Icons.close_rounded, size: 19, color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      );

  Widget _descriptionField(AppLocalizations l10n) {
    return TextField(
      controller: _descController,
      autofocus: _isAdd,
      minLines: 3,
      maxLines: 6,
      textCapitalization: TextCapitalization.sentences,
      onChanged: (_) {
        if (_descError) setState(() => _descError = false);
      },
      style: const TextStyle(fontSize: 14.5, height: 1.5, color: Color(0xFF33404B)),
      decoration: InputDecoration(
        hintText: l10n.recipeStepDescriptionHint,
        errorText: _descError ? l10n.recipeStepDescriptionRequired : null,
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.all(14),
        enabledBorder: _fieldBorder(AppColors.border),
        focusedBorder: _fieldBorder(AppColors.primary),
        errorBorder: _fieldBorder(AppColors.danger),
        focusedErrorBorder: _fieldBorder(AppColors.danger),
      ),
    );
  }

  Widget _optionButtons(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(l10n.recipeStepAddOptional),
        const SizedBox(height: 9),
        _OptionButton(
          iconBg: const Color(0xFFFBF1DE),
          icon: Icons.flag_outlined,
          iconColor: const Color(0xFFB87A18),
          title: l10n.recipeStepBannerOption,
          subtitle: l10n.recipeStepBannerOptionHint,
          onTap: () => setState(() => _bannerType = StepBannerType.warning),
        ),
        const SizedBox(height: 9),
        _OptionButton(
          iconBg: const Color(0xFFEAF0E4),
          icon: Icons.link_rounded,
          iconColor: const Color(0xFF5C7A4C),
          title: l10n.recipeStepBaseRefOption,
          subtitle: l10n.recipeStepBaseRefOptionHint,
          // Référence possible seulement à l'ajout et sans bannière.
          onTap: _isAdd ? _pickBaseRef : null,
        ),
      ],
    );
  }

  Widget _bannerEditor(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _label(l10n.recipeStepBannerLabel),
            GestureDetector(
              onTap: () => setState(() => _bannerType = null),
              child: Text(
                l10n.recipeStepBannerRemove,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFB0574B),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final type in StepBannerType.values) ...[
              Expanded(child: _bannerChip(l10n, type)),
              if (type != StepBannerType.values.last) const SizedBox(width: 9),
            ],
          ],
        ),
        const SizedBox(height: 9),
        TextField(
          controller: _bannerTextController,
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(fontSize: 13.5, color: Color(0xFF33404B)),
          decoration: InputDecoration(
            hintText: l10n.recipeStepBannerTextHint,
            filled: true,
            fillColor: AppColors.card,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            enabledBorder: _fieldBorder(AppColors.border, radius: 12),
            focusedBorder: _fieldBorder(AppColors.primary, radius: 12),
          ),
        ),
        const SizedBox(height: 12),
        // Référence de base indisponible tant qu'une bannière est présente.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            color: AppColors.pill,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Opacity(
            opacity: 0.75,
            child: Row(
              children: [
                const Icon(Icons.link_rounded, size: 16, color: Color(0xFFA79F8B)),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    l10n.recipeStepBaseRefUnavailableLabel,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF8A8574)),
                  ),
                ),
                Text(
                  l10n.recipeStepBaseRefUnavailable,
                  style: const TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFFB0AB9B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _bannerChip(AppLocalizations l10n, StepBannerType type) {
    final s = stepBannerStyle(type);
    final selected = _bannerType == type;
    return GestureDetector(
      onTap: () => setState(() => _bannerType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? s.background : AppColors.card,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected ? s.accent : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(s.iconData, size: 18, color: s.icon),
            const SizedBox(height: 5),
            Text(
              stepBannerLabel(l10n, type),
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? s.text : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ingredientsSection(AppLocalizations l10n) {
    final selected = widget.recipeIngredients
        .where((i) => _ingredientIds.contains(i.id))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _label(l10n.recipeStepIngredientsSectionLabel),
            GestureDetector(
              onTap: _pickIngredients,
              child: Text(
                l10n.recipeStepSelect,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        if (selected.isNotEmpty) ...[
          const SizedBox(height: 9),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final ing in selected)
                Container(
                  padding: const EdgeInsets.fromLTRB(11, 6, 11, 6),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    ing.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF33404B),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _footer(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: Color(0xFFECE8DE))),
      ),
      child: _isAdd
          ? Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _busy ? null : _addAndNext,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF5C7A4C),
                        side: const BorderSide(color: AppColors.primary, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(l10n.recipeStepAddNext,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _busy ? null : _finishAdd,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(l10n.recipeStepFinish,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _busy ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(l10n.commonSave,
                        style: const TextStyle(
                            fontSize: 15.5, fontWeight: FontWeight.w700)),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: TextButton.icon(
                    onPressed: _busy ? null : _delete,
                    icon: const Icon(Icons.delete_outline_rounded, size: 19),
                    label: Text(l10n.recipeStepDelete),
                    style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                  ),
                ),
              ],
            ),
    );
  }

  OutlineInputBorder _fieldBorder(Color color, {double radius = 14}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: color),
      );
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.iconBg,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Color iconBg;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFFCBC7BB)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
