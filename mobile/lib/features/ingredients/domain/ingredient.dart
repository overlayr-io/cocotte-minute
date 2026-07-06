import 'package:equatable/equatable.dart';

/// Unité de mesure d'un ingrédient. La valeur `wire` est l'identifiant stable
/// échangé avec l'API (jamais le libellé i18n, résolu côté UI).
enum IngredientUnit {
  gramme('gramme'),
  milligramme('milligramme'),
  piece('piece'),
  cuillereCafe('cuillere_cafe'),
  cuillereSoupe('cuillere_soupe');

  const IngredientUnit(this.wire);

  final String wire;

  static IngredientUnit fromWire(String value) {
    return IngredientUnit.values.firstWhere(
      (u) => u.wire == value,
      orElse: () => IngredientUnit.gramme,
    );
  }
}

/// Un ingrédient — système (catalogue de base) ou copie utilisateur.
class Ingredient extends Equatable {
  const Ingredient({
    required this.id,
    required this.name,
    required this.unit,
    required this.isSystem,
    this.imageUrl,
    this.importedFromId,
    this.alreadyImported = false,
  });

  final String id;
  final String name;
  final IngredientUnit unit;
  final bool isSystem;
  final String? imageUrl;

  /// Ingrédient système d'origine si cette copie a été importée.
  final String? importedFromId;

  /// Uniquement pour le catalogue système : l'utilisateur possède-t-il déjà une
  /// copie importée de cet ingrédient ?
  final bool alreadyImported;

  bool get isImported => importedFromId != null;

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'] as String,
      name: json['name'] as String,
      unit: IngredientUnit.fromWire(json['unit'] as String),
      isSystem: json['isSystem'] as bool? ?? false,
      imageUrl: json['imageUrl'] as String?,
      importedFromId: json['importedFromId'] as String?,
      alreadyImported: json['alreadyImported'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    unit,
    isSystem,
    imageUrl,
    importedFromId,
    alreadyImported,
  ];
}

/// Détail d'un ingrédient utilisateur, alternatives incluses.
class IngredientDetail extends Equatable {
  const IngredientDetail({required this.ingredient, required this.alternatives});

  final Ingredient ingredient;
  final List<Ingredient> alternatives;

  factory IngredientDetail.fromJson(Map<String, dynamic> json) {
    final alternatives = (json['alternatives'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(Ingredient.fromJson)
        .toList();
    return IngredientDetail(
      ingredient: Ingredient.fromJson(json),
      alternatives: alternatives,
    );
  }

  @override
  List<Object?> get props => [ingredient, alternatives];
}
