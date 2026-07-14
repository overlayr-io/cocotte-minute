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

  /// Copie avec une nouvelle couverture (feature galerie-recette). [photoUrl]
  /// est toujours fourni non-null par les appelants (couverture posée/remplacée).
  RecipeSummary copyWith({String? photoUrl}) {
    return RecipeSummary(
      id: id,
      name: name,
      photoUrl: photoUrl ?? this.photoUrl,
      isBase: isBase,
      prepTime: prepTime,
      cookTime: cookTime,
      restTime: restTime,
      servings: servings,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, photoUrl, isBase, prepTime, cookTime, restTime, servings];
}

/// Ligne d'ingrédient telle qu'affichée sur la fiche : nom + unité (lue depuis
/// l'ingrédient) + quantité (pour `servings` personnes ; la mise à l'échelle par
/// portions est un calcul d'affichage côté client, jamais persisté).
class RecipeIngredientLine extends Equatable {
  const RecipeIngredientLine({
    required this.id,
    required this.name,
    required this.unit,
    required this.quantity,
    this.imageUrl,
    this.inherited = false,
  });

  final String id;
  final String name;

  /// Valeur `wire` de l'unité (cf. `IngredientUnit.fromWire`).
  final String unit;
  final double quantity;
  final String? imageUrl;

  /// true = ligne héritée d'une sous-recette de base (lecture seule : ni
  /// édition de quantité, ni réordonnancement dans la fiche).
  final bool inherited;

