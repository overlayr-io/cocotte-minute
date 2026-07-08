import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/auth_repository.dart';
import '../../data/account_repository.dart';
import '../bloc/account_deletion_cubit.dart';

/// Écran de demande de suppression de compte (RGPD).
///
/// Remplace l'ancien placeholder « bientôt disponible ». Le wording et le
/// comportement diffèrent selon que le compte est anonyme (suppression
/// définitive immédiate) ou complet (anonymisation + délai de 30 jours).
class DeleteAccountPage extends StatelessWidget {
  const DeleteAccountPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const DeleteAccountPage());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AccountDeletionCubit(
        accountRepository: sl<AccountRepository>(),
        authRepository: sl<AuthRepository>(),
      ),
      child: const _DeleteAccountView(),
    );
  }
}

class _DeleteAccountView extends StatelessWidget {
  const _DeleteAccountView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // On fige la nature du compte à l'ouverture de l'écran : l'auth peut
    // basculer juste après la suppression (recréation anonyme / déconnexion).
    final isAnonymous = sl<AuthRepository>().isAnonymous;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.deleteAccountTitle)),
      body: BlocConsumer<AccountDeletionCubit, AccountDeletionState>(
        listener: (context, state) {
          final messenger = ScaffoldMessenger.of(context);
          switch (state) {
            case AccountDeletionGuestRecreated():
              // Compte invité recréé → retour à l'accueil vierge.
              Navigator.of(context).popUntil((r) => r.isFirst);
              messenger
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(content: Text(l10n.deleteAccountGuestDone)),
                );
            case AccountDeletionPending():
              // Compte complet déconnecté → retour à l'écran d'auth.
              Navigator.of(context).popUntil((r) => r.isFirst);
              messenger
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(content: Text(l10n.deleteAccountPendingDone)),
                );
            case AccountDeletionFailure(:final message):
              messenger
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(message)));
            case AccountDeletionInitial() || AccountDeletionInProgress():
              break;
          }
        },
        builder: (context, state) {
          final busy = state is AccountDeletionInProgress;
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBE9E7),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFE0554A),
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isAnonymous
                        ? l10n.deleteAccountGuestHeading
                        : l10n.deleteAccountFullHeading,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isAnonymous
                        ? l10n.deleteAccountGuestBody
                        : l10n.deleteAccountFullBody,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 54,
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: busy
                          ? null
                          : () => context
                                .read<AccountDeletionCubit>()
                                .requestDeletion(),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE0554A),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(
                          0xFFE0554A,
                        ).withValues(alpha: 0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: busy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              l10n.deleteAccountConfirm,
                              style: const TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: TextButton(
                      onPressed: busy
                          ? null
                          : () => Navigator.of(context).maybePop(),
                      child: Text(
                        l10n.deleteAccountCancel,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
