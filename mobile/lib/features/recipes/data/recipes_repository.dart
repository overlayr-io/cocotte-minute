import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/premium/premium_limit_error.dart';
import '../domain/recipe.dart';
import '../domain/recipe_sort.dart';

/// Erreur portant un message exploitable pour l'UI (snackbar/page d'erreur).
class RecipesRepositoryException implements Exception {
  const RecipesRepositoryException(this.message, {this.premiumLimit});

  final String message;

  /// Limite freemium (403 `PREMIUM_LIMIT_*`) : l'UI ouvre la feuille d'upsell
  /// au lieu d'afficher le message brut.
  final PremiumLimitError? premiumLimit;

  @override
  String toString() => 'RecipesRepositoryException($message)';
}

/// Sentinelle « champ non fourni » pour distinguer « ne pas toucher » de
/// « mettre à null » dans un PATCH partiel (prix étiquette / tranche de prix).
const Object _unset = Object();

/// Résultat d'un ajout de photo de galerie (feature galerie-recette). Si
/// [becameCover] est vrai, la photo est devenue la couverture de la recette (la
/// recette n'en avait pas) et n'entre PAS dans la galerie ; [coverUrl] porte
/// alors la nouvelle couverture. Sinon, [photos] reflète la galerie mise à jour.
class GalleryAddResult {
  const GalleryAddResult({
    required this.becameCover,
    required this.coverUrl,
    required this.photos,
  });

  final bool becameCover;
  final String? coverUrl;
  final List<RecipeGalleryPhoto> photos;

  factory GalleryAddResult.fromJson(Map<String, dynamic> json) {
    return GalleryAddResult(
      becameCover: json['becameCover'] as bool? ?? false,
      coverUrl: json['coverUrl'] as String?,
      photos: ((json['photos'] as List<dynamic>?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(RecipeGalleryPhoto.fromJson)
          .toList(),
    );
  }
}

/// Accès aux recettes via l'API NestJS.
class RecipesRepository {
  RecipesRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Dio get _dio => _apiClient.raw;

  /// Mes recettes. [q]/[limit]/[offset] optionnels pour la vue Liste paginée
  /// (filtre texte simple côté serveur) ; sans paramètre, tout est renvoyé.
  Future<List<RecipeSummary>> fetchMine({
    String? q,
    int? limit,
    int? offset,
    RecipeSort? sort,
  }) async {
    try {
      final res = await _dio.get<List<dynamic>>(
        '/recipes',
        queryParameters: {
          if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
          'limit': ?limit,
          'offset': ?offset,
          if (sort != null && sort != RecipeSort.recent) 'sort': sort.wire,
        },
      );
      return (res.data ?? const [])
          .cast<Map<String, dynamic>>()
          .map(RecipeSummary.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de charger tes recettes.');
    }
  }

  /// Recettes rangées dans un dossier (les plus récentes d'abord).
  Future<List<RecipeSummary>> fetchByCategory(String categoryId) async {
    try {
      final res =
          await _dio.get<List<dynamic>>('/categories/$categoryId/recipes');
      return (res.data ?? const [])
          .cast<Map<String, dynamic>>()
          .map(RecipeSummary.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de charger les recettes du dossier.');
    }
  }

  /// Recettes rangées dans aucun dossier (dossier virtuel « Autres »).
  Future<List<RecipeSummary>> fetchUncategorized() async {
    try {
      final res = await _dio.get<List<dynamic>>('/recipes/uncategorized');
      return (res.data ?? const [])
          .cast<Map<String, dynamic>>()
          .map(RecipeSummary.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de charger les recettes du dossier.');
    }
  }

  Future<RecipeDetail> fetchDetail(String id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/recipes/$id');
      return RecipeDetail.fromJson(res.data!);
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de charger la recette.');
    }
  }

  /// Génère (ou réutilise) un lien de partage public pour la recette et renvoie
  /// son URL (page web + universal/app link). Réservé au propriétaire côté serveur.
  Future<String> createShareLink(String id) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/recipes/$id/share');
      return res.data!['url'] as String;
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de générer le lien de partage.');
    }
  }

  /// Charge une recette partagée via son token public (route non authentifiée
  /// côté serveur). Utilisé à l'ouverture d'un lien de partage (deep link).
  Future<RecipeDetail> fetchByShareToken(String token) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/share/$token');
      return RecipeDetail.fromJson(res.data!);
    } on DioException catch (e) {
      throw _mapError(e, 'Ce lien de partage est introuvable ou expiré.');
    }
  }

