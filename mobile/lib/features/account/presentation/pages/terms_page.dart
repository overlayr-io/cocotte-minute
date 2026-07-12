import 'package:flutter/material.dart';

import '../../../../core/i18n/generated/app_localizations.dart';
import '../widgets/legal_page.dart';

/// Conditions d'utilisation : règles simples du service.
class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const TermsPage());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LegalPage(
      title: l10n.accountRowTerms,
      intro: l10n.termsIntro,
      sections: [
        LegalSection(l10n.termsS1Title, l10n.termsS1Body),
        LegalSection(l10n.termsS2Title, l10n.termsS2Body),
        LegalSection(l10n.termsS3Title, l10n.termsS3Body),
        LegalSection(l10n.termsS4Title, l10n.termsS4Body),
        LegalSection(l10n.termsS5Title, l10n.termsS5Body),
        LegalSection(l10n.termsS6Title, l10n.termsS6Body),
        LegalSection(l10n.termsS7Title, l10n.termsS7Body),
        LegalSection(l10n.termsS8Title, l10n.termsS8Body),
        LegalSection(l10n.termsS9Title, l10n.termsS9Body),
      ],
    );
  }
}
