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

/// Écran "Tags" : liste des tags du compte + création / édition / suppression.
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

class _TagsView extends StatelessWidget {
  const _TagsView();

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
              if (state is! TagsListLoaded) return const SizedBox.shrink();
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
    if (state.tags.isEmpty) {
      return _EmptyState(message: l10n.tagsEmpty);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 2, 2, 16),
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
              for (var i = 0; i < state.tags.length; i++)
                _TagRow(
                  tag: state.tags[i],
                  showDivider: i < state.tags.length - 1,
                  busy: state.busyId == state.tags[i].id,
                  onEdit: () => _edit(context, state.tags[i]),
                ),
            ],
          ),
        ),
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
      child: InkWell(
        onTap: busy ? null : onEdit,
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
