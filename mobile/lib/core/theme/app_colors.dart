import 'package:flutter/material.dart';

/// Tokens de couleur issus de la maquette Cocotte Minute (handoff design).
///
/// Source de vérité visuelle : direction "vert principal + corail accent" sur
/// fonds crème. À utiliser via le thème (`AppTheme`) plutôt qu'en dur dans les
/// écrans autant que possible.
class AppColors {
  const AppColors._();

  // Marque
  static const Color primary = Color(0xFF6B8E5A); // vert principal
  static const Color accent = Color(0xFFFF6F61); // corail "doux"

  // Fonds
  static const Color background = Color(0xFFEDEAE2); // fond app
  static const Color surface = Color(0xFFF7F6F2); // fond écran / sheet
  static const Color card = Color(0xFFFFFFFF); // champs, cartes

  // Teintes de support
  static const Color primaryTint = Color(0xFFEFF3EC); // vert très clair (badges)
  static const Color pill = Color(0xFFF1EEE4); // conteneur segmenté (système 1c)
  static const Color accentTint = Color(0xFFFBECEA); // corail très clair

  // Texte
  static const Color textPrimary = Color(0xFF1F2933);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  // Bordures / séparateurs
  static const Color border = Color(0xFFECEAE3);
  static const Color divider = Color(0xFFE4E1D8);
  static const Color radioIdle = Color(0xFFCFCBC0);

  // Sémantique
  static const Color danger = Color(0xFFEF4444);
}

/// Familles de polices (déclarées dans pubspec.yaml, fichiers dans assets/fonts).
class AppFonts {
  const AppFonts._();

  /// Titres / affichage.
  static const String display = 'Bricolage Grotesque';

  /// Texte courant / UI.
  static const String body = 'Hanken Grotesk';
}
