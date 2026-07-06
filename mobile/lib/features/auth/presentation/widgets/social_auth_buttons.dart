import 'package:flutter/material.dart';

import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// Boutons "Continuer avec Google / Apple".
///
/// ⚠️ Affichés uniquement en build de développement (voir usage avec
/// `kDebugMode` dans l'écran). Le câblage OAuth natif (redirect URLs,
/// Sign in with Apple) sera finalisé avant activation en production.
class SocialAuthButtons extends StatelessWidget {
  const SocialAuthButtons({
    super.key,
    required this.onGoogle,
    required this.onApple,
    this.enabled = true,
  });

  final VoidCallback onGoogle;
  final VoidCallback onApple;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        _SocialButton(
          label: l10n.authContinueGoogle,
          background: AppColors.card,
          foreground: AppColors.textPrimary,
          border: AppColors.border,
          leading: const _GoogleGlyph(),
          onPressed: enabled ? onGoogle : null,
        ),
        const SizedBox(height: 12),
        _SocialButton(
          label: l10n.authContinueApple,
          background: AppColors.textPrimary,
          foreground: Colors.white,
          leading: const Icon(Icons.apple, size: 22, color: Colors.white),
          onPressed: enabled ? onApple : null,
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.leading,
    required this.onPressed,
    this.border,
  });

  final String label;
  final Color background;
  final Color foreground;
  final Widget leading;
  final VoidCallback? onPressed;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: border != null
                ? BorderSide(color: border!)
                : BorderSide.none,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            leading,
            const SizedBox(width: 11),
            Text(
              label,
              style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

/// Petit "G" Google stylisé (évite d'embarquer un asset logo pour du dev-only).
class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFF4285F4),
        shape: BoxShape.circle,
      ),
      child: const Text(
        'G',
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
