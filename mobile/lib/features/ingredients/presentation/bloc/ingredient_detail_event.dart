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

/// Enregistre le nom / l'unité / le visuel (emoji OU image) de l'ingrédient.
/// [emoji] et [imageUrl] sont envoyés explicitement (null = vidé).
class IngredientDetailSaveRequested extends IngredientDetailEvent {
  const IngredientDetailSaveRequested({
    required this.name,
    required this.unit,
    this.imageUrl,
    this.emoji,
  });

  final String name;
  final IngredientUnit unit;
  final String? imageUrl;
  final String? emoji;

  @override
  List<Object?> get props => [name, unit, imageUrl, emoji];
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
