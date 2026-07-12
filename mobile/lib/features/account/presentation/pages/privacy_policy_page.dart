import 'package:flutter/material.dart';

import '../../../../core/i18n/generated/app_localizations.dart';
import '../widgets/legal_page.dart';

/// Politique de confidentialité : ce que l'app collecte, pourquoi, où, combien
/// de temps, et les droits de l'utilisateur.
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const PrivacyPolicyPage());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LegalPage(
      title: l10n.accountRowPrivacyPolicy,
      intro: l10n.privacyPolicyIntro,
      sections: [
        LegalSection(l10n.privacyPolicyS1Title, l10n.privacyPolicyS1Body),
        LegalSection(l10n.privacyPolicyS2Title, l10n.privacyPolicyS2Body),
        LegalSection(l10n.privacyPolicyS3Title, l10n.privacyPolicyS3Body),
        LegalSection(l10n.privacyPolicyS4Title, l10n.privacyPolicyS4Body),
        LegalSection(l10n.privacyPolicyS5Title, l10n.privacyPolicyS5Body),
        LegalSection(l10n.privacyPolicyS6Title, l10n.privacyPolicyS6Body),
        LegalSection(l10n.privacyPolicyS7Title, l10n.privacyPolicyS7Body),
        LegalSection(l10n.privacyPolicyS8Title, l10n.privacyPolicyS8Body),
        LegalSection(l10n.privacyPolicyS9Title, l10n.privacyPolicyS9Body),
        LegalSection(l10n.privacyPolicyS10Title, l10n.privacyPolicyS10Body),
        LegalSection(l10n.privacyPolicyS11Title, l10n.privacyPolicyS11Body),
        LegalSection(l10n.privacyPolicyS12Title, l10n.privacyPolicyS12Body),
      ],
    );
  }
}
