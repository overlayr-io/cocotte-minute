import '../../domain/recipe.dart';

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

/// Variantes « mot entier » d'un nom d'ingrédient replié, pour tolérer un
/// pluriel simple (français) dans les deux sens (nom singulier ↔ texte pluriel).
Set<String> _forms(String folded) {
  final name = folded.trim();
  if (name.isEmpty) return const {};
  final forms = <String>{name, '${name}s', '${name}x'};
  // Nom déjà au pluriel : ajoute la forme singulière.
  if (name.length > 2 && (name.endsWith('s') || name.endsWith('x'))) {
    forms.add(name.substring(0, name.length - 1));
  }
  return forms;
}

/// Détecte, parmi [ingredients], ceux dont le nom apparaît (mot entier,
/// insensible à la casse/aux accents, pluriel simple toléré) dans [text].
/// Retourne l'ensemble de leurs ids.
Set<String> detectIngredientIds(
  String text,
  List<RecipeIngredientLine> ingredients,
) {
  final haystack = foldForMatch(text);
  if (haystack.trim().isEmpty) return const {};
  final found = <String>{};
  for (final ing in ingredients) {
    final folded = foldForMatch(ing.name).trim();
    if (folded.isEmpty) continue;
    for (final form in _forms(folded)) {
      if (haystack.contains(' $form ')) {
        found.add(ing.id);
        break;
      }
    }
  }
  return found;
}
