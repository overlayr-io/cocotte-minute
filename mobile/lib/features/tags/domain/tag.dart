import 'package:equatable/equatable.dart';

/// Un tag qualifiant recettes, sous-recettes et personnes — système (catalogue
/// de base) ou copie utilisateur, même mécanique que les ingrédients.
///
/// `color` est un code hex `#RRGGBB` choisi dans une palette fermée (cf.
/// [TagColors]) — le tint clair des chips en est dérivé à l'affichage.
class Tag extends Equatable {
  const Tag({
    required this.id,
    required this.name,
    required this.color,
    this.recipeCount = 0,
    this.isSystem = false,
    this.importedFromId,
    this.alreadyImported = false,
  });

  final String id;
  final String name;
  final String color;

  /// Nombre de recettes portant ce tag (0 tant que le pivot recipe_tags
  /// n'est pas branché côté serveur).
  final int recipeCount;

  /// true = tag du catalogue système (non modifiable/supprimable par l'utilisateur).
  final bool isSystem;

  /// Tag système d'origine si ce tag est une copie importée.
  final String? importedFromId;

  /// Uniquement pour le catalogue système : l'utilisateur possède-t-il déjà une
  /// copie importée de ce tag ?
  final bool alreadyImported;

  bool get isImported => importedFromId != null;

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
      recipeCount: json['recipeCount'] as int? ?? 0,
      isSystem: json['isSystem'] as bool? ?? false,
      importedFromId: json['importedFromId'] as String?,
      alreadyImported: json['alreadyImported'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    color,
    recipeCount,
    isSystem,
    importedFromId,
    alreadyImported,
  ];
}
