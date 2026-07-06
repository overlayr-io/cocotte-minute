import 'package:flutter/material.dart';

/// Thème de l'application.
///
/// Volontairement minimal pour le bootstrap : une seed color et Material 3.
/// Les tokens de design (couleurs, typographies) seront affinés au fil des
/// features, après validation d'un aperçu design.
class AppTheme {
  const AppTheme._();

  static const Color _seed = Color(0xFFE8590C); // orange "cocotte"

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _seed),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.dark,
        ),
      );
}
