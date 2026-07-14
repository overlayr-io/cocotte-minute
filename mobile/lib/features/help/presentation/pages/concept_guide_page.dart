import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/concept_guide.dart';
import '../widgets/concept_video_box.dart';

/// Page d'un guide de concept (#13) : vidéo (à venir) en tête, puis une intro
/// courte et des sections titre + texte, sans jargon. Même esprit que la page
/// légale, avec le bloc vidéo en plus.
class ConceptGuidePage extends StatelessWidget {
  const ConceptGuidePage({super.key, required this.guide});

  final ConceptGuide guide;

  static Route<void> route(ConceptGuide guide) {
    return MaterialPageRoute<void>(
      builder: (_) => ConceptGuidePage(guide: guide),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(guide.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
        children: [
          ConceptVideoBox(videoUrl: guide.videoUrl),
          const SizedBox(height: 20),
          Text(
            guide.intro,
            style: const TextStyle(
              fontSize: 14.5,
              height: 1.55,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          for (final section in guide.sections) ...[
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
