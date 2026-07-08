import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Page de texte légal (politique de confidentialité, conditions d'utilisation) :
/// une intro courte puis des sections titre + paragraphe, sans jargon.
class LegalPage extends StatelessWidget {
  const LegalPage({
    super.key,
    required this.title,
    required this.intro,
    required this.sections,
  });

  final String title;
  final String intro;
  final List<LegalSection> sections;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
        children: [
          Text(
            intro,
            style: const TextStyle(
              fontSize: 14.5,
              height: 1.55,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          for (final section in sections) ...[
            const SizedBox(height: 24),
            Text(
              section.title,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w700,
                fontSize: 16.5,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              section.body,
              style: const TextStyle(
                fontSize: 14,
                height: 1.55,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class LegalSection {
  const LegalSection(this.title, this.body);

  final String title;
  final String body;
}
