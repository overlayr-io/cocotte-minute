import 'package:get_it/get_it.dart';

import '../network/api_client.dart';

/// Conteneur d'injection de dépendances global.
///
/// On y enregistre les singletons transverses (clients réseau, etc.).
/// Les repositories de features seront enregistrés au fil de leur ajout.
final GetIt sl = GetIt.instance;

void setupServiceLocator() {
  sl.registerLazySingleton<ApiClient>(() => ApiClient());
}
