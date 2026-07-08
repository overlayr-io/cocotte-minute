import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/shopping_list_repository.dart';
import '../../domain/shopping_list.dart';

/// Mode d'affichage des articles (5e).
enum ShoppingView { byRecipe, byAisle, az }

sealed class ShoppingListDetailState extends Equatable {
  const ShoppingListDetailState();
  @override
  List<Object?> get props => const [];
}

class ShoppingListDetailLoading extends ShoppingListDetailState {
  const ShoppingListDetailLoading();
}

/// La liste n'existe plus (vidée ici ou ailleurs) — l'écran doit se refermer.
class ShoppingListDetailGone extends ShoppingListDetailState {
  const ShoppingListDetailGone();
}

class ShoppingListDetailLoaded extends ShoppingListDetailState {
  const ShoppingListDetailLoaded(this.detail, this.view);
  final ShoppingListDetail detail;
  final ShoppingView view;

  @override
  List<Object?> get props => [detail, view];
}

/// Détail d'une liste (5e) : lecture réactive locale + actions offline-first.
class ShoppingListCubit extends Cubit<ShoppingListDetailState> {
  ShoppingListCubit({
    required ShoppingListRepository repository,
    required this.listId,
  }) : _repository = repository,
       super(const ShoppingListDetailLoading()) {
    _sub = _repository.watchDetail(listId).listen((detail) {
      if (detail == null) {
        emit(const ShoppingListDetailGone());
      } else {
        emit(ShoppingListDetailLoaded(detail, _view));
      }
    });
  }

  final ShoppingListRepository _repository;
  final String listId;
  StreamSubscription<ShoppingListDetail?>? _sub;
  ShoppingView _view = ShoppingView.byRecipe;

  void setView(ShoppingView view) {
    _view = view;
    final s = state;
    if (s is ShoppingListDetailLoaded) {
      emit(ShoppingListDetailLoaded(s.detail, view));
    }
  }

  Future<void> setChecked(String itemId, bool checked) =>
      _repository.setChecked(itemId, checked);

  Future<void> setAlternative(
    String itemId, {
    required String? alternativeId,
    required String? alternativeName,
  }) => _repository.setAlternative(
    itemId,
    alternativeId: alternativeId,
    alternativeName: alternativeName,
  );

  Future<void> addFreeItem(String label, {double? quantity, String? unit}) =>
      _repository.addFreeItem(listId, label: label, quantity: quantity, unit: unit);

  Future<void> removeItem(String itemId) => _repository.removeItem(itemId);

  Future<void> rename(String name) => _repository.rename(listId, name);

  Future<void> clear() => _repository.clear(listId);

  Future<void> clearChecked() => _repository.clearChecked(listId);

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
