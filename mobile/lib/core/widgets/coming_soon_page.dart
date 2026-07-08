import 'package:flutter/material.dart';

import '../i18n/generated/app_localizations.dart';
import '../theme/app_colors.dart';

/// Écran placeholder pour les entrées de menu dont la feature n'est pas encore
/// implémentée (Tags, Dossiers, Famille, Aide, Confidentialité...).
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key, required this.title});

  final String title;

  static Route<void> route(String title) {
    return MaterialPageRoute<void>(builder: (_) => ComingSoonPage(title: title));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.hourglass_bottom_rounded,
                    color: AppColors.primary, size: 30),
              ),
              const SizedBox(height: 18),
              Text(
                l10n.comingSoonTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.comingSoonBody,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
