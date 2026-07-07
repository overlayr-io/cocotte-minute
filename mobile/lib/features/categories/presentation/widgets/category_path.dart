import '../../domain/category.dart';

/// Construit le fil d'Ariane d'un dossier ("Plat › Pâtes") en remontant la
/// chaîne des parents dans la liste à plat fournie.
String categoryPath(Category category, List<Category> all, {String separator = ' › '}) {
  final byId = {for (final c in all) c.id: c};
  final parts = <String>[];
  Category? cursor = category;
  final seen = <String>{};
  while (cursor != null && seen.add(cursor.id)) {
    parts.insert(0, cursor.name);
    final parentId = cursor.parentCategoryId;
    cursor = parentId == null ? null : byId[parentId];
  }
  return parts.join(separator);
}
