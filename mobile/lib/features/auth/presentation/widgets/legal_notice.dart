import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// Mentions légales en bas de l'écran d'auth : "En continuant, tu acceptes
/// nos Conditions d'utilisation et notre Politique de confidentialité."
///
/// Les liens sont cliquables ; les destinations (CGU / confidentialité) seront
/// branchées quand les pages/URLs seront disponibles.
class LegalNotice extends StatelessWidget {
  const LegalNotice({super.key, this.onTapTerms, this.onTapPrivacy});

  final VoidCallback? onTapTerms;
  final VoidCallback? onTapPrivacy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const base = TextStyle(
      fontSize: 11.5,
      height: 1.55,
      color: AppColors.textMuted,
    );
    final link = base.copyWith(
      color: AppColors.primary,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
    );

    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: l10n.authLegalPrefix),
          TextSpan(
            text: l10n.authLegalTerms,
            style: link,
            recognizer: TapGestureRecognizer()..onTap = onTapTerms,
          ),
          TextSpan(text: l10n.authLegalAnd),
          TextSpan(
            text: l10n.authLegalPrivacy,
            style: link,
            recognizer: TapGestureRecognizer()..onTap = onTapPrivacy,
          ),
          TextSpan(text: l10n.authLegalSuffix),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
