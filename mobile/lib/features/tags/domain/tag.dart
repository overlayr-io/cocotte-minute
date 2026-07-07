import 'package:equatable/equatable.dart';

/// Un tag qualifiant recettes, sous-recettes et personnes. Propre au compte.
///
/// `color` est un code hex `#RRGGBB` choisi dans une palette fermée (cf.
/// [TagColors]) — le tint clair des chips en est dérivé à l'affichage.
class Tag extends Equatable {
  const Tag({
    required this.id,
    required this.name,
    required this.color,
    this.recipeCount = 0,
  });

  final String id;
  final String name;
  final String color;

  /// Nombre de recettes portant ce tag (0 tant que le pivot recipe_tags
  /// n'est pas branché côté serveur).
  final int recipeCount;

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
      recipeCount: json['recipeCount'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, name, color, recipeCount];
}
