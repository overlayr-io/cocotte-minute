import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'shopping_list_repository.dart';

/// Déclenche la synchronisation de la liste de courses **au retour du réseau**.
///
/// Complète le push opportuniste fait à chaque écriture : couvre le cas où l'app
/// reste ouverte hors-ligne puis retrouve la connexion sans nouvelle action de
/// l'utilisateur. Idempotent (le repository ignore un drain déjà en cours).
class ShoppingSyncService {
  ShoppingSyncService({
    required ShoppingListRepository repository,
    Connectivity? connectivity,
  }) : _repository = repository,
       _connectivity = connectivity ?? Connectivity();

  final ShoppingListRepository _repository;
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  void start() {
    _sub ??= _connectivity.onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online) unawaited(_repository.syncPending());
    });
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }
}
