import '../../recipes/domain/recipe.dart';

/// Recette enrichie pour la vue Découverte (flag « de saison » + pivots).
class DiscoveryRecipe {
  const DiscoveryRecipe({
    required this.summary,
    required this.seasonal,
    required this.tagIds,
    required this.categoryIds,
  });

  final RecipeSummary summary;
  final bool seasonal;
  final List<String> tagIds;
  final List<String> categoryIds;

  factory DiscoveryRecipe.fromJson(Map<String, dynamic> json) {
    return DiscoveryRecipe(
      summary: RecipeSummary.fromJson(json),
      seasonal: json['seasonal'] as bool? ?? false,
      tagIds: (json['tagIds'] as List<dynamic>?)?.cast<String>() ?? const [],
      categoryIds:
          (json['categoryIds'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }
}

/// Personne allégée pour composer une rangée « Pour {prénom} ».
class DiscoveryPerson {
  const DiscoveryPerson({
    required this.id,
    required this.firstName,
    required this.avatarUrl,
    required this.tagIds,
  });

  final String id;
  final String firstName;
  final String? avatarUrl;
  final List<String> tagIds;

  factory DiscoveryPerson.fromJson(Map<String, dynamic> json) {
    return DiscoveryPerson(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      tagIds: (json['tagIds'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }
}

/// Charge utile de la vue Découverte (GET /discovery/home).
class DiscoveryData {
  const DiscoveryData({
    required this.month,
    required this.recipes,
    required this.people,
  });

  /// Mois courant (1..12), pour le titre « De saison en {mois} ».
  final int month;
  final List<DiscoveryRecipe> recipes;
  final List<DiscoveryPerson> people;

  factory DiscoveryData.fromJson(Map<String, dynamic> json) {
    return DiscoveryData(
      month: json['month'] as int? ?? DateTime.now().month,
      recipes: (json['recipes'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(DiscoveryRecipe.fromJson)
          .toList(),
      people: (json['people'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(DiscoveryPerson.fromJson)
          .toList(),
    );
  }
}
