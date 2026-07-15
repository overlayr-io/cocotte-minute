import 'package:equatable/equatable.dart';

/// Limite freemium signalée par le serveur : réponse 403 structurée
/// `{ statusCode, timestamp, path, message, code, limit, current }` avec un
/// `code` `PREMIUM_LIMIT_*`. Portée (nullable) par les exceptions des
/// repositories pour que l'UI ouvre la feuille d'upsell adaptée au lieu d'un
/// message d'erreur brut.
class PremiumLimitError extends Equatable {
  const PremiumLimitError({
    required this.code,
    this.limit,
    this.current,
    this.message,
  });

  /// 5 recettes de base max en gratuit (POST /recipes, toggle is_base).
  static const String baseRecipes = 'PREMIUM_LIMIT_BASE_RECIPES';

  /// 1 seule liste de courses active en gratuit (génération).
  static const String shoppingLists = 'PREMIUM_LIMIT_SHOPPING_LISTS';

  /// 6 critères de recherche cumulés max en gratuit (GET /search/recipes).
  static const String searchCriteria = 'PREMIUM_LIMIT_SEARCH_CRITERIA';

  /// Photos de galerie par recette : 3 en gratuit, 6 en Pro (POST
  /// /recipes/:id/gallery). Contrairement aux autres, ce plafond existe même en
  /// Pro — l'UI n'affiche donc l'upsell qu'aux comptes gratuits.
  static const String galleryPhotos = 'PREMIUM_LIMIT_GALLERY_PHOTOS';

  /// 1 entrée max par créneau du planning en gratuit (POST /meal-plan/entries).
  static const String mealSlotEntries = 'PREMIUM_LIMIT_MEAL_SLOT_ENTRIES';

  /// Planning éditable sur T/T+1 uniquement en gratuit (au-delà : lecture seule).
  static const String mealPlanWeek = 'PREMIUM_LIMIT_MEAL_PLAN_WEEK';

  /// Photos « Mes produits » par ingrédient : 1 en gratuit, 3 en Pro (POST
  /// /ingredients/:id/photos). Plafond réel même en Pro.
  static const String ingredientPhotos = 'PREMIUM_LIMIT_INGREDIENT_PHOTOS';

  /// Parse le corps d'une réponse d'erreur serveur. Null si le corps ne porte
  /// pas un code `PREMIUM_LIMIT_*` (erreur classique).
  static PremiumLimitError? fromResponseData(Object? data) {
    if (data is! Map) return null;
    final code = data['code'];
    if (code is! String || !code.startsWith('PREMIUM_LIMIT_')) return null;
    return PremiumLimitError(
      code: code,
      limit: (data['limit'] as num?)?.toInt(),
      current: (data['current'] as num?)?.toInt(),
      message: data['message'] as String?,
    );
  }

  final String code;

  /// Plafond du plan gratuit (ex. 5), si transmis par le serveur.
  final int? limit;

  /// Valeur courante ayant déclenché la limite, si transmise.
  final int? current;

  /// Message FR serveur (secours) — préférer les clés i18n routées par [code].
  final String? message;

  @override
  List<Object?> get props => [code, limit, current, message];
}
