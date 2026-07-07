import 'package:get_it/get_it.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/ingredients/data/ingredients_repository.dart';
import '../../features/people/data/people_repository.dart';
import '../../features/tags/data/tags_repository.dart';
import '../network/api_client.dart';

/// Conteneur d'injection de dépendances global.
///
/// On y enregistre les singletons transverses (clients réseau, etc.).
/// Les repositories de features sont enregistrés au fil de leur ajout.
final GetIt sl = GetIt.instance;

void setupServiceLocator() {
  sl.registerLazySingleton<ApiClient>(() => ApiClient());
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepository(apiClient: sl<ApiClient>()),
  );
  sl.registerLazySingleton<IngredientsRepository>(
    () => IngredientsRepository(apiClient: sl<ApiClient>()),
  );
  sl.registerLazySingleton<TagsRepository>(
    () => TagsRepository(apiClient: sl<ApiClient>()),
  );
  sl.registerLazySingleton<PeopleRepository>(
    () => PeopleRepository(apiClient: sl<ApiClient>()),
  );
}
