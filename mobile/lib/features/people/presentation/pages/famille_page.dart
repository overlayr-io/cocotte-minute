import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../tags/presentation/widgets/tag_colors.dart';
import '../../data/people_repository.dart';
import '../../domain/person.dart';
import '../bloc/people_list_bloc.dart';
import '../widgets/person_avatar.dart';
import '../widgets/person_form_sheet.dart';
import 'person_edit_page.dart';

/// Écran "Famille" : liste des personnes du compte + accès création / édition.
class FamillePage extends StatelessWidget {
  const FamillePage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const FamillePage());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          PeopleListBloc(repository: sl<PeopleRepository>())
            ..add(const PeopleRequested()),
      child: const _FamilleView(),
    );
  }
}

class _FamilleView extends StatelessWidget {
  const _FamilleView();

  Future<void> _create(BuildContext context) async {
    final bloc = context.read<PeopleListBloc>();
    final draft = await showCreatePersonSheet(context);
    if (draft == null) return;
    bloc.add(
      PersonCreated(firstName: draft.firstName, lastName: draft.lastName),
    );
  }

  Future<void> _edit(BuildContext context, Person person) async {
    final bloc = context.read<PeopleListBloc>();
    final changed = await Navigator.of(
      context,
    ).push(PersonEditPage.route(person));
    if (changed == true) bloc.add(const PeopleRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.familleTitle),
        actions: [
          BlocBuilder<PeopleListBloc, PeopleListState>(
            builder: (context, state) {
              if (state is! PeopleListLoaded) return const SizedBox.shrink();
              return IconButton(
                onPressed: () => _create(context),
                icon: const Icon(Icons.add_rounded),
                tooltip: l10n.personCreateCta,
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: BlocConsumer<PeopleListBloc, PeopleListState>(
        listenWhen: (_, curr) => curr is PeopleListActionFailure,
        listener: (context, state) {
          if (state is PeopleListActionFailure) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          return switch (state) {
            PeopleListError(:final message) => ErrorView(
              message: message,
              onRetry: () =>
                  context.read<PeopleListBloc>().add(const PeopleRequested()),
            ),
            PeopleListLoaded() => _buildContent(context, state, l10n),
            _ => const Center(child: CircularProgressIndicator()),
          };
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    PeopleListLoaded state,
    AppLocalizations l10n,
  ) {
    if (state.people.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            l10n.familleEmpty,
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 2, 2, 16),
          child: Text(
            l10n.familleIntro,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: Color(0xFF8A8574),
            ),
          ),
        ),
        for (final person in state.people)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _PersonTile(
              person: person,
              onTap: () => _edit(context, person),
            ),
          ),
      ],
    );
  }
}

class _PersonTile extends StatelessWidget {
  const _PersonTile({required this.person, required this.onTap});

  final Person person;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                PersonAvatar(
                  name: person.firstName,
                  imageUrl: person.avatarUrl,
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        person.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 5),
                      if (person.tags.isEmpty)
                        Text(
                          l10n.personNoTags,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFFB0AB9B),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final tag in person.tags)
                              _MiniChip(
                                name: tag.name,
                                color: TagColors.parse(tag.color),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
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

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: TagColors.tint(color),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
