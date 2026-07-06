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

/// Enregistre le nom / l'unité / l'image de l'ingrédient.
class IngredientDetailSaveRequested extends IngredientDetailEvent {
  const IngredientDetailSaveRequested({
    required this.name,
    required this.unit,
    this.imageUrl,
  });

  final String name;
  final IngredientUnit unit;
  final String? imageUrl;

  @override
  List<Object?> get props => [name, unit, imageUrl];
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
