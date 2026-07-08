import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gère la langue choisie par l'utilisateur.
///
/// L'état est un [Locale] nullable : `null` = « Système (automatique) », c.-à-d.
/// que `MaterialApp.locale` reste `null` et Flutter suit la langue de l'appareil.
/// Un code de langue explicite (`fr`, `en`) force cette langue.
///
/// Le choix est persisté localement via `shared_preferences` (même mécanisme que
/// le reste de l'app) et rechargé au démarrage.
class LocaleCubit extends Cubit<Locale?> {
  LocaleCubit() : super(null);

  static const _key = 'app.locale';

  /// Langues sélectionnables explicitement (hors « Système »).
  static const supported = <Locale>[Locale('fr'), Locale('en')];

  /// Charge le choix persisté. À appeler une fois au démarrage.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code == null || code.isEmpty) {
      emit(null);
      return;
    }
    emit(Locale(code));
  }

  /// Applique et persiste un nouveau choix (`null` = suivre le système).
  Future<void> setLocale(Locale? locale) async {
    emit(locale);
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, locale.languageCode);
    }
  }
}
