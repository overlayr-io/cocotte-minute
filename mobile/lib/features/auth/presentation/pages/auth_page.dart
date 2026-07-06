import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show OAuthProvider;

import '../../../../core/di/service_locator.dart';
import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/auth_repository.dart';
import '../bloc/auth_form_bloc.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/keep_data_sheet.dart';
import '../widgets/legal_notice.dart';
import '../widgets/social_auth_buttons.dart';

/// Écran Login / Inscription (maquette 2b).
///
/// L'utilisateur arrive ici en tant qu'invité (compte anonyme). "Créer mon
/// compte" convertit le compte en conservant les données ; s'il était invité,
/// la modal "conserver / repartir" (système 1c) est ensuite proposée.
class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const AuthPage());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthFormBloc(repository: sl<AuthRepository>()),
      child: const _AuthView(),
    );
  }
}

enum _AuthMode { create, signIn }

class _AuthView extends StatefulWidget {
  const _AuthView();

  @override
  State<_AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<_AuthView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  _AuthMode _mode = _AuthMode.create;
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isCreate => _mode == _AuthMode.create;

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final bloc = context.read<AuthFormBloc>();
    if (_isCreate) {
      bloc.add(
        AuthFormAccountCreationRequested(email: email, password: password),
      );
    } else {
      bloc.add(AuthFormSignInRequested(email: email, password: password));
    }
  }

  Future<void> _onAccountReady(bool wasGuest) async {
    if (wasGuest) {
      final choice = await showKeepDataSheet(context);
      if (!mounted) return;
      if (choice == KeepDataChoice.reset) {
        context.read<AuthFormBloc>().add(
          const AuthFormGuestDataResetRequested(),
        );
        return; // fermeture gérée à la réception de AuthFormGuestDataReset
      }
    }
    _close();
  }

  void _close() {
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: BlocListener<AuthFormBloc, AuthFormState>(
        listener: (context, state) {
          switch (state) {
            case AuthFormAccountReady(:final wasGuest):
              _onAccountReady(wasGuest);
            case AuthFormGuestDataReset():
              _close();
            case AuthFormFailure(:final message):
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(message)));
            case AuthFormInitial() || AuthFormSubmitting():
              break;
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(26, 4, 26, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TopBar(onBack: _close, onSkip: _close),
                const SizedBox(height: 12),
                const _AppIconPlaceholder(),
                const SizedBox(height: 18),
                Text(
                  _isCreate ? l10n.authCreateTitle : l10n.authSignInTitle,
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w700,
                    fontSize: 29,
                    height: 1.1,
                    letterSpacing: -0.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isCreate ? l10n.authCreateSubtitle : l10n.authSignInSubtitle,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AuthTextField(
                        label: l10n.authEmailLabel,
                        hint: l10n.authEmailHint,
                        icon: Icons.mail_outline,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        validator: (v) => _validateEmail(v, l10n),
                      ),
                      const SizedBox(height: 16),
                      AuthTextField(
                        label: l10n.authPasswordLabel,
                        hint: l10n.authPasswordHint,
                        icon: Icons.lock_outline,
                        controller: _passwordController,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        validator: (v) => _validatePassword(v, l10n),
                        suffix: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _PrimaryButton(
                  label: _isCreate
                      ? l10n.authCreateAction
                      : l10n.authSignInAction,
                  onPressed: _submit,
                ),
                if (kDebugMode) ...[
                  _OrDivider(label: l10n.authDividerOr),
                  SocialAuthButtons(
                    onGoogle: () => context.read<AuthFormBloc>().add(
                      const AuthFormOAuthRequested(OAuthProvider.google),
                    ),
                    onApple: () => context.read<AuthFormBloc>().add(
                      const AuthFormOAuthRequested(OAuthProvider.apple),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Center(child: _SwitchModeLink(isCreate: _isCreate, onTap: _toggleMode)),
                const SizedBox(height: 16),
                const LegalNotice(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleMode() {
    setState(() {
      _mode = _isCreate ? _AuthMode.signIn : _AuthMode.create;
    });
  }

  String? _validateEmail(String? value, AppLocalizations l10n) {
    final v = value?.trim() ?? '';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);
    return ok ? null : l10n.authEmailInvalid;
  }

  String? _validatePassword(String? value, AppLocalizations l10n) {
    return (value ?? '').length >= 6 ? null : l10n.authPasswordTooShort;
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack, required this.onSkip});

  final VoidCallback onBack;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Material(
          color: AppColors.card,
          shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onBack,
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Icon(Icons.chevron_left, color: AppColors.textPrimary),
            ),
          ),
        ),
      ],
    );
  }
}

/// Emplacement de l'icône de l'app (le logo réel sera ajouté plus tard).
class _AppIconPlaceholder extends StatelessWidget {
  const _AppIconPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 66,
      height: 66,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFD8D4C8),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, size: 22, color: Color(0xFFB7B2A4)),
          SizedBox(height: 2),
          Text(
            'Logo app',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Color(0xFFB7B2A4),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final submitting = context.select<AuthFormBloc, bool>(
      (b) => b.state is AuthFormSubmitting,
    );
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: FilledButton(
        onPressed: submitting ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: submitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.divider, height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ),
          const Expanded(child: Divider(color: AppColors.divider, height: 1)),
        ],
      ),
    );
  }
}

class _SwitchModeLink extends StatelessWidget {
  const _SwitchModeLink({required this.isCreate, required this.onTap});

  final bool isCreate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Text.rich(
        TextSpan(
          style: const TextStyle(fontSize: 13.5, color: AppColors.textMuted),
          children: [
            TextSpan(
              text: isCreate
                  ? '${l10n.authAlreadyHaveAccount} '
                  : '${l10n.authNoAccountYet} ',
            ),
            TextSpan(
              text: isCreate ? l10n.authSwitchToSignIn : l10n.authSwitchToCreate,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
