import '../../../../core/utils/text_normalize.dart';
import '../../domain/recipe.dart';

/// Variantes « mot entier » d'un nom d'ingrédient replié, pour tolérer un
/// pluriel simple (français) dans les deux sens (nom singulier ↔ texte pluriel).
/// Ne retient que le premier mot significatif du nom : un nom composé d'une
/// base + qualificatif(s) (« Beurre doux », « Farine T55 ») est ainsi détecté
/// dès que le texte mentionne juste la base (« Beurre », « Farine »). Ce
/// choix privilégie le rappel : deux variantes d'un même ingrédient de base
/// (« Sucre roux » / « Sucre glace ») peuvent toutes les deux matcher un
/// texte qui n'en mentionne qu'une — accepté (traitement local, ajustable
/// manuellement par l'utilisateur ensuite).
Set<String> _forms(String folded) {
  final words = folded.trim().split(' ');
  final firstWord = words.isEmpty ? '' : words.first;
  if (firstWord.isEmpty) return const {};
  final forms = <String>{firstWord, '${firstWord}s', '${firstWord}x'};
  // Mot déjà au pluriel : ajoute la forme singulière.
  if (firstWord.length > 2 &&
      (firstWord.endsWith('s') || firstWord.endsWith('x'))) {
    forms.add(firstWord.substring(0, firstWord.length - 1));
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
