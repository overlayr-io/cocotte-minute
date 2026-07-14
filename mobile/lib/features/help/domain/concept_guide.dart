import 'package:flutter/widgets.dart';

/// Guide explicatif d'un concept de l'app (#13) : un texte simple, sans jargon,
/// accompagné (à terme) d'une vidéo. Le contenu vient de l'i18n.
class ConceptGuide {
  const ConceptGuide({
    required this.id,
    required this.icon,
    required this.title,
    required this.summary,
    required this.intro,
    required this.sections,
    this.videoUrl,
  });

  /// Identifiant stable (analytics / deep-link éventuel).
  final String id;
  final IconData icon;
  final String title;

  /// Accroche courte affichée dans la liste des guides.
  final String summary;
  final String intro;
  final List<ConceptSection> sections;

  /// URL de la vidéo du concept. `null` pour l'instant : la section vidéo
  /// affiche un état « bientôt disponible » (le lecteur réel viendra plus tard).
  final String? videoUrl;
}

class ConceptSection {
  const ConceptSection(this.title, this.body);

  final String title;
  final String body;
}
