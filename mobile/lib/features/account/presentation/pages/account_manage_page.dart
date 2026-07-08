import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/auth_repository.dart';
import '../bloc/account_manage_cubit.dart';

/// Page « Gérer le compte » (utilisateur connecté) : modification de l'e-mail
/// et du mot de passe. Deux sections indépendantes, chacune avec son propre
/// bouton d'enregistrement.
class AccountManagePage extends StatelessWidget {
  const AccountManagePage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const AccountManagePage());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AccountManageCubit(sl<AuthRepository>()),
      child: const _AccountManageView(),
    );
  }
}

class _AccountManageView extends StatefulWidget {
  const _AccountManageView();

  @override
  State<_AccountManageView> createState() => _AccountManageViewState();
}

class _AccountManageViewState extends State<_AccountManageView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  String? _emailError;
  String? _passwordError;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _emailController.text =
        context.read<AccountManageCubit>().currentEmail ?? '';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _saveEmail(AppLocalizations l10n) {
    final email = _emailController.text.trim();
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!valid) {
      setState(() => _emailError = l10n.authEmailInvalid);
      return;
    }
    if (email == (context.read<AccountManageCubit>().currentEmail ?? '')) {
      setState(() => _emailError = l10n.accountManageEmailUnchanged);
      return;
    }
    setState(() => _emailError = null);
    FocusScope.of(context).unfocus();
    context.read<AccountManageCubit>().updateEmail(email);
  }

  void _savePassword(AppLocalizations l10n) {
    final password = _passwordController.text;
    if (password.length < 6) {
      setState(() => _passwordError = l10n.authPasswordTooShort);
      return;
    }
    if (password != _confirmController.text) {
      setState(() => _passwordError = l10n.accountManagePasswordMismatch);
      return;
    }
    setState(() => _passwordError = null);
    FocusScope.of(context).unfocus();
    context.read<AccountManageCubit>().updatePassword(password);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<AccountManageCubit, AccountManageState>(
      listenWhen: (prev, curr) =>
          curr.outcome != AccountManageOutcome.none ||
          curr.message != prev.message,
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);
        switch (state.outcome) {
          case AccountManageOutcome.emailUpdated:
            messenger
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(l10n.accountManageEmailSent)),
              );
          case AccountManageOutcome.passwordUpdated:
            _passwordController.clear();
            _confirmController.clear();
            messenger
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(l10n.accountManagePasswordUpdated)),
              );
          case AccountManageOutcome.none:
            break;
        }
        if (state.message != null) {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message!)));
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: Text(l10n.accountManageTitle)),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              _SectionCard(
                title: l10n.accountManageEmailSection,
                subtitle: l10n.accountManageEmailHelp,
                children: [
                  _Label(l10n.authEmailLabel),
                  const SizedBox(height: 7),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    onChanged: (_) {
                      if (_emailError != null) {
                        setState(() => _emailError = null);
                      }
                    },
                    decoration: _decoration(
                      hint: l10n.authEmailHint,
                      errorText: _emailError,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SaveButton(
                    label: l10n.commonSave,
                    saving: state.savingEmail,
                    onPressed: () => _saveEmail(l10n),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _SectionCard(
                title: l10n.accountManagePasswordSection,
                subtitle: l10n.accountManagePasswordHelp,
                children: [
                  _Label(l10n.accountManageNewPassword),
                  const SizedBox(height: 7),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    onChanged: (_) {
                      if (_passwordError != null) {
                        setState(() => _passwordError = null);
                      }
                    },
                    decoration: _decoration(
                      hint: l10n.authPasswordHint,
                      errorText: _passwordError,
                      suffix: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _Label(l10n.accountManageConfirmPassword),
                  const SizedBox(height: 7),
                  TextField(
                    controller: _confirmController,
                    obscureText: _obscure,
                    onChanged: (_) {
                      if (_passwordError != null) {
                        setState(() => _passwordError = null);
                      }
                    },
                    decoration: _decoration(
                      hint: l10n.accountManageConfirmPasswordHint,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SaveButton(
                    label: l10n.commonSave,
                    saving: state.savingPassword,
                    onPressed: () => _savePassword(l10n),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  InputDecoration _decoration({
    required String hint,
    String? errorText,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      errorText: errorText,
      suffixIcon: suffix,
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

/// Carte de section (titre + aide + champs), style cohérent avec les pages
/// d'édition existantes.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.label,
    required this.saving,
    required this.onPressed,
  });

  final String label;
  final bool saving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton(
        onPressed: saving ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: saving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                ),
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
