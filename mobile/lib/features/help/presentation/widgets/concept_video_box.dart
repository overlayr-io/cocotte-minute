import 'package:flutter/material.dart';

import '../../../../core/i18n/generated/app_localizations.dart';

/// Emplacement vidéo d'un guide de concept (#13). Tant qu'aucune vidéo n'est
/// fournie ([videoUrl] == null), affiche un état « bientôt disponible ». Point
/// de bascule unique : quand le lecteur réel (embed YouTube / package vidéo)
/// sera branché, seule cette classe changera.
class ConceptVideoBox extends StatelessWidget {
  const ConceptVideoBox({super.key, this.videoUrl});

  final String? videoUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E3A2B), Color(0xFF41533B)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.conceptVideoComingSoon,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
