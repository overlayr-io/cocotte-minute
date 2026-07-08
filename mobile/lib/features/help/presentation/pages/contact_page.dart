import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/help_repository.dart';
import '../bloc/contact_cubit.dart';

/// « Nous contacter » : formulaire (sujet + message) envoyé au serveur. Succès
/// = retour à l'écran précédent + snackbar de confirmation.
class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const ContactPage());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ContactCubit(repository: sl<HelpRepository>()),
      child: const _ContactView(),
    );
  }
}

class _ContactView extends StatefulWidget {
  const _ContactView();

  @override
  State<_ContactView> createState() => _ContactViewState();
}

class _ContactViewState extends State<_ContactView> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<ContactCubit>().send(
      subject: _subjectController.text.trim(),
      message: _messageController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountRowContact)),
      body: BlocConsumer<ContactCubit, ContactState>(
        listener: (context, state) {
          if (state.status == ContactStatus.success) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(l10n.contactSuccess)));
            Navigator.of(context).maybePop();
          } else if (state.status == ContactStatus.failure) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(state.errorMessage ?? l10n.commonRetry)),
              );
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                Text(
                  l10n.contactIntro,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: Color(0xFF8A8574),
                  ),
                ),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel(l10n.contactSubjectLabel),
                      const SizedBox(height: 7),
                      TextFormField(
                        controller: _subjectController,
                        textInputAction: TextInputAction.next,
                        maxLength: 120,
                        decoration: _decoration(l10n.contactSubjectHint),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? l10n.contactSubjectError
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _FieldLabel(l10n.contactMessageLabel),
                      const SizedBox(height: 7),
                      TextFormField(
                        controller: _messageController,
                        minLines: 5,
                        maxLines: 10,
                        maxLength: 4000,
                        keyboardType: TextInputType.multiline,
                        decoration: _decoration(l10n.contactMessageHint),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? l10n.contactMessageError
                            : null,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          onPressed: state.isSending ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: state.isSending
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  l10n.contactSendAction,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 15, color: AppColors.textMuted),
      filled: true,
      fillColor: AppColors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}