  factory RecipeIngredientLine.fromJson(Map<String, dynamic> json) {
    return RecipeIngredientLine(
      id: json['id'] as String,
      name: json['name'] as String,
      unit: json['unit'] as String,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
      imageUrl: json['imageUrl'] as String?,
      inherited: json['inherited'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, name, unit, quantity, imageUrl, inherited];
}

/// Une photo de galerie (feature galerie-recette) — une réalisation postée par
/// l'utilisateur après avoir cuisiné la recette. Distincte de la photo de
/// couverture (`summary.photoUrl`), jamais comptée dans le quota galerie.
class RecipeGalleryPhoto extends Equatable {
  const RecipeGalleryPhoto({
    required this.id,
    required this.imageUrl,
    required this.createdAt,
  });

  final String id;
  final String imageUrl;
  final DateTime createdAt;

  factory RecipeGalleryPhoto.fromJson(Map<String, dynamic> json) {
    return RecipeGalleryPhoto(
      id: json['id'] as String,
      imageUrl: json['imageUrl'] as String,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime(1970),
    );
  }

  @override
  List<Object?> get props => [id, imageUrl, createdAt];
}

/// Type de bannière d'une étape. `wire` = valeur stable échangée avec l'API ;
/// la couleur et l'icône sont dérivées côté UI.
enum StepBannerType {
  warning('warning'),
  info('info'),
  danger('danger'),
  learn('learn');

  const StepBannerType(this.wire);

  final String wire;

  static StepBannerType fromWire(String value) => StepBannerType.values.firstWhere(
        (t) => t.wire == value,
        orElse: () => StepBannerType.info,
      );
}

/// Bannière d'une étape : un préréglage + un texte court.
class StepBanner extends Equatable {
  const StepBanner({required this.type, required this.text});

  final StepBannerType type;
  final String text;

  factory StepBanner.fromJson(Map<String, dynamic> json) => StepBanner(
        type: StepBannerType.fromWire(json['type'] as String),
        text: json['text'] as String? ?? '',
      );

  @override
  List<Object?> get props => [type, text];
}

/// Étape « figée » affichée dans un bloc référence de base (lecture seule).
class ExpandedStep extends Equatable {
  const ExpandedStep({required this.description, this.banner});

  final String description;
  final StepBanner? banner;

  factory ExpandedStep.fromJson(Map<String, dynamic> json) => ExpandedStep(
        description: json['description'] as String? ?? '',
        banner: json['banner'] == null
            ? null
            : StepBanner.fromJson(json['banner'] as Map<String, dynamic>),
      );

  @override
  List<Object?> get props => [description, banner];
}

/// Une étape de recette : soit une étape texte (éditable, réordonnable), soit
/// un bloc référence de base (ses étapes sont dépliées, figées).
sealed class RecipeStep extends Equatable {
  const RecipeStep();

  String get id;

  factory RecipeStep.fromJson(Map<String, dynamic> json) {
    return json['kind'] == 'base_ref'
        ? RecipeBaseRefStep.fromJson(json)
        : RecipeTextStep.fromJson(json);
  }
}

class RecipeTextStep extends RecipeStep {
  const RecipeTextStep({
    required this.id,
    required this.description,
    this.banner,
    this.ingredients = const [],
  });

  @override
  final String id;
  final String description;
  final StepBanner? banner;
  final List<RecipeIngredientLine> ingredients;

  factory RecipeTextStep.fromJson(Map<String, dynamic> json) => RecipeTextStep(
        id: json['id'] as String,
        description: json['description'] as String? ?? '',
        banner: json['banner'] == null
            ? null
            : StepBanner.fromJson(json['banner'] as Map<String, dynamic>),
        ingredients: ((json['ingredients'] as List<dynamic>?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(RecipeIngredientLine.fromJson)
            .toList(),
      );

  @override
  List<Object?> get props => [id, description, banner, ingredients];
}

class RecipeBaseRefStep extends RecipeStep {
  const RecipeBaseRefStep({
    required this.id,
    required this.baseRecipeId,
    required this.baseRecipeName,
    this.steps = const [],
  });

  @override
  final String id;
  final String baseRecipeId;
  final String baseRecipeName;

  /// Étapes de la recette de base, dépliées et figées.
  final List<ExpandedStep> steps;

  factory RecipeBaseRefStep.fromJson(Map<String, dynamic> json) => RecipeBaseRefStep(
        id: json['id'] as String,
        baseRecipeId: json['baseRecipeId'] as String,
        baseRecipeName: json['baseRecipeName'] as String? ?? '',
        steps: ((json['steps'] as List<dynamic>?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(ExpandedStep.fromJson)
            .toList(),
      );

  @override
  List<Object?> get props => [id, baseRecipeId, baseRecipeName, steps];
}

/// Mode de prix d'une recette (feature prix-estime) : `calculated` = somme des
/// prix moyens des ingrédients (défaut) ; `fixed` = prix étiquette saisi
/// manuellement, pour la base `servings` de la recette. Les deux modes scalent
/// ensuite de la même façon selon les portions affichées.
enum RecipePriceMode {
  calculated('calculated'),
  fixed('fixed');

  const RecipePriceMode(this.wire);

  final String wire;

  static RecipePriceMode fromWire(String value) => RecipePriceMode.values.firstWhere(
        (m) => m.wire == value,
        orElse: () => RecipePriceMode.calculated,
      );
}

/// Tranche de prix affichée en badge sur la recette (feature prix-estime) —
/// calculée et poussée par le client, jamais par le serveur. Absente tant que
/// le prix n'est pas entièrement connu (jamais posée sur un total partiel).
enum RecipePriceBracket {
  under5('under_5'),
  from5To10('from_5_to_10'),
  from10To20('from_10_to_20'),
  over20('over_20');

  const RecipePriceBracket(this.wire);

  final String wire;

  static RecipePriceBracket? fromWire(String? value) {
    for (final b in RecipePriceBracket.values) {
      if (b.wire == value) return b;
    }
    return null;
  }
}

/// Déduit la tranche de prix d'une recette à partir de son prix de base (pour
/// `servings` personnes, jamais un prix déjà scalé par les portions affichées).
RecipePriceBracket priceBracketForValue(double value) {
  if (value < 5) return RecipePriceBracket.under5;
  if (value < 10) return RecipePriceBracket.from5To10;
  if (value < 20) return RecipePriceBracket.from10To20;
  return RecipePriceBracket.over20;
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
    this.priceMode = RecipePriceMode.calculated,
    this.fixedPrice,
    this.priceBracket,
    this.ingredients = const [],
    this.steps = const [],
    this.components = const [],
    this.usedIn = const [],
    this.categoryIds = const [],
    this.tagIds = const [],
    this.galleryPhotos = const [],
  });

  final RecipeSummary summary;
  final String authorId;
  final String? description;

  /// Recette de base utilisée comme composant ailleurs → `isBase` verrouillé
  /// (impossible de la repasser en recette normale).
  final bool isLocked;

  final RecipePriceMode priceMode;

  /// Prix étiquette pour `servings` personnes — non-null seulement si
  /// `priceMode == RecipePriceMode.fixed`.
  final double? fixedPrice;
  final RecipePriceBracket? priceBracket;

  final List<RecipeIngredientLine> ingredients;

  /// Étapes (arbre déjà déplié : les blocs référence portent leurs sous-étapes).
  final List<RecipeStep> steps;

  /// Sous-recettes (recettes de base) utilisées par cette recette.
  final List<RecipeSummary> components;

  /// Recettes qui utilisent cette recette comme composant (rempli si `isBase`).
  final List<RecipeSummary> usedIn;

  final List<String> categoryIds;
  final List<String> tagIds;

  /// Photos de galerie (réalisations), les plus anciennes d'abord.
  final List<RecipeGalleryPhoto> galleryPhotos;

  String get id => summary.id;
  String get name => summary.name;
  bool get isBase => summary.isBase;

  /// Copie avec une nouvelle tranche de prix (feature prix-estime) — pas un
  /// `copyWith` générique : `priceBracket` doit pouvoir être explicitement
  /// remis à `null` (prix devenu partiel/inconnu), sans ambiguïté `??`.
  RecipeDetail copyWithPriceBracket(RecipePriceBracket? priceBracket) {
    return RecipeDetail(
      summary: summary,
      authorId: authorId,
      description: description,
      isLocked: isLocked,
      priceMode: priceMode,
      fixedPrice: fixedPrice,
      priceBracket: priceBracket,
      ingredients: ingredients,
      steps: steps,
      components: components,
      usedIn: usedIn,
      categoryIds: categoryIds,
      tagIds: tagIds,
      galleryPhotos: galleryPhotos,
    );
  }

  /// Copie avec une galerie mise à jour (feature galerie-recette), et
  /// éventuellement une nouvelle couverture ([coverPhotoUrl]) — utile quand le
  /// 1er upload devient la couverture, ou lors d'un « Changer la photo ». Les
  /// autres champs sont inchangés.
  RecipeDetail copyWithGallery({
    List<RecipeGalleryPhoto>? galleryPhotos,
    String? coverPhotoUrl,
  }) {
    return RecipeDetail(
      summary: coverPhotoUrl == null
          ? summary
          : summary.copyWith(photoUrl: coverPhotoUrl),
      authorId: authorId,
      description: description,
      isLocked: isLocked,
      priceMode: priceMode,
      fixedPrice: fixedPrice,
      priceBracket: priceBracket,
      ingredients: ingredients,
      steps: steps,
      components: components,
      usedIn: usedIn,
      categoryIds: categoryIds,
      tagIds: tagIds,
      galleryPhotos: galleryPhotos ?? this.galleryPhotos,
    );
  }

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
      priceMode: RecipePriceMode.fromWire(json['priceMode'] as String? ?? 'calculated'),
      fixedPrice: (json['fixedPrice'] as num?)?.toDouble(),
      priceBracket: RecipePriceBracket.fromWire(json['priceBracket'] as String?),
      ingredients: list('ingredients', RecipeIngredientLine.fromJson),
      steps: list('steps', RecipeStep.fromJson),
      components: list('components', RecipeSummary.fromJson),
      usedIn: list('usedIn', RecipeSummary.fromJson),
      categoryIds:
          ((json['categoryIds'] as List<dynamic>?) ?? const []).cast<String>(),
      tagIds: ((json['tagIds'] as List<dynamic>?) ?? const []).cast<String>(),
      galleryPhotos: list('galleryPhotos', RecipeGalleryPhoto.fromJson),
    );
  }

  @override
  List<Object?> get props => [
        summary,
        authorId,
        description,
        isLocked,
        priceMode,
        fixedPrice,
        priceBracket,
        ingredients,
        steps,
        components,
        usedIn,
        categoryIds,
        tagIds,
        galleryPhotos,
      ];
}
