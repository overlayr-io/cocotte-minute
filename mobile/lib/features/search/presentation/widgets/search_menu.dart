import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../categories/domain/category.dart';
import '../../../people/domain/person.dart';
import '../../../people/presentation/pages/famille_page.dart';
import '../../../people/presentation/widgets/person_avatar.dart';
import '../../../tags/domain/tag.dart';
import '../../../tags/presentation/widgets/tag_colors.dart';
import '../../domain/search_token.dart';
import '../bloc/search_cubit.dart';
import 'search_colors.dart';

/// Panneau d'autocomplétion affiché sous le champ selon la dimension en cours
/// (`/` dossiers, `#` tags, `@` personnes). Blanc, arrondi, ombré ; liste
/// scrollable de propositions filtrées par la saisie.
class SearchMenu extends StatelessWidget {
  const SearchMenu({super.key, required this.state});

  final SearchState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<SearchCubit>();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.22),
            blurRadius: 46,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        children: switch (state.openMenu!) {
          SearchDimension.folder => _folderRows(context, l10n, cubit),
          SearchDimension.tag => _tagRows(context, l10n, cubit),
          SearchDimension.person => _personRows(context, l10n, cubit),
        },
      ),
    );
  }

  // --- dossiers ----------------------------------------------------------

  List<Widget> _folderRows(
    BuildContext context,
    AppLocalizations l10n,
    SearchCubit cubit,
  ) {
    final candidates = state.folderCandidates;
    return [
      _SectionHeader(label: l10n.searchSectionFolders),
      for (final c in candidates)
        _FolderRow(
          category: c,
          path: state.categoryPath(c),
          subfolderCount: state.subfolderCount(c.id),
          l10n: l10n,
          onTap: () => cubit.addFolder(c),
        ),
      if (candidates.isEmpty) _EmptyRow(message: l10n.searchNoSuggestion),
    ];
  }

  // --- tags --------------------------------------------------------------

  List<Widget> _tagRows(
    BuildContext context,
    AppLocalizations l10n,
    SearchCubit cubit,
  ) {
    final candidates = state.tagCandidates;
    final query = state.menuQuery.trim();
    return [
      _SectionHeader(label: l10n.searchSectionTags),
      for (final t in candidates)
        _TagRow(tag: t, onTap: () => cubit.addTag(t)),
      if (candidates.isEmpty && query.isEmpty)
        _EmptyRow(message: l10n.searchNoSuggestion),
      if (!state.hasExactTagMatch && query.isNotEmpty) ...[
        if (candidates.isNotEmpty) const _Divider(),
        _CreateTagRow(
          name: query,
          l10n: l10n,
          onTap: () => cubit.createAndAddTag(query),
        ),
      ],
    ];
  }

  // --- personnes ---------------------------------------------------------

  List<Widget> _personRows(
    BuildContext context,
    AppLocalizations l10n,
    SearchCubit cubit,
  ) {
    final candidates = state.personCandidates;
    return [
      _SectionHeader(label: l10n.searchSectionPeople),
      for (final p in candidates)
        _PersonRow(person: p, onTap: () => cubit.addPerson(p)),
      if (candidates.isEmpty) _EmptyRow(message: l10n.searchNoSuggestion),
      const _Divider(),
      _ManageFamilyRow(
        l10n: l10n,
        onTap: () => Navigator.of(context).push(FamillePage.route()),
      ),
    ];
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: SearchColors.sectionLabel,
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Divider(height: 1, thickness: 1, color: Color(0xFFF0EDE5)),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Text(
        message,
        style: const TextStyle(fontSize: 13.5, color: AppColors.textMuted),
      ),
    );
  }
}

class _FolderRow extends StatelessWidget {
  const _FolderRow({
    required this.category,
    required this.path,
    required this.subfolderCount,
    required this.l10n,
    required this.onTap,
  });

  final Category category;
  final String path;
  final int subfolderCount;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = subfolderCount > 0
        ? '${l10n.searchFolderRecipes(category.recipeCount)} · ${l10n.searchFolderSubfolders(subfolderCount)}'
        : l10n.searchFolderRecipes(category.recipeCount);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF7D9C6A), Color(0xFF5E7F4F)],
                ),
              ),
              child: category.icon != null
                  ? Text(category.icon!, style: const TextStyle(fontSize: 18))
                  : const Icon(Icons.folder_rounded, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    path,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFFC4BEAD)),
          ],
        ),
      ),
    );
  }
}

class _TagRow extends StatelessWidget {
  const _TagRow({required this.tag, required this.onTap});

  final Tag tag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: TagColors.parse(tag.color),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '#${tag.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (tag.recipeCount > 0)
              Text(
                '${tag.recipeCount}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: SearchColors.muted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CreateTagRow extends StatelessWidget {
  const _CreateTagRow({
    required this.name,
    required this.l10n,
    required this.onTap,
  });

  final String name;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: SearchColors.folderRowTint,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add_rounded, size: 15, color: SearchColors.folder),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.searchCreateTag(name),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: SearchColors.folderText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.person, required this.onTap});

  final Person person;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tagsLine = person.tags.map((t) => t.name).join(' · ');
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            PersonAvatar(
              name: person.displayName,
              imageUrl: person.avatarUrl,
              size: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (tagsLine.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      tagsLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManageFamilyRow extends StatelessWidget {
  const _ManageFamilyRow({required this.l10n, required this.onTap});

  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: SearchColors.folderRowTint,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.group_rounded, size: 15, color: SearchColors.folder),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.searchManageFamily,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: SearchColors.folderText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