  Future<RecipeSummary> create({
    required String name,
    String? photoUrl,
    bool isBase = false,
    required int servings,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/recipes',
        data: {
          'name': name,
          'photoUrl': ?photoUrl,
          'isBase': isBase,
          'servings': servings,
        },
      );
      return RecipeSummary.fromJson(res.data!);
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de créer la recette.');
    }
  }

  /// Duplique une recette (copie profonde côté serveur). Renvoie le résumé de
  /// la nouvelle recette.
  Future<RecipeSummary> duplicateRecipe(String recipeId) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/recipes/$recipeId/duplicate',
      );
      return RecipeSummary.fromJson(res.data!);
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de dupliquer la recette.');
    }
  }

  /// Recettes aimées « J'aime » (#15), plus récemment ajoutées d'abord.
  Future<List<RecipeSummary>> fetchFavorites() async {
    try {
      final res = await _dio.get<List<dynamic>>('/recipes/favorites');
      return (res.data ?? const [])
          .cast<Map<String, dynamic>>()
          .map(RecipeSummary.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de charger tes favoris.');
    }
  }

  /// Ajoute la recette aux favoris (idempotent). Peut porter un `premiumLimit`.
  Future<void> addFavorite(String recipeId) async {
    try {
      await _dio.post<void>('/recipes/$recipeId/favorite');
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible d\'ajouter aux favoris.');
    }
  }

  /// Retire la recette des favoris (idempotent).
  Future<void> removeFavorite(String recipeId) async {
    try {
      await _dio.delete<void>('/recipes/$recipeId/favorite');
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de retirer des favoris.');
    }
  }

  /// [priceBracket] utilise la sentinelle [_unset] par défaut : ne rien passer
  /// = tranche inchangée (la plupart des appels ne touchent pas au prix),
  /// passer `null` explicitement = effacée (prix devenu partiel/inconnu).
  Future<RecipeSummary> update(
    String id, {
    String? name,
    String? photoUrl,
    String? description,
    bool? isBase,
    int? prepTime,
    int? cookTime,
    int? restTime,
    int? servings,
    RecipePriceMode? priceMode,
    double? fixedPrice,
    Object? priceBracket = _unset,
    Object? caloriesPerServing = _unset,
    Object? proteinsPerServing = _unset,
    Object? carbsPerServing = _unset,
    Object? fatsPerServing = _unset,
  }) async {
    try {
      final data = <String, dynamic>{
        'name': ?name,
        'photoUrl': ?photoUrl,
        'description': ?description,
        'isBase': ?isBase,
        'prepTime': ?prepTime,
        'cookTime': ?cookTime,
        'restTime': ?restTime,
        'servings': ?servings,
        'priceMode': ?priceMode?.wire,
        'fixedPrice': ?fixedPrice,
      };
      if (!identical(priceBracket, _unset)) {
        data['priceBracket'] = (priceBracket as RecipePriceBracket?)?.wire;
      }
      // Nutrition (feature #8) : sentinelle `_unset` = champ non touché ; null
      // explicite = valeur effacée. Chaque champ est envoyé indépendamment.
      if (!identical(caloriesPerServing, _unset)) {
        data['caloriesPerServing'] = caloriesPerServing as double?;
      }
      if (!identical(proteinsPerServing, _unset)) {
        data['proteinsPerServing'] = proteinsPerServing as double?;
      }
      if (!identical(carbsPerServing, _unset)) {
        data['carbsPerServing'] = carbsPerServing as double?;
      }
      if (!identical(fatsPerServing, _unset)) {
        data['fatsPerServing'] = fatsPerServing as double?;
      }
      final res = await _dio.patch<Map<String, dynamic>>(
        '/recipes/$id',
        data: data,
      );
      return RecipeSummary.fromJson(res.data!);
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible d\'enregistrer les modifications.');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete<void>('/recipes/$id');
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de supprimer la recette.');
    }
  }

  // --- galerie (feature galerie-recette) ---------------------------------

  /// Ajoute une photo (déjà uploadée sur Storage) à la galerie d'une recette.
  /// L'URL vient de `ImageUploadService`. En cas de quota atteint, l'exception
  /// porte le `PremiumLimitError` (l'UI décide upsell vs message selon le tier).
  Future<GalleryAddResult> addGalleryPhoto(String recipeId, String imageUrl) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/recipes/$recipeId/gallery',
        data: {'imageUrl': imageUrl},
      );
      return GalleryAddResult.fromJson(res.data!);
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible d\'ajouter la photo.');
    }
  }

  /// Supprime une photo de galerie et renvoie la galerie mise à jour.
  Future<List<RecipeGalleryPhoto>> deleteGalleryPhoto(
    String recipeId,
    String imageId,
  ) async {
    try {
      final res = await _dio.delete<Map<String, dynamic>>(
        '/recipes/$recipeId/gallery/$imageId',
      );
      return ((res.data?['photos'] as List<dynamic>?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(RecipeGalleryPhoto.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de supprimer la photo.');
    }
  }

  /// Ajoute (ou met à jour la quantité d') un ingrédient sur la recette.
  Future<void> addIngredient(
    String recipeId,
    String ingredientId,
    double quantity,
  ) async {
    try {
      await _dio.post<void>(
        '/recipes/$recipeId/ingredients',
        data: {'ingredientId': ingredientId, 'quantity': quantity},
      );
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible d\'ajouter l\'ingrédient.');
    }
  }

  /// Met à jour la seule quantité d'un ingrédient déjà présent sur la recette.
  Future<void> updateIngredientQuantity(
    String recipeId,
    String ingredientId,
    double quantity,
  ) async {
    try {
      await _dio.patch<void>(
        '/recipes/$recipeId/ingredients/$ingredientId',
        data: {'quantity': quantity},
      );
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de modifier la quantité.');
    }
  }

  Future<void> removeIngredient(String recipeId, String ingredientId) async {
    try {
      await _dio.delete<void>('/recipes/$recipeId/ingredients/$ingredientId');
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de retirer l\'ingrédient.');
    }
  }

  // --- étapes ------------------------------------------------------------

  Future<void> addTextStep(
    String recipeId, {
    required String description,
    StepBanner? banner,
    List<String> ingredientIds = const [],
  }) async {
    try {
      await _dio.post<void>(
        '/recipes/$recipeId/steps',
        data: {
          'description': description,
          'bannerType': ?banner?.type.wire,
          'bannerText': ?banner?.text,
          'ingredientIds': ingredientIds,
        },
      );
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible d\'ajouter l\'étape.');
    }
  }

  Future<void> addBaseRefStep(String recipeId, String baseRecipeId) async {
    try {
      await _dio.post<void>(
        '/recipes/$recipeId/steps',
        data: {'baseRecipeRefId': baseRecipeId},
      );
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible d\'ajouter la sous-recette.');
    }
  }

  Future<void> importSteps(String recipeId, List<String> descriptions) async {
    try {
      await _dio.post<void>(
        '/recipes/$recipeId/steps/import',
        data: {'descriptions': descriptions},
      );
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible d\'importer les étapes.');
    }
  }

  /// Édite une étape texte. `banner == null` retire la bannière (null explicite).
  Future<void> updateStep(
    String recipeId,
    String stepId, {
    required String description,
    StepBanner? banner,
  }) async {
    try {
      await _dio.patch<void>(
        '/recipes/$recipeId/steps/$stepId',
        data: {
          'description': description,
          'bannerType': banner?.type.wire,
          'bannerText': banner?.text,
        },
      );
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible d\'enregistrer l\'étape.');
    }
  }

  Future<void> removeStep(String recipeId, String stepId) async {
    try {
      await _dio.delete<void>('/recipes/$recipeId/steps/$stepId');
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de supprimer l\'étape.');
    }
  }

  Future<void> reorderSteps(String recipeId, List<String> stepIds) async {
    try {
      await _dio.put<void>(
        '/recipes/$recipeId/steps/order',
        data: {'stepIds': stepIds},
      );
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de réordonner les étapes.');
    }
  }

  Future<void> reorderIngredients(
      String recipeId, List<String> ingredientIds) async {
    try {
      await _dio.put<void>(
        '/recipes/$recipeId/ingredients/order',
        data: {'ingredientIds': ingredientIds},
      );
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de réordonner les ingrédients.');
    }
  }

  Future<void> setStepIngredients(
    String recipeId,
    String stepId,
    List<String> ingredientIds,
  ) async {
    try {
      await _dio.put<void>(
        '/recipes/$recipeId/steps/$stepId/ingredients',
        data: {'ingredientIds': ingredientIds},
      );
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible d\'enregistrer les ingrédients de l\'étape.');
    }
  }

  // --- composants (sous-recettes) ---------------------------------------

  /// Ajoute une recette de base comme composant. Le serveur refuse une recette
  /// non « de base » ou créant un cycle (message FR remonté tel quel).
  Future<void> addComponent(String recipeId, String baseRecipeId) async {
    try {
      await _dio.post<void>(
        '/recipes/$recipeId/components',
        data: {'baseRecipeId': baseRecipeId},
      );
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible d\'ajouter la sous-recette.');
    }
  }

  Future<void> removeComponent(String recipeId, String baseRecipeId) async {
    try {
      await _dio.delete<void>('/recipes/$recipeId/components/$baseRecipeId');
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de retirer la sous-recette.');
    }
  }

  // --- rangement & étiquetage -------------------------------------------

  /// Range la recette dans un dossier (catégorie).
  Future<void> assignCategory(String recipeId, String categoryId) async {
    try {
      await _dio.post<void>(
        '/recipes/$recipeId/categories',
        data: {'categoryId': categoryId},
      );
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de ranger la recette.');
    }
  }

  Future<void> unassignCategory(String recipeId, String categoryId) async {
    try {
      await _dio.delete<void>('/recipes/$recipeId/categories/$categoryId');
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de retirer la recette du dossier.');
    }
  }

  /// Étiquette la recette avec un tag.
  Future<void> assignTag(String recipeId, String tagId) async {
    try {
      await _dio.post<void>(
        '/recipes/$recipeId/tags',
        data: {'tagId': tagId},
      );
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible d\'ajouter le tag.');
    }
  }

  Future<void> unassignTag(String recipeId, String tagId) async {
    try {
      await _dio.delete<void>('/recipes/$recipeId/tags/$tagId');
    } on DioException catch (e) {
      throw _mapError(e, 'Impossible de retirer le tag.');
    }
  }

  RecipesRepositoryException _mapError(DioException e, String fallback) {
    // 400/403/404/409 : le serveur renvoie un message FR actionnable (verrou
    // is_base, composant invalide, recette introuvable...), on le remonte tel quel.
    final status = e.response?.statusCode;
    if (status == 400 || status == 403 || status == 404 || status == 409) {
      final data = e.response?.data;
      // 403 structuré { code: PREMIUM_LIMIT_*, limit, current } : porté par
      // l'exception pour que l'UI ouvre l'upsell adapté.
      final premiumLimit = PremiumLimitError.fromResponseData(data);
      if (data is Map && data['message'] is String) {
        return RecipesRepositoryException(
          data['message'] as String,
          premiumLimit: premiumLimit,
        );
      }
      if (premiumLimit != null) {
        return RecipesRepositoryException(fallback, premiumLimit: premiumLimit);
      }
    }
    const connectivityErrors = {
      DioExceptionType.connectionError,
      DioExceptionType.connectionTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.sendTimeout,
    };
    if (connectivityErrors.contains(e.type)) {
      return const RecipesRepositoryException(
        'Serveur injoignable. Vérifie que l\'API tourne et que l\'URL est correcte.',
      );
    }
    return RecipesRepositoryException(fallback);
  }
}
