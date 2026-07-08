import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/resume_state.dart';

/// Persistance locale de l'état de reprise du mode pas-à-pas.
///
/// Un seul emplacement global (pas de clé par recette) : une seule session de
/// cuisson à la fois, cf. `docs/features/step-by-step.md`. Ce n'est PAS un
/// repository serveur — rien ici ne quitte jamais l'appareil.
class RecipePlayerStorage {
  const RecipePlayerStorage();

  static const _key = 'recipe_player.resume_state';

  Future<ResumeState?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return ResumeState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      // Donnée corrompue/format obsolète : on l'ignore plutôt que de planter
      // le lancement du mode cuisine.
      return null;
    }
  }

  Future<void> write(ResumeState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
