import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../categories/data/categories_repository.dart';
import '../../../categories/domain/category.dart';
import '../bloc/recipe_detail_cubit.dart';

/// Feuille de rangement : liste des dossiers du compte, chaque ligne se coche /
/// décoche pour (dé)ranger la recette. Les mutations passent par le
/// [RecipeDetailCubit] (rechargement) ; la sélection courante est relue depuis
/// l'état à chaque changement.
Future<void> showCategoryAssignSheet(
  BuildContext context, {
  required RecipeDetailCubit cubit,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: const _CategoryAssignSheet(),
    ),
  );
}

class _CategoryAssignSheet extends StatefulWidget {
  const _CategoryAssignSheet();

  @override
  State<_CategoryAssignSheet> createState() => _CategoryAssignSheetState();
}

class _CategoryAssignSheetState extends State<_CategoryAssignSheet> {
  late final Future<List<Category>> _future = _load();

  Future<List<Category>> _load() async {
    final all = await sl<CategoriesRepository>().fetchMine();
    // Tri stable : racines d'abord, puis par nom (les dossiers imbriqués suivent).
    all.sort((a, b) {
      if (a.depth != b.depth) return a.depth.compareTo(b.depth);
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return all;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8D3C6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.recipeFoldersSheetTitle,
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  letterSpacing: -0.3,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                l10n.recipeFoldersSheetSubtitle,
                style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<List<Category>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final folders = snapshot.data!;
                    if (folders.isEmpty) {
                      return _Empty(message: l10n.recipeFoldersSheetEmpty);
                    }
                    return BlocBuilder<RecipeDetailCubit, RecipeDetailState>(
                      builder: (context, state) {
                        final assigned = state is RecipeDetailLoaded
                            ? state.detail.categoryIds.toSet()
                            : const <String>{};
                        return ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: folders.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final folder = folders[i];
                            final selected = assigned.contains(folder.id);
                            return _FolderToggleTile(
                              folder: folder,
                              selected: selected,
                              onTap: () {
                                final c = context.read<RecipeDetailCubit>();
                                if (selected) {
                                  c.unassignCategory(folder.id);
                                } else {
                                  c.assignCategory(folder.id);
                                }
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FolderToggleTile extends StatelessWidget {
  const _FolderToggleTile({
    required this.folder,
    required this.selected,
    required this.onTap,
  });

  final Category folder;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryTint : AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: folder.icon != null
                    ? Text(folder.icon!, style: const TextStyle(fontSize: 18))
                    : const Icon(Icons.folder_outlined,
                        size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  folder.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 22,
                color: selected ? AppColors.primary : const Color(0xFFC4C0B5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
      ),
    );
  }
}
