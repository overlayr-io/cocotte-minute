import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Cache de lecture simple (mécanisme n°1 de la stratégie de données locales)
/// pour une liste JSON renvoyée par l'API :
///
/// - **mémoire** avec TTL court : évite de re-télécharger les mêmes données à
///   chaque ouverture d'écran pendant la session ;
/// - **disque** (`shared_preferences`, clé scopée à l'utilisateur courant) :
///   repli quand le réseau est indisponible, y compris après redémarrage.
///
/// Read-only et passif : aucune queue de sync. Toute mutation côté serveur
/// doit appeler [clear] (et celui des caches liés) pour forcer un re-fetch.
class JsonListCache {
  JsonListCache({
    required this.storageKey,
    this.ttl = const Duration(minutes: 5),
  });

  /// Suffixe de la clé de stockage (ex: `tags`, `people`).
  final String storageKey;

  /// Durée pendant laquelle la copie mémoire est servie sans re-fetch.
  final Duration ttl;

  List<Map<String, dynamic>>? _memory;
  DateTime? _fetchedAt;

  /// Clé disque scopée à l'utilisateur (évite de servir le cache d'un autre
  /// compte après déconnexion/reconnexion). Null si personne n'est connecté
  /// ou si Supabase n'est pas initialisé (tests unitaires) → pas de disque.
  String? get _diskKey {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      return userId == null ? null : 'cache/$storageKey/$userId';
    } on Object {
      return null;
    }
  }

  /// Copie mémoire encore valide (TTL non expiré), sinon null.
  List<Map<String, dynamic>>? get fresh {
    final fetchedAt = _fetchedAt;
    if (_memory == null || fetchedAt == null) return null;
    if (DateTime.now().difference(fetchedAt) >= ttl) return null;
    return _memory;
  }

  /// Dernière réponse persistée sur disque (repli hors connexion), sinon null.
  Future<List<Map<String, dynamic>>?> readDisk() async {
    final key = _diskKey;
    if (key == null) return null;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } on Object {
      return null; // contenu corrompu → on l'ignore, le réseau fera foi
    }
  }

  /// Mémorise la réponse fraîche du serveur (mémoire + disque).
  Future<void> write(List<Map<String, dynamic>> items) async {
    _memory = items;
    _fetchedAt = DateTime.now();
    final key = _diskKey;
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(items));
  }

  /// Invalide mémoire et disque (après une mutation serveur).
  Future<void> clear() async {
    _memory = null;
    _fetchedAt = null;
    final key = _diskKey;
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
