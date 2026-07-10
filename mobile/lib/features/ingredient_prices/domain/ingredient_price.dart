import 'package:equatable/equatable.dart';

/// Unité de référence du prix d'un ingrédient — indépendante de son unité de
/// mesure (feature prix-estime), librement modifiable par l'utilisateur.
/// `litre` est prévue mais inatteignable en v1 (aucune unité de quantité
/// "volume" côté ingrédients) — chip toujours désactivée côté UI.
enum PriceReferenceUnit {
  kilogram('kilogram'),
  litre('litre'),
  piece('piece');

  const PriceReferenceUnit(this.wire);

  final String wire;

  static PriceReferenceUnit fromWire(String value) {
    return PriceReferenceUnit.values.firstWhere(
      (u) => u.wire == value,
      orElse: () => PriceReferenceUnit.kilogram,
    );
  }
}

/// Prix d'un ingrédient — propre à l'utilisateur courant, même sur un
/// ingrédient système partagé (feature prix-estime). `lowPrice`/`highPrice`
/// réservés Premium (conservés mais masqués côté UI après désabonnement,
/// jamais perdus). `averagePrice` null = prix inconnu.
class IngredientPrice extends Equatable {
  const IngredientPrice({
    required this.ingredientId,
    required this.priceReferenceUnit,
    this.lowPrice,
    this.highPrice,
    this.averagePrice,
  });

  final String ingredientId;
  final PriceReferenceUnit priceReferenceUnit;
  final double? lowPrice;
  final double? highPrice;
  final double? averagePrice;

  factory IngredientPrice.fromJson(Map<String, dynamic> json) {
    return IngredientPrice(
      ingredientId: json['ingredientId'] as String,
      priceReferenceUnit: PriceReferenceUnit.fromWire(
        json['priceReferenceUnit'] as String,
      ),
      lowPrice: (json['lowPrice'] as num?)?.toDouble(),
      highPrice: (json['highPrice'] as num?)?.toDouble(),
      averagePrice: (json['averagePrice'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [
    ingredientId,
    priceReferenceUnit,
    lowPrice,
    highPrice,
    averagePrice,
  ];
}
