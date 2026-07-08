import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../categories/data/categories_repository.dart';
import '../../../categories/domain/category.dart';
import '../../../tags/data/tags_repository.dart';
import '../../../tags/domain/tag.dart';
import '../../../tags/presentation/widgets/tag_colors.dart';
import '../../domain/recipe.dart';
import '../bloc/recipe_detail_cubit.dart';
import 'category_assign_sheet.dart';
import 'tag_assign_sheet.dart';

/// Bloc « organisation » de la fiche : tags associés + dossiers de rangement,
/// chacun éditable via une feuille de (dé)sélection. Les noms/couleurs sont
/// résolus depuis les listes du compte (la fiche ne porte que les ids).
class RecipeOrganizationSection extends StatefulWidget {
  const RecipeOrganizationSection({super.key, required this.detail});

  final RecipeDetail detail;

  @override
  State<RecipeOrganizationSection> createState() =>
      _RecipeOrganizationSectionState();
}

class _RecipeOrganizationSectionState extends State<RecipeOrganizationSection> {
  // Chargées une fois : servent à résoudre les ids portés par la fiche en
  // objets affichables. Rarement modifiées depuis cet écran.
  late final Future<List<Tag>> _tagsFuture = sl<TagsRepository>().fetchMine();
  late final Future<List<Category>> _categoriesFuture =
      sl<CategoriesRepository>().fetchMine();

  void _editTags() {
    showTagAssignSheet(context, cubit: context.read<RecipeDetailCubit>());
  }

  void _editFolders() {
    showCategoryAssignSheet(context, cubit: context.read<RecipeDetailCubit>());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          FutureBuilder<List<Tag>>(
            future: _tagsFuture,
            builder: (context, snapshot) {
              final byId = {for (final t in snapshot.data ?? const []) t.id: t};
              final assigned = widget.detail.tagIds
                  .map((id) => byId[id])
                  .whereType<Tag>()
                  .toList();
              return _Row(
                icon: Icons.sell_outlined,
                title: l10n.recipeTagsSection,
                onEdit: _editTags,
                editTooltip: l10n.recipeTagsEdit,
                child: assigned.isEmpty
                    ? _Placeholder(label: l10n.recipeTagsNone)
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final tag in assigned) _TagChip(tag: tag),
                        ],
                      ),
              );
            },
          ),
          const Divider(height: 1, color: AppColors.divider),
          FutureBuilder<List<Category>>(
            future: _categoriesFuture,
            builder: (context, snapshot) {
              final byId =
                  {for (final c in snapshot.data ?? const []) c.id: c};
              final assigned = widget.detail.categoryIds
                  .map((id) => byId[id])
                  .whereType<Category>()
                  .toList();
              return _Row(
                icon: Icons.folder_outlined,
                title: l10n.recipeFoldersSection,
                onEdit: _editFolders,
                editTooltip: l10n.recipeFoldersEdit,
                child: assigned.isEmpty
                    ? _Placeholder(label: l10n.recipeFoldersNone)
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final folder in assigned)
                            _FolderChip(folder: folder),
                        ],
                      ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.onEdit,
    required this.editTooltip,
    required this.child,
  });

  final IconData icon;
  final String title;
  final VoidCallback onEdit;
  final String editTooltip;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  child,
                ],
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: editTooltip,
              child: const Icon(Icons.add_circle_outline_rounded,
                  size: 22, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.tag});

  final Tag tag;

  @override
  Widget build(BuildContext context) {
    final color = TagColors.parse(tag.color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: TagColors.tint(color),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            tag.name,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _FolderChip extends StatelessWidget {
  const _FolderChip({required this.folder});

  final Category folder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          folder.icon != null
              ? Text(folder.icon!, style: const TextStyle(fontSize: 12))
              : const Icon(Icons.folder_rounded,
                  size: 13, color: AppColors.primary),
          const SizedBox(width: 7),
          Text(
            folder.name,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
