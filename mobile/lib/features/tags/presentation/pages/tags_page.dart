import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/widgets/error_view.dart';
import '../../data/tags_repository.dart';
import '../../domain/tag.dart';
import '../bloc/tags_list_bloc.dart';
import '../widgets/tag_colors.dart';
import '../widgets/tag_form_sheet.dart';

/// Écran "Tags" : onglets mes tags / catalogue système + création / édition /
/// suppression / import.
class TagsPage extends StatelessWidget {
  const TagsPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const TagsPage());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          TagsListBloc(repository: sl<TagsRepository>())
            ..add(const TagsRequested()),
      child: const _TagsView(),
    );
  }
}

class _TagsView extends StatefulWidget {
  const _TagsView();

  @override
  State<_TagsView> createState() => _TagsViewState();
}

class _TagsViewState extends State<_TagsView> {
  int _tab = 0; // 0 = mes tags, 1 = catalogue

  Future<void> _create(BuildContext context) async {
    final bloc = context.read<TagsListBloc>();
    final result = await showTagFormSheet(context);
    if (result is TagSaved) {
      bloc.add(TagCreated(name: result.name, color: result.color));
    }
  }

  Future<void> _edit(BuildContext context, Tag tag) async {
    final bloc = context.read<TagsListBloc>();
    final result = await showTagFormSheet(context, initial: tag);
    if (result is TagSaved) {
      bloc.add(TagUpdated(id: tag.id, name: result.name, color: result.color));
    } else if (result is TagDeleteRequested) {
      if (!context.mounted) return;
      final confirmed = await _confirmDelete(context, tag);
      if (confirmed) bloc.add(TagDeleted(tag.id));
    }
  }

  Future<bool> _confirmDelete(BuildContext context, Tag tag) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.tagDeleteConfirmTitle),
        content: Text(l10n.tagDeleteConfirmBody(tag.name)),
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
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tagsTitle),
        actions: [
          BlocBuilder<TagsListBloc, TagsListState>(
            builder: (context, state) {
              if (state is! TagsListLoaded || _tab != 0) {
                return const SizedBox.shrink();
              }
              if (state.creating) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              return IconButton(
                onPressed: () => _create(context),
                icon: const Icon(Icons.add_rounded),
                tooltip: l10n.tagsCreateCta,
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: BlocConsumer<TagsListBloc, TagsListState>(
        listenWhen: (_, curr) => curr is TagsListActionFailure,
        listener: (context, state) {
          if (state is TagsListActionFailure) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          return switch (state) {
            TagsListError(:final message) => ErrorView(
              message: message,
              onRetry: () =>
                  context.read<TagsListBloc>().add(const TagsRequested()),
            ),
            TagsListLoaded() => _buildContent(context, state, l10n),
            _ => const Center(child: CircularProgressIndicator()),
          };
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    TagsListLoaded state,
    AppLocalizations l10n,
  ) {
    final isMine = _tab == 0;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
          child: _Segmented(
            index: _tab,
            labels: [l10n.tagsTabMine, l10n.tagsTabCatalog],
            onChanged: (i) => setState(() => _tab = i),
          ),
        ),
        Expanded(
          child: isMine
              ? _mineList(context, state, l10n)
              : _catalogList(context, state, l10n),
        ),
      ],
    );
  }

  Widget _mineList(
    BuildContext context,
    TagsListLoaded state,
    AppLocalizations l10n,
  ) {
    if (state.mine.isEmpty) {
      return _EmptyState(message: l10n.tagsEmpty);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            l10n.tagsIntro,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: Color(0xFF8A8574),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            children: [
              for (var i = 0; i < state.mine.length; i++)
                _TagRow(
                  tag: state.mine[i],
                  showDivider: i < state.mine.length - 1,
                  busy: state.busyId == state.mine[i].id,
                  onEdit: () => _edit(context, state.mine[i]),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _catalogList(
    BuildContext context,
    TagsListLoaded state,
    AppLocalizations l10n,
  ) {
    if (state.system.isEmpty) {
      return _EmptyState(message: l10n.tagsEmptyCatalog);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            children: [
              for (var i = 0; i < state.system.length; i++)
                _SystemTagRow(
                  tag: state.system[i],
                  showDivider: i < state.system.length - 1,
                  busy: state.busyId == state.system[i].id,
                  onImport: () => context
                      .read<TagsListBloc>()
                      .add(TagSystemImported(state.system[i].id)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _ImportInfo(text: l10n.tagsImportInfo),
      ],
    );
  }
}

class _TagRow extends StatelessWidget {
  const _TagRow({
    required this.tag,
    required this.showDivider,
    required this.busy,
    required this.onEdit,
  });

  final Tag tag;
  final bool showDivider;
  final bool busy;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = TagColors.parse(tag.color);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: Color(0xFFF1EEE7)))
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: busy ? null : onEdit,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    tag.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.tagsRecipeCount(tag.recipeCount),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFA79F8B),
                  ),
                ),
                const SizedBox(width: 12),
                Container(width: 1, height: 20, color: const Color(0xFFF1EEE7)),
                const SizedBox(width: 12),
                busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: Color(0xFFCBC7BB),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SystemTagRow extends StatelessWidget {
  const _SystemTagRow({
    required this.tag,
    required this.showDivider,
    required this.busy,
    required this.onImport,
  });

  final Tag tag;
  final bool showDivider;
  final bool busy;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = TagColors.parse(tag.color);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: Color(0xFFF1EEE7)))
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                tag.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            if (tag.alreadyImported)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_rounded, size: 16, color: Color(0xFF3F7D3A)),
                  const SizedBox(width: 4),
                  Text(
                    l10n.tagsAlreadyImported,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3F7D3A),
                    ),
                  ),
                ],
              )
            else
              OutlinedButton(
                onPressed: busy ? null : onImport,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape:
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                child: busy
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.download_rounded, size: 16),
                          const SizedBox(width: 5),
                          Text(
                            l10n.tagsImport,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
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
}

class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.index,
    required this.labels,
    required this.onChanged,
  });

  final int index;
  final List<String> labels;
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
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: i == index ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: i == index
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
                    labels[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: i == index
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ImportInfo extends StatelessWidget {
  const _ImportInfo({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EAD6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF8A7A4E)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8A7A4E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            height: 1.45,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
