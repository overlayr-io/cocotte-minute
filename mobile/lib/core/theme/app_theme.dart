import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Thème de l'application, aligné sur la maquette Cocotte Minute.
///
/// Direction visuelle : vert principal + corail accent sur fonds crème,
/// titres en Bricolage Grotesque, texte en Hanken Grotesk.
class AppTheme {
  const AppTheme._();

  static ThemeData get light => _build(Brightness.light);

  // Le dark mode reprend la même identité pour l'instant (v1 = clair only côté
  // maquette). On garde l'entrée pour ne pas casser MaterialApp.darkTheme.
  static ThemeData get dark => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: brightness,
        ).copyWith(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.surface,
          error: AppColors.danger,
          onPrimary: Colors.white,
          onSurface: AppColors.textPrimary,
        );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.surface,
      fontFamily: AppFonts.body,
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }

  /// Titres en Bricolage Grotesque, corps en Hanken Grotesk.
  static TextTheme _textTheme(TextTheme base) {
    const display = AppFonts.display;
    return base
        .copyWith(
          displayLarge: base.displayLarge?.copyWith(fontFamily: display),
          displayMedium: base.displayMedium?.copyWith(fontFamily: display),
          displaySmall: base.displaySmall?.copyWith(fontFamily: display),
          headlineLarge: base.headlineLarge?.copyWith(fontFamily: display),
          headlineMedium: base.headlineMedium?.copyWith(fontFamily: display),
          headlineSmall: base.headlineSmall?.copyWith(fontFamily: display),
          titleLarge: base.titleLarge?.copyWith(fontFamily: display),
        )
        .apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        );
  }
}
