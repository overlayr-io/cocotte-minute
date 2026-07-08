import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../tags/data/tags_repository.dart';
import '../../../tags/domain/tag.dart';
import '../../../tags/presentation/widgets/tag_colors.dart';
import '../bloc/recipe_detail_cubit.dart';

/// Feuille d'étiquetage : liste des tags du compte, chaque ligne se coche /
/// décoche pour (dé)associer le tag à la recette. Les mutations passent par le
/// [RecipeDetailCubit] (rechargement) ; la sélection courante est relue depuis
/// l'état à chaque changement.
Future<void> showTagAssignSheet(
  BuildContext context, {
  required RecipeDetailCubit cubit,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: const _TagAssignSheet(),
    ),
  );
}

class _TagAssignSheet extends StatefulWidget {
  const _TagAssignSheet();

  @override
  State<_TagAssignSheet> createState() => _TagAssignSheetState();
}

class _TagAssignSheetState extends State<_TagAssignSheet> {
  late final Future<List<Tag>> _future = sl<TagsRepository>().fetchMine();

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
                l10n.recipeTagsSheetTitle,
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  letterSpacing: -0.3,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                l10n.recipeTagsSheetSubtitle,
                style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<List<Tag>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final tags = snapshot.data!;
                    if (tags.isEmpty) {
                      return _Empty(message: l10n.recipeTagsSheetEmpty);
                    }
                    return BlocBuilder<RecipeDetailCubit, RecipeDetailState>(
                      builder: (context, state) {
                        final assigned = state is RecipeDetailLoaded
                            ? state.detail.tagIds.toSet()
                            : const <String>{};
                        return ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: tags.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final tag = tags[i];
                            final selected = assigned.contains(tag.id);
                            return _TagToggleTile(
                              tag: tag,
                              selected: selected,
                              onTap: () {
                                final c = context.read<RecipeDetailCubit>();
                                if (selected) {
                                  c.unassignTag(tag.id);
                                } else {
                                  c.assignTag(tag.id);
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

class _TagToggleTile extends StatelessWidget {
  const _TagToggleTile({
    required this.tag,
    required this.selected,
    required this.onTap,
  });

  final Tag tag;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = TagColors.parse(tag.color);
    return Material(
      color: selected ? TagColors.tint(color) : AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? color : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  tag.name,
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
                color: selected ? color : const Color(0xFFC4C0B5),
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
