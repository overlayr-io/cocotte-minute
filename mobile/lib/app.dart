import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/auth/auth_bloc.dart';
import 'core/i18n/generated/app_localizations.dart';
import 'core/i18n/locale_cubit.dart';
import 'core/navigation/main_shell.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/error_view.dart';
import 'features/auth/presentation/pages/auth_page.dart';

class CocotteApp extends StatelessWidget {
  const CocotteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc()..add(const AuthStarted())),
        BlocProvider(create: (_) => LocaleCubit()..load()),
      ],
      child: BlocBuilder<LocaleCubit, Locale?>(
        builder: (context, locale) {
          return MaterialApp(
            onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            // `null` = suit la langue de l'appareil (option « Système »).
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const _AuthGate(),
          );
        },
      ),
    );
  }
}

/// Aiguille l'utilisateur selon l'état d'authentification résolu au démarrage.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return switch (state) {
          // La clé par `userId` garantit une coquille neuve (onglet Accueil) au
          // changement de compte — ex. recréation d'un compte invité après
          // suppression, qui doit repartir « comme une première installation ».
          AuthAuthenticated(:final user) => MainShell(key: ValueKey(user.id)),
          // Après déconnexion explicite : écran de connexion/inscription.
          AuthUnauthenticated() => const AuthPage(),
          AuthFailure(:final message) => ErrorView(
              message: message,
              onRetry: () =>
                  context.read<AuthBloc>().add(const AuthStarted()),
            ),
          _ => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
        };
      },
    );
  }
}
