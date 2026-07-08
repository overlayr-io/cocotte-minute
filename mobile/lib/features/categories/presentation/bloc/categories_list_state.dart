part of 'categories_list_bloc.dart';

sealed class CategoriesListState extends Equatable {
  const CategoriesListState();

  @override
  List<Object?> get props => const [];
}

class CategoriesListInitial extends CategoriesListState {
  const CategoriesListInitial();
}

class CategoriesListLoading extends CategoriesListState {
  const CategoriesListLoading();
}

/// Arborescence à plat chargée. `busyId` = dossier en cours d'action
/// (édition/suppression). Les pages filtrent par parent via [childrenOf].
class CategoriesListLoaded extends CategoriesListState {
  const CategoriesListLoaded({required this.categories, this.busyId});

  final List<Category> categories;
  final String? busyId;

  /// Sous-dossiers directs d'un parent (null = dossiers racines), triés comme
  /// renvoyés par l'API (défauts d'abord, puis ordre de création).
  List<Category> childrenOf(String? parentId) => categories
      .where((c) => c.parentCategoryId == parentId)
      .toList(growable: false);

  /// Dossier par identifiant, ou null s'il n'existe plus (ex: après suppression).
  Category? byId(String id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  CategoriesListLoaded copyWith({List<Category>? categories, String? busyId}) {
    return CategoriesListLoaded(
      categories: categories ?? this.categories,
      busyId: busyId,
    );
  }

  @override
  List<Object?> get props => [categories, busyId];
}

/// Échec transitoire d'une action : l'arborescence reste affichée, un message
/// est remonté pour une snackbar.
class CategoriesListActionFailure extends CategoriesListLoaded {
  const CategoriesListActionFailure({
    required super.categories,
    required this.message,
  });

  final String message;

  @override
  List<Object?> get props => [categories, message];
}

/// Échec bloquant du chargement initial → page d'erreur + retry.
class CategoriesListError extends CategoriesListState {
  const CategoriesListError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
