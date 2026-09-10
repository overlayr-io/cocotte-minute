import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../categories/data/categories_repository.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/widgets/category_drilldown_picker.dart';
import '../../../categories/presentation/widgets/category_path.dart';
import '../bloc/recipe_detail_cubit.dart';

/// Feuille de rangement : dossiers déjà assignés (avec leur chemin complet) et
/// bouton ouvrant le sélecteur en drill-down pour naviguer dans les
/// sous-dossiers et (dé)cocher plusieurs dossiers à la fois. Les mutations
/// passent par le [RecipeDetailCubit] (rechargement à chaque diff).
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
  late final Future<List<Category>> _future =
      sl<CategoriesRepository>().fetchMine();

  /// true pendant l'application du diff renvoyé par le sélecteur (plusieurs
  /// mutations à la suite).
  bool _busy = false;

  Future<void> _openPicker(
    RecipeDetailCubit cubit,
    Set<String> currentlyAssigned,
  ) async {
    final result = await showCategoryDrilldownPicker(
      context,
      initiallySelected: currentlyAssigned,
    );
    if (result == null || !mounted) return;
    final toAdd = result.difference(currentlyAssigned);
    final toRemove = currentlyAssigned.difference(result);
    if (toAdd.isEmpty && toRemove.isEmpty) return;
    setState(() => _busy = true);
    for (final id in toAdd) {
      await cubit.assignCategory(id);
    }
    for (final id in toRemove) {
      await cubit.unassignCategory(id);
    }
    if (mounted) setState(() => _busy = false);
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
                    final all = snapshot.data!;
                    return BlocBuilder<RecipeDetailCubit, RecipeDetailState>(
                      builder: (context, state) {
                        final assignedIds = state is RecipeDetailLoaded
                            ? state.detail.categoryIds.toSet()
                            : const <String>{};
                        final byId = {for (final c in all) c.id: c};
                        final assigned = assignedIds
                            .map((id) => byId[id])
                            .whereType<Category>()
                            .toList();
                        final cubit = context.read<RecipeDetailCubit>();
                        return SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (assigned.isEmpty)
                                _Empty(message: l10n.recipeFoldersSheetEmpty)
                              else
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final folder in assigned)
                                      Chip(
                                        avatar: const Icon(
                                          Icons.folder_outlined,
                                          size: 16,
                                          color: AppColors.primary,
                                        ),
                                        label: Text(categoryPath(folder, all)),
                                        backgroundColor: AppColors.card,
                                        side: const BorderSide(
                                            color: AppColors.border),
                                      ),
                                  ],
                                ),
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: _busy
                                      ? null
                                      : () => _openPicker(cubit, assignedIds),
                                  icon: _busy
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white),
                                        )
                                      : const Icon(Icons.folder_open_rounded),
                                  label: Text(l10n.recipeFoldersSheetTitle),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
