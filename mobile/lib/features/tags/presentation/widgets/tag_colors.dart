import 'package:flutter/material.dart';

/// Palette fermée des couleurs de tag (miroir de `TAG_COLORS` côté serveur).
///
/// Chaque couleur de premier plan (pastille / texte) est associée à un tint
/// clair servant de fond de chip, comme dans la maquette 3m.
class TagColors {
  const TagColors._();

  /// Couleurs sélectionnables, dans l'ordre d'affichage du sélecteur.
  static const List<Color> options = [
    Color(0xFF3F7D3A), // vert
    Color(0xFFB14A3F), // rouge
    Color(0xFF3D6DA8), // bleu
    Color(0xFFB8862F), // or
    Color(0xFF8A5BB0), // violet
    Color(0xFFC86A3C), // orange
  ];

  static const Map<int, Color> _tints = {
    0xFF3F7D3A: Color(0xFFE3F0DE),
    0xFFB14A3F: Color(0xFFFBE4E1),
    0xFF3D6DA8: Color(0xFFE1EAF5),
    0xFFB8862F: Color(0xFFF6EEDD),
    0xFF8A5BB0: Color(0xFFEDE4F3),
    0xFFC86A3C: Color(0xFFF7E7DC),
  };

  /// Couleur de premier plan par défaut (première de la palette).
  static Color get fallback => options.first;

  /// Fond clair associé à une couleur de tag ; dérivé par transparence si la
  /// couleur ne fait pas partie de la palette connue.
  static Color tint(Color color) =>
      _tints[color.toARGB32()] ?? color.withValues(alpha: 0.14);

  /// Parse un code hex `#RRGGBB` en [Color] opaque. Retombe sur [fallback] si
  /// la chaîne est invalide (robustesse face à une donnée serveur inattendue).
  static Color parse(String hex) {
    final cleaned = hex.startsWith('#') ? hex.substring(1) : hex;
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null || cleaned.length != 6) return fallback;
    return Color(0xFF000000 | value);
  }

  /// Sérialise une [Color] en `#RRGGBB` majuscule pour l'API.
  static String toHex(Color color) {
    final rgb = color.toARGB32() & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}
