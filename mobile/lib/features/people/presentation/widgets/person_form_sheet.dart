import 'package:flutter/material.dart';

import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import 'person_avatar.dart';

/// Données saisies pour créer une personne (les tags s'associent ensuite en
/// édition — cf. règle métier tags-personnes.md).
typedef PersonDraft = ({String firstName, String? lastName});

/// Bottom-sheet de création d'une personne (prénom + nom + avatar), dans la
/// coque de la maquette 3l. Aucune sélection de tag ici.
Future<PersonDraft?> showCreatePersonSheet(BuildContext context) {
  return showModalBottomSheet<PersonDraft>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _PersonFormSheet(),
  );
}

class _PersonFormSheet extends StatefulWidget {
  const _PersonFormSheet();

  @override
  State<_PersonFormSheet> createState() => _PersonFormSheetState();
}

class _PersonFormSheetState extends State<_PersonFormSheet> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  bool _showError = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _submit() {
    final firstName = _firstNameController.text.trim();
    if (firstName.isEmpty) {
      setState(() => _showError = true);
      return;
    }
    final lastName = _lastNameController.text.trim();
    Navigator.of(context).pop(
      (firstName: firstName, lastName: lastName.isEmpty ? null : lastName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFDAD5C8),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.personCreateTitle,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w700,
                fontSize: 22,
                letterSpacing: -0.4,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: PersonAvatar(
                name: _firstNameController.text,
                size: 82,
              ),
            ),
            const SizedBox(height: 20),
            _Label(l10n.personFieldFirstName),
            const SizedBox(height: 7),
            TextField(
              controller: _firstNameController,
              autofocus: true,
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
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  l10n.commonSave,
                  style:
                      const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
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
