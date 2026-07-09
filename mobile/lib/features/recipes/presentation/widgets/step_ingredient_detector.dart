import '../../../../core/utils/text_normalize.dart';
import '../../domain/recipe.dart';

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
