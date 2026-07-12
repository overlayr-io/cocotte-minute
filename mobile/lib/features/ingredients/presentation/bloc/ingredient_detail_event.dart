part of 'ingredient_detail_bloc.dart';

sealed class IngredientDetailEvent extends Equatable {
  const IngredientDetailEvent();

  @override
  List<Object?> get props => const [];
}

class IngredientDetailRequested extends IngredientDetailEvent {
  const IngredientDetailRequested(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

/// Enregistre le nom / l'unité / le visuel (emoji OU image) de l'ingrédient,
/// et son prix si le bloc prix a été affiché. [emoji] et [imageUrl] sont
/// envoyés explicitement (null = vidé).
///
/// [savePrice] : true dès que le bloc prix a été affiché (déjà rempli, ou
/// "Ajouter un prix" tapé cette session) — évite de créer une ligne de prix
/// vide si l'utilisateur n'y a jamais touché. [lowPrice]/[highPrice] non nuls
/// ensemble = palier premium (envoyés au serveur) ; sinon seul [averagePrice]
/// est envoyé (gratuit, ou premium désabonné) — les bas/haut déjà enregistrés
/// côté serveur restent alors intacts (conservés mais masqués, cf. doc).
class IngredientDetailSaveRequested extends IngredientDetailEvent {
  const IngredientDetailSaveRequested({
    required this.name,
    required this.unit,
    this.imageUrl,
    this.emoji,
    this.savePrice = false,
    this.priceReferenceUnit,
    this.averagePrice,
    this.lowPrice,
    this.highPrice,
  });

  final String name;
  final IngredientUnit unit;
  final String? imageUrl;
  final String? emoji;

  final bool savePrice;
  final PriceReferenceUnit? priceReferenceUnit;
  final double? averagePrice;
  final double? lowPrice;
  final double? highPrice;

  @override
  List<Object?> get props => [
    name,
    unit,
    imageUrl,
    emoji,
    savePrice,
    priceReferenceUnit,
    averagePrice,
    lowPrice,
    highPrice,
  ];
}

class IngredientAlternativeAdded extends IngredientDetailEvent {
  const IngredientAlternativeAdded(this.alternativeId);

  final String alternativeId;

  @override
  List<Object?> get props => [alternativeId];
}

class IngredientAlternativeRemoved extends IngredientDetailEvent {
  const IngredientAlternativeRemoved(this.alternativeId);

  final String alternativeId;

  @override
  List<Object?> get props => [alternativeId];
}

class IngredientDetailDeleteRequested extends IngredientDetailEvent {
  const IngredientDetailDeleteRequested();
}
