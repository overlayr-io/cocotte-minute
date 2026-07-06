import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/auth/auth_bloc.dart';
import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../auth/presentation/pages/auth_page.dart';

/// Page d'accueil provisoire — sert de point d'ancrage au bootstrap.
/// Les vraies pages de features viendront après validation du design.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authState = context.watch<AuthBloc>().state;
    final isAnonymous =
        authState is AuthAuthenticated && authState.isAnonymous;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.homeWelcome),
            const SizedBox(height: 8),
            if (isAnonymous)
              const Text(
                'Session anonyme active',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            // CTA temporaire vers l'écran d'auth, en attendant l'écran Compte.
            if (isAnonymous) ...[
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () =>
                    Navigator.of(context).push(AuthPage.route()),
                child: Text(l10n.homeCreateAccountCta),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
