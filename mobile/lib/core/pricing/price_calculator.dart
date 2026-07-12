import 'package:equatable/equatable.dart';

import '../../features/ingredient_prices/domain/ingredient_price.dart';
import '../../features/ingredients/domain/ingredient.dart';

/// Constantes de conversion volumique → poids pour les cuillères (feature
/// prix-estime) : équivalence conventionnelle française (5 mL / 15 mL, densité
/// eau ≈ 1 g/mL) — usage courant, pas une norme AFNOR. Imprécision assumée.
const double kTeaspoonGrams = 5;
const double kTablespoonGrams = 15;

/// Unité de référence déduite de l'unité de mesure d'un ingrédient — valeur de
/// départ proposée à l'utilisateur (première saisie), qui reste libre de la
/// changer ensuite (chips Kilogramme/Pièce toujours actives).
PriceReferenceUnit deduceReferenceUnit(IngredientUnit quantityUnit) {
  return quantityUnit == IngredientUnit.piece
      ? PriceReferenceUnit.piece
      : PriceReferenceUnit.kilogram;
}

/// Convertit une quantité (exprimée dans l'unité de mesure d'un ingrédient)
/// vers l'unité de référence d'un prix. Renvoie `null` si la combinaison n'est
/// pas convertible (ex: pièce → kilogram, sans donnée de densité disponible) —
/// le prix est alors exclu du calcul plutôt que de produire une valeur fausse.
double? convertQuantityToReferenceUnit({
  required double quantity,
  required IngredientUnit quantityUnit,
  required PriceReferenceUnit referenceUnit,
}) {
  switch (referenceUnit) {
    case PriceReferenceUnit.kilogram:
      final grams = switch (quantityUnit) {
        IngredientUnit.gramme => quantity,
        IngredientUnit.milligramme => quantity / 1000,
        IngredientUnit.cuillereCafe => quantity * kTeaspoonGrams,
        IngredientUnit.cuillereSoupe => quantity * kTablespoonGrams,
        IngredientUnit.piece => null,
      };
      return grams == null ? null : grams / 1000;
    case PriceReferenceUnit.piece:
      return quantityUnit == IngredientUnit.piece ? quantity : null;
    case PriceReferenceUnit.litre:
      return null; // Inatteignable en v1 : aucune unité de quantité "volume".
  }
}

/// Coût d'une ligne (quantité × prix moyen, converti dans l'unité de
/// référence). `null` si le prix est inconnu ou la combinaison d'unités
/// inconvertible — traité partout comme "prix non renseigné", jamais une erreur.
double? ingredientLinePrice({
  required double quantity,
  required IngredientUnit quantityUnit,
  required IngredientPrice? price,
}) {
  final average = price?.averagePrice;
  if (price == null || average == null) return null;
  final converted = convertQuantityToReferenceUnit(
    quantity: quantity,
    quantityUnit: quantityUnit,
    referenceUnit: price.priceReferenceUnit,
  );
  return converted == null ? null : converted * average;
}

/// Estimation de prix agrégée (recette ou liste de courses) : [value] est la
/// somme des lignes connues, [knownCount]/[totalCount] permettent à chaque
/// écran de choisir son traitement — "≈" + avertissement dès qu'une ligne
/// manque ([isPartial]), état neutre "prix inconnu" si aucune n'est connue
/// ([isFullyUnknown]).
class PriceEstimate extends Equatable {
  const PriceEstimate({
    required this.value,
    required this.knownCount,
    required this.totalCount,
  });

  static const PriceEstimate empty = PriceEstimate(
    value: 0,
    knownCount: 0,
    totalCount: 0,
  );

  final double value;
  final int knownCount;
  final int totalCount;

  bool get isPartial => knownCount < totalCount;

  bool get isFullyUnknown => knownCount == 0 && totalCount > 0;

  PriceEstimate operator +(PriceEstimate other) => PriceEstimate(
    value: value + other.value,
    knownCount: knownCount + other.knownCount,
    totalCount: totalCount + other.totalCount,
  );

  @override
  List<Object?> get props => [value, knownCount, totalCount];
}

/// Agrège une liste de lignes (quantité + unité + ingrédient) en [PriceEstimate],
/// à partir des prix connus de l'utilisateur (cache `IngredientPricesRepository`).
PriceEstimate estimateFromLines(
  Iterable<({double quantity, IngredientUnit unit, String ingredientId})> lines,
  Map<String, IngredientPrice> pricesByIngredientId,
) {
  var value = 0.0;
  var known = 0;
  var total = 0;
  for (final line in lines) {
    total++;
    final price = ingredientLinePrice(
      quantity: line.quantity,
      quantityUnit: line.unit,
      price: pricesByIngredientId[line.ingredientId],
    );
    if (price != null) {
      value += price;
      known++;
    }
  }
  return PriceEstimate(value: value, knownCount: known, totalCount: total);
}

/// Prix affiché après mise à l'échelle par les portions choisies — même
/// formule que le scaling des quantités : prix affiché = prix base ×
/// portionsChoisies / servings.
double scalePrice(
  double basePrice, {
  required int servings,
  required int chosenServings,
}) {
  if (servings <= 0) return basePrice;
  return basePrice * chosenServings / servings;
}
