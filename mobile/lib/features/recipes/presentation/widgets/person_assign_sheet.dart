import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../people/data/people_repository.dart';
import '../../../people/domain/person.dart';
import '../../../people/presentation/widgets/person_avatar.dart';

/// Feuille « Associer une personne » : liste des personnes du compte, chaque
/// ligne se coche / décoche pour (dé)associer la recette à la personne (pivot
/// person_recipes, mutations via [PeopleRepository]).
Future<void> showPersonAssignSheet(
  BuildContext context, {
  required String recipeId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PersonAssignSheet(recipeId: recipeId),
  );
}

class _PersonAssignSheet extends StatefulWidget {
  const _PersonAssignSheet({required this.recipeId});

  final String recipeId;

  @override
  State<_PersonAssignSheet> createState() => _PersonAssignSheetState();
}

class _PersonAssignSheetState extends State<_PersonAssignSheet> {
  final PeopleRepository _repository = sl<PeopleRepository>();

  List<Person>? _people;
  String? _error;

  /// Personne en cours de mutation (une seule à la fois).
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final people = await _repository.fetchMine();
      if (mounted) setState(() => _people = people);
    } on PeopleRepositoryException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _toggle(Person person) async {
    if (_busyId != null) return;
    final selected = person.recipeIds.contains(widget.recipeId);
    setState(() => _busyId = person.id);
    try {
      final updated = selected
          ? await _repository.removeRecipe(person.id, widget.recipeId)
          : await _repository.addRecipe(person.id, widget.recipeId);
      if (!mounted) return;
      setState(() {
        _people = [
          for (final p in _people!) p.id == updated.id ? updated : p,
        ];
      });
    } on PeopleRepositoryException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
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
                l10n.recipePeopleSheetTitle,
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  letterSpacing: -0.3,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                l10n.recipePeopleSheetSubtitle,
                style:
                    const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),
              Expanded(child: _body(l10n, scrollController)),
            ],
          ),
        );
      },
    );
  }

  Widget _body(AppLocalizations l10n, ScrollController scrollController) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
        ),
      );
    }
    final people = _people;
    if (people == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (people.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            l10n.recipePeopleSheetEmpty,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
        ),
      );
    }
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: people.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final person = people[i];
        final selected = person.recipeIds.contains(widget.recipeId);
        return _PersonToggleTile(
          person: person,
          selected: selected,
          busy: _busyId == person.id,
          onTap: () => _toggle(person),
        );
      },
    );
  }
}

class _PersonToggleTile extends StatelessWidget {
  const _PersonToggleTile({
    required this.person,
    required this.selected,
    required this.busy,
    required this.onTap,
  });

  final Person person;
  final bool selected;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryTint : AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              PersonAvatar(
                name: person.firstName,
                imageUrl: person.avatarUrl,
                size: 36,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  person.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 22,
                      color: selected
                          ? AppColors.primary
                          : const Color(0xFFC4C0B5),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
