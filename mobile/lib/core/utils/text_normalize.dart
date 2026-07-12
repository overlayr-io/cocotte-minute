/// Replie une chaîne pour la comparaison : minuscules, accents retirés, et tout
/// caractère non alphanumérique remplacé par une espace (espaces normalisés).
/// Le résultat est encadré d'espaces pour permettre une recherche « mot entier »
/// par simple test de sous-chaîne (`" mot "`).
String foldForMatch(String input) {
  final lower = input.toLowerCase();
  final buffer = StringBuffer(' ');
  for (final rune in lower.runes) {
    final ch = String.fromCharCode(rune);
    final folded = _accentFolds[ch];
    if (folded != null) {
      buffer.write(folded);
    } else if (_isAlphaNum(rune)) {
      buffer.write(ch);
    } else {
      buffer.write(' ');
    }
  }
  buffer.write(' ');
  // Espaces multiples → une seule.
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ');
}

bool _isAlphaNum(int rune) {
  return (rune >= 48 && rune <= 57) || // 0-9
      (rune >= 97 && rune <= 122); // a-z (déjà en minuscule, hors accents)
}

const Map<String, String> _accentFolds = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a',
  'ç': 'c',
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
  'ñ': 'n',
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
  'ý': 'y', 'ÿ': 'y',
  'œ': 'oe', 'æ': 'ae',
};
