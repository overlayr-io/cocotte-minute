import 'package:equatable/equatable.dart';

/// Contribution d'une recette à un article agrégé (vue « par recette » + détail
/// du calcul « 20 g + 15 g + 10 g »).
class ShoppingItemSource extends Equatable {
  const ShoppingItemSource({required this.recipeId, required this.quantity});

  final String recipeId;
  final double quantity;

  factory ShoppingItemSource.fromJson(Map<String, dynamic> json) =>
      ShoppingItemSource(
        recipeId: json['recipeId'] as String,
        quantity: (json['quantity'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {'recipeId': recipeId, 'quantity': quantity};

  @override
  List<Object?> get props => [recipeId, quantity];
}

/// Un article de la liste (ligne agrégée par ingrédient, ou article libre).
class ShoppingListItem extends Equatable {
  const ShoppingListItem({
    required this.id,
    this.ingredientId,
    this.customLabel,
    required this.name,
    this.quantity,
    this.unit,
    this.isChecked = false,
    this.replacedByAlternativeId,
    this.replacementName,
    this.sources = const [],
    this.position = 0,
    required this.clientUpdatedAt,
  });

  final String id;
  final String? ingredientId;
  final String? customLabel;
  final String name;
  final double? quantity;
  final String? unit;
  final bool isChecked;
  final String? replacedByAlternativeId;
  final String? replacementName;
  final List<ShoppingItemSource> sources;
  final int position;
  final DateTime clientUpdatedAt;

  /// Article ajouté à la main (hors recette).
  bool get isFree => ingredientId == null;

  /// Un remplacement par alternative est appliqué (affichage seulement).
  bool get isReplaced => replacedByAlternativeId != null;

  /// Nom à afficher : l'alternative choisie prime sur l'ingrédient d'origine.
  String get displayName => replacementName ?? name;

  factory ShoppingListItem.fromJson(Map<String, dynamic> json) =>
      ShoppingListItem(
        id: json['id'] as String,
        ingredientId: json['ingredientId'] as String?,
        customLabel: json['customLabel'] as String?,
        name: json['name'] as String,
        quantity: (json['quantity'] as num?)?.toDouble(),
        unit: json['unit'] as String?,
        isChecked: json['isChecked'] as bool? ?? false,
        replacedByAlternativeId: json['replacedByAlternativeId'] as String?,
        replacementName: json['replacementName'] as String?,
        sources: (json['sources'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>()
            .map(ShoppingItemSource.fromJson)
            .toList(),
        position: json['position'] as int? ?? 0,
        clientUpdatedAt: DateTime.parse(json['clientUpdatedAt'] as String),
      );

  @override
  List<Object?> get props => [
    id,
    ingredientId,
    customLabel,
    name,
    quantity,
    unit,
    isChecked,
    replacedByAlternativeId,
    replacementName,
    sources,
    position,
    clientUpdatedAt,
  ];
}

/// Recette source d'une liste (snapshot pour la vue « par recette »).
class ShoppingRecipe extends Equatable {
  const ShoppingRecipe({
    required this.recipeId,
    required this.recipeName,
    this.photoUrl,
    required this.servings,
  });

  final String recipeId;
  final String recipeName;
  final String? photoUrl;
  final int servings;

  factory ShoppingRecipe.fromJson(Map<String, dynamic> json) => ShoppingRecipe(
    recipeId: json['recipeId'] as String,
    recipeName: json['recipeName'] as String,
    photoUrl: json['photoUrl'] as String?,
    servings: json['servings'] as int,
  );

  @override
  List<Object?> get props => [recipeId, recipeName, photoUrl, servings];
}

/// Résumé d'une liste (écran 5a / carte de liste active).
class ShoppingList extends Equatable {
  const ShoppingList({
    required this.id,
    required this.name,
    this.isArchived = false,
    this.itemCount = 0,
    this.checkedCount = 0,
    this.recipeCount = 0,
    required this.clientUpdatedAt,
    required this.createdAt,
  });

  final String id;
  final String name;
  final bool isArchived;
  final int itemCount;
  final int checkedCount;
  final int recipeCount;
  final DateTime clientUpdatedAt;
  final DateTime createdAt;

  /// Progression des courses (cochés / total), entre 0 et 1.
  double get progress => itemCount == 0 ? 0 : checkedCount / itemCount;

  factory ShoppingList.fromJson(Map<String, dynamic> json) => ShoppingList(
    id: json['id'] as String,
    name: json['name'] as String,
    isArchived: json['isArchived'] as bool? ?? false,
    itemCount: json['itemCount'] as int? ?? 0,
    checkedCount: json['checkedCount'] as int? ?? 0,
    recipeCount: json['recipeCount'] as int? ?? 0,
    clientUpdatedAt: DateTime.parse(json['clientUpdatedAt'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  @override
  List<Object?> get props => [
    id,
    name,
    isArchived,
    itemCount,
    checkedCount,
    recipeCount,
    clientUpdatedAt,
    createdAt,
  ];
}

/// Détail complet d'une liste : résumé + articles + recettes sources.
class ShoppingListDetail extends Equatable {
  const ShoppingListDetail({
    required this.list,
    required this.items,
    required this.recipes,
  });

  final ShoppingList list;
  final List<ShoppingListItem> items;
  final List<ShoppingRecipe> recipes;

  factory ShoppingListDetail.fromJson(Map<String, dynamic> json) =>
      ShoppingListDetail(
        list: ShoppingList.fromJson(json),
        items: (json['items'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>()
            .map(ShoppingListItem.fromJson)
            .toList(),
        recipes: (json['recipes'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>()
            .map(ShoppingRecipe.fromJson)
            .toList(),
      );

  @override
  List<Object?> get props => [list, items, recipes];
}
