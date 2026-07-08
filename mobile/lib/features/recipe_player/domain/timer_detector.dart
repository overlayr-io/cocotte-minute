/// Détecte une durée exprimée en français dans un texte d'étape (ex: "15 min",
/// "20 minutes", "1h30", "2 heures"). Renvoie la première durée trouvée dans
/// l'ordre du texte, ou `null` si aucune n'est détectée.
///
/// Heuristique purement locale (pas de champ serveur dédié) : si une étape
/// mentionne plusieurs durées (ex: "reposer 10 min, puis cuire 20 min"), seule
/// la première est retenue. Le résultat ne sert qu'à pré-remplir le réglage
/// manuel du minuteur — toujours ajustable par l'utilisateur avant de démarrer.
Duration? detectDuration(String text) {
  final candidates = <MapEntry<int, Duration>>[];

  final hourMinutePattern = RegExp(r'(\d+)\s*h\s*(\d{1,2})\b', caseSensitive: false);
  for (final m in hourMinutePattern.allMatches(text)) {
    candidates.add(
      MapEntry(
        m.start,
        Duration(hours: int.parse(m.group(1)!), minutes: int.parse(m.group(2)!)),
      ),
    );
  }

  final hourOnlyPattern = RegExp(r'(\d+)\s*h(?:eures?)?\b', caseSensitive: false);
  for (final m in hourOnlyPattern.allMatches(text)) {
    candidates.add(MapEntry(m.start, Duration(hours: int.parse(m.group(1)!))));
  }

  final minutesPattern = RegExp(r'(\d+)\s*min(?:ute)?s?\b', caseSensitive: false);
  for (final m in minutesPattern.allMatches(text)) {
    candidates.add(MapEntry(m.start, Duration(minutes: int.parse(m.group(1)!))));
  }

  if (candidates.isEmpty) return null;
  candidates.sort((a, b) => a.key.compareTo(b.key));
  return candidates.first.value;
}
