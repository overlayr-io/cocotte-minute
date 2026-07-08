import 'package:flutter/material.dart';

import '../../domain/search_token.dart';

/// Palette propre à la recherche avancée : chaque dimension a sa famille de
/// couleurs (dossier = vert, tag = ambre, personne = violet), reprises de la
/// maquette 11a-e et non génériques du thème.
class SearchColors {
  const SearchColors._();

  // Dossiers (/)
  static const Color folder = Color(0xFF6B8E5A);
  static const Color folderText = Color(0xFF5C7A4C);
  static const Color folderTint = Color(0xFFEEF3E9);
  static const Color folderRowTint = Color(0xFFF1F5EC);
  static const Color folderBorder = Color(0xFFD8E4CE);

  // Tags (#)
  static const Color tag = Color(0xFFB8792B);
  static const Color tagBorder = Color(0xFFE0B15E);
  static const Color tagTint = Color(0xFFF6EEDF);
  static const Color tagRowTint = Color(0xFFFBF4E8);

  // Personnes (@)
  static const Color person = Color(0xFF8A6AA0);
  static const Color personBorder = Color(0xFFB79BCB);
  static const Color personTint = Color(0xFFF1ECF5);
  static const Color personRowTint = Color(0xFFF5F1F8);

  // Divers
  static const Color sectionLabel = Color(0xFFA79F8B);
  static const Color muted = Color(0xFFB0A892);

  /// Couleur d'accent d'une dimension (bouton déclencheur / texte de saisie).
  static Color accentOf(SearchDimension dim) => switch (dim) {
        SearchDimension.folder => folderText,
        SearchDimension.tag => tag,
        SearchDimension.person => person,
      };

  static Color tintOf(SearchDimension dim) => switch (dim) {
        SearchDimension.folder => folderRowTint,
        SearchDimension.tag => tagTint,
        SearchDimension.person => personTint,
      };

  static Color borderOf(SearchDimension dim) => switch (dim) {
        SearchDimension.folder => folder,
        SearchDimension.tag => tagBorder,
        SearchDimension.person => personBorder,
      };

  static Color rowTintOf(SearchDimension dim) => switch (dim) {
        SearchDimension.folder => folderRowTint,
        SearchDimension.tag => tagRowTint,
        SearchDimension.person => personRowTint,
      };
}
