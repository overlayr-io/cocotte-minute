import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../tags/data/tags_repository.dart';
import '../../../tags/domain/tag.dart';
import '../../../tags/presentation/widgets/tag_colors.dart';
import '../../data/people_repository.dart';
import '../../domain/person.dart';
import '../bloc/person_edit_cubit.dart';
import '../widgets/person_avatar.dart';

/// Page d'édition d'une personne : prénom + nom + avatar, et association des
/// tags du compte par toggle. Suppression en trailing d'AppBar, enregistrement
/// épinglé en bas d'écran. Retourne `true` si une modification a eu lieu.
class PersonEditPage extends StatelessWidget {
  const PersonEditPage({super.key, required this.person});

  final Person person;

  static Route<bool> route(Person person) {
    return MaterialPageRoute<bool>(builder: (_) => PersonEditPage(person: person));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PersonEditCubit(
        peopleRepository: sl<PeopleRepository>(),
        tagsRepository: sl<TagsRepository>(),
        person: person,
      )..loadTags(),
      child: const _PersonEditView(),
    );
  }
}

class _PersonEditView extends StatefulWidget {
  const _PersonEditView();

  @override
  State<_PersonEditView> createState() => _PersonEditViewState();
}

class _PersonEditViewState extends State<_PersonEditView> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    final person = context.read<PersonEditCubit>().state.person;
    _firstNameController = TextEditingController(text: person.firstName);
    _lastNameController = TextEditingController(text: person.lastName ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _save() {
    final firstName = _firstNameController.text.trim();
    if (firstName.isEmpty) {
      setState(() => _showError = true);
      return;
    }
    context
        .read<PersonEditCubit>()
        .save(firstName: firstName, lastName: _lastNameController.text.trim());
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<PersonEditCubit>();
    final person = cubit.state.person;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.personDeleteConfirmTitle),
        content: Text(l10n.personDeleteConfirmBody(person.displayName)),
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
    if (confirmed == true) cubit.deletePerson();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<PersonEditCubit, PersonEditState>(
      listenWhen: (prev, curr) =>
          curr.outcome != PersonEditOutcome.none || curr.message != prev.message,
      listener: (context, state) {
        if (state.outcome != PersonEditOutcome.none) {
          Navigator.of(context).pop(true);
          return;
        }
        if (state.message != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message!)));
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.personEditTitle),
            actions: [
              IconButton(
                onPressed: state.saving ? null : _confirmDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                color: AppColors.danger,
                tooltip: l10n.personDelete,
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Center(
                child: PersonAvatar(
                  name: _firstNameController.text.isEmpty
                      ? state.person.firstName
                      : _firstNameController.text,
                  imageUrl: state.person.avatarUrl,
                  size: 82,
                ),
              ),
              const SizedBox(height: 22),
              _Label(l10n.personFieldFirstName),
              const SizedBox(height: 7),
              TextField(
                controller: _firstNameController,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() => _showError = false),
                decoration: _decoration(
                  hint: l10n.personFirstNameHint,
                  errorText: _showError ? l10n.personFirstNameRequired : null,
                ),
              ),
              const SizedBox(height: 16),
              _Label(l10n.personFieldLastName),
              const SizedBox(height: 7),
              TextField(
                controller: _lastNameController,
                textCapitalization: TextCapitalization.words,
                decoration: _decoration(hint: l10n.personLastNameHint),
              ),
              const SizedBox(height: 22),
              _Label(l10n.personTagsLabel),
              const SizedBox(height: 11),
              _TagsSection(state: state, l10n: l10n),
            ],
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: state.saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: state.saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        l10n.commonSave,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  InputDecoration _decoration({required String hint, String? errorText}) {
    return InputDecoration(
      hintText: hint,
      errorText: errorText,
      filled: true,
      fillColor: AppColors.card,
      enabledBorder: _border(AppColors.border),
      focusedBorder: _border(AppColors.primary),
      errorBorder: _border(AppColors.danger),
      focusedErrorBorder: _border(AppColors.danger),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  OutlineInputBorder _border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color),
    );
  }
}

class _TagsSection extends StatelessWidget {
  const _TagsSection({required this.state, required this.l10n});

  final PersonEditState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    if (state.tagsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.allTags.isEmpty) {
      return Text(
        l10n.personTagsEmptyHint,
        style: const TextStyle(
          fontSize: 13,
          height: 1.4,
          color: AppColors.textMuted,
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final tag in state.allTags)
          _TagToggle(
            tag: tag,
            selected: state.person.hasTag(tag.id),
            busy: state.busyTagIds.contains(tag.id),
            onTap: () => context.read<PersonEditCubit>().toggleTag(tag),
          ),
      ],
    );
  }
}

class _TagToggle extends StatelessWidget {
  const _TagToggle({
    required this.tag,
    required this.selected,
    required this.busy,
    required this.onTap,
  });

  final Tag tag;
  final bool selected;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = TagColors.parse(tag.color);
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : AppColors.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (busy)
              SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: selected ? Colors.white : color,
                ),
              )
            else if (selected)
              const Icon(Icons.check_rounded, size: 15, color: Colors.white)
            else
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            const SizedBox(width: 6),
            Text(
              tag.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: AppColors.textMuted,
      ),
    );
  }
}
