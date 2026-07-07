import 'package:get_it/get_it.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/categories/data/categories_repository.dart';
import '../../features/ingredients/data/ingredients_repository.dart';
import '../../features/people/data/people_repository.dart';
import '../../features/recipe_player/data/recipe_player_storage.dart';
import '../../features/recipes/data/recipes_repository.dart';
import '../../features/shopping_list/data/local/shopping_database.dart';
import '../../features/shopping_list/data/shopping_list_api.dart';
import '../../features/shopping_list/data/shopping_list_repository.dart';
import '../../features/shopping_list/data/shopping_sync_service.dart';
import '../../features/tags/data/tags_repository.dart';
import '../network/api_client.dart';
import '../storage/image_upload_service.dart';

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
  sl.registerLazySingleton<CategoriesRepository>(
    () => CategoriesRepository(apiClient: sl<ApiClient>()),
  );
  sl.registerLazySingleton<RecipesRepository>(
    () => RecipesRepository(apiClient: sl<ApiClient>()),
  );
  sl.registerLazySingleton<RecipePlayerStorage>(() => const RecipePlayerStorage());

  // Upload d'image partagé (ingrédient, avatar personne, photo recette) vers
  // Supabase Storage — bucket public « images ».
  sl.registerLazySingleton<ImageUploadService>(() => const ImageUploadService());

  // Liste de courses (offline-first) : base SQLite locale + API + sync réseau.
  sl.registerLazySingleton<ShoppingDatabase>(() => ShoppingDatabase());
  sl.registerLazySingleton<ShoppingListApi>(
    () => ShoppingListApi(apiClient: sl<ApiClient>()),
  );
  sl.registerLazySingleton<ShoppingListRepository>(
    () => ShoppingListRepository(
      database: sl<ShoppingDatabase>(),
      api: sl<ShoppingListApi>(),
    ),
  );
  sl.registerLazySingleton<ShoppingSyncService>(
    () => ShoppingSyncService(repository: sl<ShoppingListRepository>()),
  );
}
