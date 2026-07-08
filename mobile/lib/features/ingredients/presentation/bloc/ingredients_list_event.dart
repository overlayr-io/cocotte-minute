part of 'ingredients_list_bloc.dart';

sealed class IngredientsListEvent extends Equatable {
  const IngredientsListEvent();

  @override
  List<Object?> get props => const [];
}

/// Charge (ou recharge) les deux listes : mes ingrédients + catalogue système.
class IngredientsRequested extends IngredientsListEvent {
  const IngredientsRequested();
}

/// Importe un ingrédient système → copie personnelle.
class IngredientSystemImported extends IngredientsListEvent {
  const IngredientSystemImported(this.systemId);

  final String systemId;

  @override
  List<Object?> get props => [systemId];
}

/// Soft-delete d'un de mes ingrédients.
class IngredientDeleted extends IngredientsListEvent {
  const IngredientDeleted(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

/// Création d'un ingrédient custom (emoji et image exclusifs).
class IngredientCreated extends IngredientsListEvent {
  const IngredientCreated({
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
