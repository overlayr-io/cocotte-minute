import 'package:flutter/material.dart';

import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../domain/concept_guide.dart';
import '../../domain/concept_guides_catalog.dart';
import 'concept_guide_page.dart';

/// Liste des guides de concepts (#13) : chaque tuile ouvre un guide explicatif
/// simple (avec vidéo à venir). Accessible depuis l'onglet Compte, section Aide.
class ConceptGuidesPage extends StatelessWidget {
  const ConceptGuidesPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const ConceptGuidesPage());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final guides = conceptGuides(l10n);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.conceptGuidesTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            l10n.conceptGuidesIntro,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: Color(0xFF8A8574),
            ),
          ),
          const SizedBox(height: 16),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppShadows.card,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Column(
                children: [
                  for (var i = 0; i < guides.length; i++) ...[
                    _GuideTile(guide: guides[i]),
                    if (i != guides.length - 1)
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFF1EEE7),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideTile extends StatelessWidget {
  const _GuideTile({required this.guide});

  final ConceptGuide guide;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).push(ConceptGuidePage.route(guide)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(guide.icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guide.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      guide.summary,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: Color(0xFFCBC7BB),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
