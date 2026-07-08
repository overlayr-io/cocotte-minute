import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/i18n/generated/app_localizations.dart';
import '../bloc/account_status_cubit.dart';

/// Bannière globale d'annulation de suppression (RGPD).
///
/// N'affiche rien tant que le compte n'est pas `pending_deletion`. Quand une
/// suppression est en attente, propose de l'annuler (« Annuler la suppression »)
/// via [AccountStatusCubit.cancelDeletion]. À succès : snackbar de confirmation
/// puis la bannière disparaît. S'appuie sur l'[AccountStatusCubit] fourni plus
/// haut dans l'arbre (cf. `MainShell`).
class CancelDeletionBanner extends StatelessWidget {
  const CancelDeletionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<AccountStatusCubit, AccountStatusState>(
      listenWhen: (_, s) =>
          s is AccountStatusCancelSuccess || s is AccountStatusCancelFailure,
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);
        switch (state) {
          case AccountStatusCancelSuccess():
            messenger
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(l10n.cancelDeletionSuccess)),
              );
          case AccountStatusCancelFailure(:final message):
            messenger
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(message)));
          default:
            break;
        }
      },
      buildWhen: (_, s) =>
          s is AccountStatusPending || s is AccountStatusHidden,
      builder: (context, state) {
        if (state is! AccountStatusPending) return const SizedBox.shrink();
        return SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: _BannerCard(
              title: l10n.cancelDeletionBannerTitle,
              body: l10n.cancelDeletionBannerBody,
              ctaLabel: l10n.cancelDeletionBannerCta,
              busy: state.cancelling,
              onCancel: () =>
                  context.read<AccountStatusCubit>().cancelDeletion(),
            ),
          ),
        );
      },
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.title,
    required this.body,
    required this.ctaLabel,
    required this.busy,
    required this.onCancel,
  });

  final String title;
  final String body;
  final String ctaLabel;
  final bool busy;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFFFBE9E7),
        border: Border.all(color: const Color(0xFFF3C6C0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFE0554A),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFC0392B),
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            body,
            style: const TextStyle(
              color: Color(0xFF7A4A44),
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton(
              onPressed: busy ? null : onCancel,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE0554A),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(
                  0xFFE0554A,
                ).withValues(alpha: 0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      ctaLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
