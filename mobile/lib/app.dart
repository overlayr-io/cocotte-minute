import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/auth/auth_bloc.dart';
import 'core/config/env.dart';
import 'core/i18n/generated/app_localizations.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/error_view.dart';
import 'features/home/presentation/pages/home_page.dart';

class CocotteApp extends StatelessWidget {
  const CocotteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc()..add(const AuthStarted()),
      child: MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // Bandeau "DEV" en environnement de développement, pour ne jamais
        // confondre un build dev avec la prod (cf. docs/RUN_LOCAL.md).
        builder: (context, child) {
          if (Env.isProd || child == null) return child ?? const SizedBox();
          return Banner(
            message: 'DEV',
            location: BannerLocation.topStart,
            color: AppColors.accent,
            child: child,
          );
        },
        home: const _AuthGate(),
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
          AuthAuthenticated() => const HomePage(),
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
