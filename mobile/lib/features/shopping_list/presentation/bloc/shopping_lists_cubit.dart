import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/shopping_list_repository.dart';
import '../../domain/shopping_list.dart';

/// État de l'onglet Courses (5a) : liste(s) active(s), depuis le cache local.
sealed class ShoppingListsState extends Equatable {
  const ShoppingListsState();
  @override
  List<Object?> get props => const [];
}

class ShoppingListsLoading extends ShoppingListsState {
  const ShoppingListsLoading();
}

class ShoppingListsLoaded extends ShoppingListsState {
  const ShoppingListsLoaded(this.lists);
  final List<ShoppingList> lists;

  /// En gratuit : au plus une liste active (la première).
  ShoppingList? get active => lists.isEmpty ? null : lists.first;

  @override
  List<Object?> get props => [lists];
}

/// Alimente l'écran 5a en écoutant la base locale (source de vérité offline) et
/// déclenche un rafraîchissement serveur en arrière-plan à l'ouverture.
class ShoppingListsCubit extends Cubit<ShoppingListsState> {
  ShoppingListsCubit({required ShoppingListRepository repository})
    : _repository = repository,
      super(const ShoppingListsLoading()) {
    _sub = _repository.watchActiveLists().listen((lists) {
      emit(ShoppingListsLoaded(lists));
    });
    // Sync d'ouverture : push des modifs en attente + pull. Silencieux si offline.
    unawaited(_repository.refresh());
  }

  final ShoppingListRepository _repository;
  StreamSubscription<List<ShoppingList>>? _sub;

  Future<void> refresh() => _repository.refresh();

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
