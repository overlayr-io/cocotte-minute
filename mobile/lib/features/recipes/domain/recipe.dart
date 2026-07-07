import 'package:equatable/equatable.dart';

/// Nombre de personnes par défaut à la création (aligné `DEFAULT_SERVINGS` serveur).
const int kDefaultServings = 1;

/// Résumé d'une recette : ce qu'affichent la liste et les cartes (sans les
/// relations lourdes). `isBase` distingue une recette « de base » (réutilisable
/// comme composant) d'une recette normale.
class RecipeSummary extends Equatable {
  const RecipeSummary({
    required this.id,
    required this.name,
    this.photoUrl,
    this.isBase = false,
    this.prepTime = 0,
    this.cookTime = 0,
    this.restTime = 0,
    this.servings = kDefaultServings,
  });

  final String id;
  final String name;
  final String? photoUrl;
  final bool isBase;

  /// Temps en minutes.
  final int prepTime;
  final int cookTime;
  final int restTime;
  final int servings;

  factory RecipeSummary.fromJson(Map<String, dynamic> json) {
    return RecipeSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      photoUrl: json['photoUrl'] as String?,
      isBase: json['isBase'] as bool? ?? false,
      prepTime: json['prepTime'] as int? ?? 0,
      cookTime: json['cookTime'] as int? ?? 0,
      restTime: json['restTime'] as int? ?? 0,
      servings: json['servings'] as int? ?? kDefaultServings,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, photoUrl, isBase, prepTime, cookTime, restTime, servings];
}

/// Ligne d'ingrédient telle qu'affichée sur la fiche (nom + unité lue depuis
/// l'ingrédient ; pas de quantité en v1).
class RecipeIngredientLine extends Equatable {
  const RecipeIngredientLine({
    required this.id,
    required this.name,
    required this.unit,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String unit;
  final String? imageUrl;

  factory RecipeIngredientLine.fromJson(Map<String, dynamic> json) {
    return RecipeIngredientLine(
      id: json['id'] as String,
      name: json['name'] as String,
      unit: json['unit'] as String,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, name, unit, imageUrl];
}

/// Fiche détail complète d'une recette. La même page sert une recette normale et
/// une recette de base ; certaines sections ne s'affichent que dans l'un des cas
/// (« Sous-recettes utilisées » côté normale, « Utilisée dans » côté base).
class RecipeDetail extends Equatable {
  const RecipeDetail({
    required this.summary,
    required this.authorId,
    this.description,
    this.isLocked = false,
    this.ingredients = const [],
    this.components = const [],
    this.usedIn = const [],
    this.categoryIds = const [],
    this.tagIds = const [],
  });

  final RecipeSummary summary;
  final String authorId;
  final String? description;

  /// Recette de base utilisée comme composant ailleurs → `isBase` verrouillé
  /// (impossible de la repasser en recette normale).
  final bool isLocked;

  final List<RecipeIngredientLine> ingredients;

  /// Sous-recettes (recettes de base) utilisées par cette recette.
  final List<RecipeSummary> components;

  /// Recettes qui utilisent cette recette comme composant (rempli si `isBase`).
  final List<RecipeSummary> usedIn;

  final List<String> categoryIds;
  final List<String> tagIds;

  String get id => summary.id;
  String get name => summary.name;
  bool get isBase => summary.isBase;

  factory RecipeDetail.fromJson(Map<String, dynamic> json) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) parse) =>
        ((json[key] as List<dynamic>?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(parse)
            .toList();

    return RecipeDetail(
      summary: RecipeSummary.fromJson(json),
      authorId: json['authorId'] as String,
      description: json['description'] as String?,
      isLocked: json['isLocked'] as bool? ?? false,
      ingredients: list('ingredients', RecipeIngredientLine.fromJson),
      components: list('components', RecipeSummary.fromJson),
      usedIn: list('usedIn', RecipeSummary.fromJson),
      categoryIds:
          ((json['categoryIds'] as List<dynamic>?) ?? const []).cast<String>(),
      tagIds: ((json['tagIds'] as List<dynamic>?) ?? const []).cast<String>(),
    );
  }

  @override
  List<Object?> get props => [
        summary,
        authorId,
        description,
        isLocked,
        ingredients,
        components,
        usedIn,
        categoryIds,
        tagIds,
      ];
}
