import 'package:equatable/equatable.dart';

/// Profondeur maximale d'imbrication (racine = niveau 1). Doit rester alignée
/// avec `CATEGORY_MAX_DEPTH` côté serveur.
const int kCategoryMaxDepth = 5;

/// Un dossier de rangement des recettes, propre au compte et imbricable.
///
/// `icon` est un emoji système optionnel (null = icône dossier par défaut à
/// l'affichage). `parentCategoryId` null = dossier racine. Les 4 dossiers
/// `isDefault` (Entrée/Plat/Dessert/Boisson) ne sont ni renommables ni
/// supprimables.
class Category extends Equatable {
  const Category({
    required this.id,
    required this.name,
    this.icon,
    this.parentCategoryId,
    this.depth = 1,
    this.isDefault = false,
    this.recipeCount = 0,
  });

  final String id;
  final String name;
  final String? icon;
  final String? parentCategoryId;
  final int depth;
  final bool isDefault;

  /// Nombre de recettes rangées dans ce dossier (0 tant que le pivot
  /// recipe_categories n'est pas branché côté serveur).
  final int recipeCount;

  bool get isRoot => parentCategoryId == null;

  /// Vrai si ce dossier peut encore accueillir des sous-dossiers (profondeur).
  bool get canHaveChildren => depth < kCategoryMaxDepth;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String?,
      parentCategoryId: json['parentCategoryId'] as String?,
      depth: json['depth'] as int? ?? 1,
      isDefault: json['isDefault'] as bool? ?? false,
      recipeCount: json['recipeCount'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        icon,
        parentCategoryId,
        depth,
        isDefault,
        recipeCount,
      ];
}
