import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'shopping_database.g.dart';

/// État de synchronisation d'une entité locale (offline-first).
///
/// Modèle par-entité (plutôt qu'un journal d'actions) : chaque modification
/// tamponne l'entité `pending*` + son `clientUpdatedAt`, et la sync rejoue
/// l'action correspondante (upsert / delete) de façon idempotente. La résolution
/// de conflit « le plus récent gagne » se fait côté serveur via `clientUpdatedAt`.
abstract final class SyncState {
  static const synced = 'synced';
  static const pendingCreate = 'pendingCreate';
  static const pendingUpdate = 'pendingUpdate';
  static const pendingDelete = 'pendingDelete';
}

/// Listes de courses stockées localement (source de vérité hors-ligne).
class LocalShoppingLists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get clientUpdatedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  /// Soft-delete local (« vidée ») en attente de propagation au serveur.
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  TextColumn get syncState =>
      text().withDefault(const Constant(SyncState.synced))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Articles d'une liste (agrégés par ingrédient + articles libres).
class LocalShoppingItems extends Table {
  TextColumn get id => text()();
  TextColumn get listId =>
      text().references(LocalShoppingLists, #id, onDelete: KeyAction.cascade)();
  /// Ingrédient source (null = article libre).
  TextColumn get ingredientId => text().nullable()();
  TextColumn get customLabel => text().nullable()();
  TextColumn get name => text()();
  RealColumn get quantity => real().nullable()();
  TextColumn get unit => text().nullable()();
  BoolColumn get isChecked => boolean().withDefault(const Constant(false))();
  TextColumn get replacedByAlternativeId => text().nullable()();
  TextColumn get replacementName => text().nullable()();
  /// Contributions par recette, sérialisées en JSON ([{recipeId, quantity}]).
  TextColumn get sourcesJson => text().withDefault(const Constant('[]'))();
  IntColumn get position => integer().withDefault(const Constant(0))();
  DateTimeColumn get clientUpdatedAt => dateTime()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  TextColumn get syncState =>
      text().withDefault(const Constant(SyncState.synced))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Recettes ayant généré une liste (vue « par recette »), snapshotées.
class LocalShoppingRecipes extends Table {
  TextColumn get listId =>
      text().references(LocalShoppingLists, #id, onDelete: KeyAction.cascade)();
  TextColumn get recipeId => text()();
  TextColumn get recipeName => text()();
  TextColumn get photoUrl => text().nullable()();
  IntColumn get servings => integer()();

  @override
  Set<Column> get primaryKey => {listId, recipeId};
}

/// Base SQLite locale de la liste de courses (offline-first, scopée à cette
/// feature — cf. mobile/CLAUDE.md). Persistée sur disque via drift_flutter.
@DriftDatabase(
  tables: [LocalShoppingLists, LocalShoppingItems, LocalShoppingRecipes],
)
class ShoppingDatabase extends _$ShoppingDatabase {
  ShoppingDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'cocotte_shopping'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      // Cascade FK (articles/recettes supprimés avec leur liste).
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
