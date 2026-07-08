part of 'categories_list_bloc.dart';

sealed class CategoriesListEvent extends Equatable {
  const CategoriesListEvent();

  @override
  List<Object?> get props => const [];
}

/// Charge (ou recharge) toute l'arborescence des dossiers du compte.
class CategoriesRequested extends CategoriesListEvent {
  const CategoriesRequested();
}

/// Création d'un dossier (racine si `parentCategoryId` est null).
class CategoryCreated extends CategoriesListEvent {
  const CategoryCreated({
    required this.name,
    this.icon,
    this.parentCategoryId,
  });

  final String name;
  final String? icon;
  final String? parentCategoryId;

  @override
  List<Object?> get props => [name, icon, parentCategoryId];
}

/// Édition d'un dossier (renommer / changer l'emoji). Le parent n'est pas
/// modifiable (pas de déplacement en v1).
class CategoryUpdated extends CategoriesListEvent {
  const CategoryUpdated({required this.id, this.name, this.icon});

  final String id;
  final String? name;
  final String? icon;

  @override
  List<Object?> get props => [id, name, icon];
}

/// Soft-delete d'un dossier (refusé si par défaut, bloqué si non vide côté API).
class CategoryDeleted extends CategoriesListEvent {
  const CategoryDeleted(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
