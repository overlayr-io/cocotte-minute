import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Liste « À planifier » (bandeau du bas du planning) : ids des recettes que
/// l'utilisateur garde sous la main pour les glisser sur les créneaux.
///
/// Brouillon de travail **local au device** (décision planification-repas.md),
/// clé scopée à l'utilisateur courant comme JsonListCache.
class MealPlanTrayStore {
  static const _prefix = 'meal_plan_tray';

  String? get _key {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      return userId == null ? null : '$_prefix/$userId';
    } on Object {
      return null;
    }
  }

  Future<List<String>> read() async {
    final key = _key;
    if (key == null) return const [];
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key) ?? const [];
  }

  Future<void> write(List<String> recipeIds) async {
    final key = _key;
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, recipeIds);
  }
}
