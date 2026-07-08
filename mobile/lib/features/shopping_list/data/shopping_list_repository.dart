import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';

import '../domain/shopping_list.dart';
import 'local/shopping_database.dart';
import 'shopping_list_api.dart';

/// Repository **offline-first** de la liste de courses.
///
/// La base SQLite locale (Drift) est la source de vérité de l'UI : toutes les
/// lectures sont réactives (streams) et toutes les écritures se font d'abord en
/// local (marquées `pending*`), puis sont poussées au serveur dès que possible.
/// La résolution de conflit « le plus récent gagne » est arbitrée côté serveur
/// via `clientUpdatedAt`. La génération d'une liste, elle, nécessite le réseau
/// (agrégation serveur + données recettes) : une fois créée, la liste s'utilise
/// et se modifie entièrement hors-ligne.
class ShoppingListRepository {
  ShoppingListRepository({
    required ShoppingDatabase database,
    required ShoppingListApi api,
  }) : _db = database,
       _api = api;

  final ShoppingDatabase _db;
  final ShoppingListApi _api;
  bool _syncing = false;

  /// Cache de parsing de `sourcesJson`, clé = chaîne JSON brute. Les sources
  /// d'un article sont immuables après génération ; sans cache, chaque
  /// émission des `watch()` (ex. cocher UN article) re-jsonDecode les sources
  /// de TOUS les articles sur le main isolate.
  final _sourcesCache = <String, List<ShoppingItemSource>>{};

  // --- lectures réactives (local) ---------------------------------------

  /// Listes actives (non vidées), les plus récentes d'abord.
  Stream<List<ShoppingList>> watchActiveLists() {
    final lists = (_db.select(_db.localShoppingLists)
          ..where((t) => t.deleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
    final items = (_db.select(_db.localShoppingItems)
          ..where((t) => t.deleted.equals(false)))
        .watch();
    final recipes = _db.select(_db.localShoppingRecipes).watch();
    return _combine3(lists, items, recipes, (ls, its, rs) {
      return ls
          .map(
            (l) => _summaryFrom(
              l,
              its.where((i) => i.listId == l.id).toList(),
              rs.where((r) => r.listId == l.id).toList(),
            ),
          )
          .toList();
    });
  }

  /// Détail réactif d'une liste (résumé + articles ordonnés + recettes).
  Stream<ShoppingListDetail?> watchDetail(String id) {
    final list = (_db.select(_db.localShoppingLists)
          ..where((t) => t.id.equals(id) & t.deleted.equals(false)))
        .watchSingleOrNull();
    final items = (_db.select(_db.localShoppingItems)
          ..where((t) => t.listId.equals(id) & t.deleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.position)]))
        .watch();
    final recipes = (_db.select(_db.localShoppingRecipes)
          ..where((t) => t.listId.equals(id)))
        .watch();
    return _combine3(list, items, recipes, (l, its, rs) {
      if (l == null) return null;
      return ShoppingListDetail(
        list: _summaryFrom(l, its, rs),
        items: its.map(_itemToDomain).toList(),
        recipes: rs.map(_recipeToDomain).toList(),
      );
    });
  }

  // --- écritures (local d'abord, puis sync) -----------------------------

  /// Génère une liste côté serveur puis la stocke en local. Nécessite le réseau ;
  /// remonte le message serveur (ex: garde freemium « une seule liste active »).
  Future<ShoppingListDetail> generate({
    required String name,
    required List<({String recipeId, int servings})> recipes,
    required List<String> pantryIngredientIds,
  }) async {
    final detail = await _api.generate(
      id: _uuid(),
      name: name,
      recipes: recipes,
      pantryIngredientIds: pantryIngredientIds,
      clientUpdatedAt: DateTime.now(),
    );
    await _mergeServerList(detail);
    return detail;
  }

  /// Coche/décoche un article (local immédiat, puis push).
  Future<void> setChecked(String itemId, bool checked) async {
    await (_db.update(_db.localShoppingItems)..where((t) => t.id.equals(itemId)))
        .write(
      LocalShoppingItemsCompanion(
        isChecked: Value(checked),
        clientUpdatedAt: Value(DateTime.now()),
        syncState: Value(await _pendingUpdateState(itemId)),
      ),
    );
    _kickSync();
  }

  /// Applique une alternative « introuvable en magasin » (affichage seulement).
  /// `alternativeId`/`alternativeName` null réinitialisent vers l'original.
  Future<void> setAlternative(
    String itemId, {
    required String? alternativeId,
    required String? alternativeName,
  }) async {
    await (_db.update(_db.localShoppingItems)..where((t) => t.id.equals(itemId)))
        .write(
      LocalShoppingItemsCompanion(
        replacedByAlternativeId: Value(alternativeId),
        replacementName: Value(alternativeName),
        clientUpdatedAt: Value(DateTime.now()),
        syncState: Value(await _pendingUpdateState(itemId)),
      ),
    );
    _kickSync();
  }

  /// Ajoute un article libre (hors recette).
  Future<void> addFreeItem(
    String listId, {
    required String label,
    double? quantity,
    String? unit,
  }) async {
    final maxPos =
        await (_db.selectOnly(_db.localShoppingItems)
              ..addColumns([_db.localShoppingItems.position.max()])
              ..where(_db.localShoppingItems.listId.equals(listId)))
            .map((r) => r.read(_db.localShoppingItems.position.max()))
            .getSingleOrNull();
    await _db.into(_db.localShoppingItems).insert(
          LocalShoppingItemsCompanion.insert(
            id: _uuid(),
            listId: listId,
            name: label,
            customLabel: Value(label),
            quantity: Value(quantity),
            unit: Value(unit),
            position: Value((maxPos ?? -1) + 1),
            clientUpdatedAt: DateTime.now(),
            syncState: const Value(SyncState.pendingCreate),
          ),
        );
    _kickSync();
  }

  /// Supprime un article (retrait immédiat local, puis propagation).
  Future<void> removeItem(String itemId) async {
    final row = await (_db.select(_db.localShoppingItems)
          ..where((t) => t.id.equals(itemId)))
        .getSingleOrNull();
    if (row == null) return;
    if (row.syncState == SyncState.pendingCreate) {
      // Jamais synchronisé : suppression locale directe, rien à propager.
      await (_db.delete(_db.localShoppingItems)..where((t) => t.id.equals(itemId)))
          .go();
    } else {
      await (_db.update(_db.localShoppingItems)
            ..where((t) => t.id.equals(itemId)))
          .write(
        const LocalShoppingItemsCompanion(
          deleted: Value(true),
          syncState: Value(SyncState.pendingDelete),
        ),
      );
    }
    _kickSync();
  }

  /// Renomme une liste.
  Future<void> rename(String listId, String name) async {
    await (_db.update(_db.localShoppingLists)..where((t) => t.id.equals(listId)))
        .write(
      LocalShoppingListsCompanion(
        name: Value(name),
        clientUpdatedAt: Value(DateTime.now()),
        syncState: Value(await _pendingUpdateStateList(listId)),
      ),
    );
    _kickSync();
  }

  /// Retire de la liste les articles cochés (garde la liste et le reste).
  /// Mêmes règles offline-first que [removeItem], en une transaction.
  Future<void> clearChecked(String listId) async {
    await _db.transaction(() async {
      final rows = await (_db.select(_db.localShoppingItems)
            ..where((t) =>
                t.listId.equals(listId) &
                t.isChecked.equals(true) &
                t.deleted.equals(false)))
          .get();
      for (final row in rows) {
        if (row.syncState == SyncState.pendingCreate) {
          await (_db.delete(_db.localShoppingItems)
                ..where((t) => t.id.equals(row.id)))
              .go();
        } else {
          await (_db.update(_db.localShoppingItems)
                ..where((t) => t.id.equals(row.id)))
              .write(
            const LocalShoppingItemsCompanion(
              deleted: Value(true),
              syncState: Value(SyncState.pendingDelete),
            ),
          );
        }
      }
    });
    _kickSync();
  }

  /// « Vide » une liste (soft delete local + propagation).
  Future<void> clear(String listId) async {
    await (_db.update(_db.localShoppingLists)..where((t) => t.id.equals(listId)))
        .write(
      const LocalShoppingListsCompanion(
        deleted: Value(true),
        syncState: Value(SyncState.pendingDelete),
      ),
    );
    _kickSync();
  }

  // --- synchronisation ---------------------------------------------------

  /// Pousse toutes les modifications locales en attente, puis rafraîchit depuis
  /// le serveur. Sans réseau, les modifs restent en file et seront rejouées.
  Future<void> refresh() async {
    await syncPending();
    try {
      final lists = await _api.fetchLists();
      // Détails récupérés en parallèle (au lieu de N requêtes séquentielles).
      final details = await Future.wait(
        lists.map((l) => _api.fetchDetail(l.id)),
      );
      final serverIds = lists.map((l) => l.id).toSet();
      // Une seule transaction : les watch() ne ré-émettent qu'une fois à la
      // fin, au lieu d'une cascade de rebuilds par liste fusionnée.
      await _db.transaction(() async {
        final localLists = await _db.select(_db.localShoppingLists).get();
        for (final l in localLists) {
          if (!serverIds.contains(l.id) && l.syncState == SyncState.synced) {
            await (_db.delete(_db.localShoppingLists)
                  ..where((t) => t.id.equals(l.id)))
                .go();
          }
        }
        for (final detail in details) {
          await _mergeServerList(detail);
        }
      });
    } on ShoppingListApiException {
      // Hors ligne : on garde l'état local, la sync reprendra plus tard.
    }
  }

  /// Rejoue la file d'attente vers le serveur. Idempotent, arrêté proprement si
  /// le réseau retombe (les entités restent `pending*` pour un prochain essai).
  Future<void> syncPending() async {
    if (_syncing) return;
    _syncing = true;
    try {
      // Suppressions de listes.
      for (final l in await _pendingLists(SyncState.pendingDelete)) {
        final stop = await _guard(() => _api.clear(l.id));
        if (stop) return;
        await (_db.delete(_db.localShoppingLists)..where((t) => t.id.equals(l.id)))
            .go();
      }
      // Renommages de listes.
      for (final l in await _pendingLists(SyncState.pendingUpdate)) {
        final stop = await _guard(
          () => _api.rename(l.id, name: l.name, clientUpdatedAt: l.clientUpdatedAt),
        );
        if (stop) return;
        await _markListSynced(l.id);
      }
      // Créations d'articles libres.
      for (final it in await _pendingItems(SyncState.pendingCreate)) {
        final stop = await _guard(() async {
          await _api.createItem(
            it.listId,
            itemId: it.id,
            customLabel: it.customLabel ?? it.name,
            quantity: it.quantity,
            unit: it.unit,
            clientUpdatedAt: it.clientUpdatedAt,
          );
          if (it.isChecked || it.replacedByAlternativeId != null) {
            await _api.updateItem(
              it.listId,
              it.id,
              isChecked: it.isChecked,
              replacedByAlternativeId: it.replacedByAlternativeId,
              clientUpdatedAt: it.clientUpdatedAt,
            );
          }
        });
        if (stop) return;
        await _markItemSynced(it.id);
      }
      // Mises à jour d'articles (coché / alternative).
      for (final it in await _pendingItems(SyncState.pendingUpdate)) {
        final stop = await _guard(
          () => _api.updateItem(
            it.listId,
            it.id,
            isChecked: it.isChecked,
            replacedByAlternativeId: it.replacedByAlternativeId,
            clientUpdatedAt: it.clientUpdatedAt,
          ),
        );
        if (stop) return;
        await _markItemSynced(it.id);
      }
      // Suppressions d'articles.
      for (final it in await _pendingItems(SyncState.pendingDelete)) {
        final stop = await _guard(() => _api.removeItem(it.listId, it.id));
        if (stop) return;
        await (_db.delete(_db.localShoppingItems)
              ..where((t) => t.id.equals(it.id)))
            .go();
      }
    } finally {
      _syncing = false;
    }
  }

  // --- privé -------------------------------------------------------------

  void _kickSync() => unawaited(syncPending());

  /// Exécute un appel réseau. Renvoie `true` (= stop) si le réseau est absent
  /// (on réessaiera). Une erreur serveur (4xx) est absorbée pour ne pas boucler.
  Future<bool> _guard(Future<void> Function() call) async {
    try {
      await call();
      return false;
    } on ShoppingListApiException catch (e) {
      return e.isConnectivity;
    }
  }

  Future<List<LocalShoppingList>> _pendingLists(String state) =>
      (_db.select(_db.localShoppingLists)..where((t) => t.syncState.equals(state)))
          .get();

  Future<List<LocalShoppingItem>> _pendingItems(String state) =>
      (_db.select(_db.localShoppingItems)..where((t) => t.syncState.equals(state)))
          .get();

  Future<void> _markListSynced(String id) =>
      (_db.update(_db.localShoppingLists)..where((t) => t.id.equals(id))).write(
        const LocalShoppingListsCompanion(syncState: Value(SyncState.synced)),
      );

  Future<void> _markItemSynced(String id) =>
      (_db.update(_db.localShoppingItems)..where((t) => t.id.equals(id))).write(
        const LocalShoppingItemsCompanion(syncState: Value(SyncState.synced)),
      );

  /// Un article déjà en création reste `pendingCreate` (sinon `pendingUpdate`).
  Future<String> _pendingUpdateState(String itemId) async {
    final row = await (_db.select(_db.localShoppingItems)
          ..where((t) => t.id.equals(itemId)))
        .getSingleOrNull();
    return row?.syncState == SyncState.pendingCreate
        ? SyncState.pendingCreate
        : SyncState.pendingUpdate;
  }

  Future<String> _pendingUpdateStateList(String listId) async {
    final row = await (_db.select(_db.localShoppingLists)
          ..where((t) => t.id.equals(listId)))
        .getSingleOrNull();
    return row?.syncState == SyncState.pendingCreate
        ? SyncState.pendingCreate
        : SyncState.pendingUpdate;
  }

  /// Fusionne un détail serveur dans le local sans écraser les modifs locales
  /// encore en attente (celles-ci gagnent tant qu'elles ne sont pas poussées).
  Future<void> _mergeServerList(ShoppingListDetail d) async {
    await _db.transaction(() async {
      final localList = await (_db.select(_db.localShoppingLists)
            ..where((t) => t.id.equals(d.list.id)))
          .getSingleOrNull();
      if (localList != null && localList.syncState != SyncState.synced) {
        return; // modif locale plus récente non poussée : elle gagne
      }
      await _db.into(_db.localShoppingLists).insertOnConflictUpdate(
            LocalShoppingListsCompanion.insert(
              id: d.list.id,
              name: d.list.name,
              isArchived: Value(d.list.isArchived),
              clientUpdatedAt: d.list.clientUpdatedAt,
              createdAt: d.list.createdAt,
              deleted: const Value(false),
              syncState: const Value(SyncState.synced),
            ),
          );

      final localItems = await (_db.select(_db.localShoppingItems)
            ..where((t) => t.listId.equals(d.list.id)))
          .get();
      final localById = {for (final i in localItems) i.id: i};
      final serverIds = d.items.map((i) => i.id).toSet();
      for (final it in d.items) {
        final loc = localById[it.id];
        if (loc != null && loc.syncState != SyncState.synced) continue;
        await _db
            .into(_db.localShoppingItems)
            .insertOnConflictUpdate(_itemCompanion(d.list.id, it));
      }
      for (final loc in localItems) {
        if (!serverIds.contains(loc.id) && loc.syncState == SyncState.synced) {
          await (_db.delete(_db.localShoppingItems)
                ..where((t) => t.id.equals(loc.id)))
              .go();
        }
      }
      // Recettes immuables après génération : remplacement simple.
      await (_db.delete(_db.localShoppingRecipes)
            ..where((t) => t.listId.equals(d.list.id)))
          .go();
      for (final r in d.recipes) {
        await _db.into(_db.localShoppingRecipes).insert(
              LocalShoppingRecipesCompanion.insert(
                listId: d.list.id,
                recipeId: r.recipeId,
                recipeName: r.recipeName,
                photoUrl: Value(r.photoUrl),
                servings: r.servings,
              ),
            );
      }
    });
  }

  LocalShoppingItemsCompanion _itemCompanion(String listId, ShoppingListItem it) =>
      LocalShoppingItemsCompanion.insert(
        id: it.id,
        listId: listId,
        name: it.name,
        ingredientId: Value(it.ingredientId),
        customLabel: Value(it.customLabel),
        quantity: Value(it.quantity),
        unit: Value(it.unit),
        isChecked: Value(it.isChecked),
        replacedByAlternativeId: Value(it.replacedByAlternativeId),
        replacementName: Value(it.replacementName),
        sourcesJson: Value(
          jsonEncode(it.sources.map((s) => s.toJson()).toList()),
        ),
        position: Value(it.position),
        clientUpdatedAt: it.clientUpdatedAt,
        syncState: const Value(SyncState.synced),
      );

  ShoppingList _summaryFrom(
    LocalShoppingList l,
    List<LocalShoppingItem> items,
    List<LocalShoppingRecipe> recipes,
  ) {
    return ShoppingList(
      id: l.id,
      name: l.name,
      isArchived: l.isArchived,
      itemCount: items.length,
      checkedCount: items.where((i) => i.isChecked).length,
      recipeCount: recipes.length,
      clientUpdatedAt: l.clientUpdatedAt,
      createdAt: l.createdAt,
    );
  }

  ShoppingListItem _itemToDomain(LocalShoppingItem r) => ShoppingListItem(
    id: r.id,
    ingredientId: r.ingredientId,
    customLabel: r.customLabel,
    name: r.name,
    quantity: r.quantity,
    unit: r.unit,
    isChecked: r.isChecked,
    replacedByAlternativeId: r.replacedByAlternativeId,
    replacementName: r.replacementName,
    sources: _parseSources(r.sourcesJson),
    position: r.position,
    clientUpdatedAt: r.clientUpdatedAt,
  );

  List<ShoppingItemSource> _parseSources(String json) {
    final cached = _sourcesCache[json];
    if (cached != null) return cached;
    // Garde-fou : borne la mémoire si l'utilisateur accumule des listes.
    if (_sourcesCache.length > 500) _sourcesCache.clear();
    return _sourcesCache[json] = (jsonDecode(json) as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(ShoppingItemSource.fromJson)
        .toList(growable: false);
  }

  ShoppingRecipe _recipeToDomain(LocalShoppingRecipe r) => ShoppingRecipe(
    recipeId: r.recipeId,
    recipeName: r.recipeName,
    photoUrl: r.photoUrl,
    servings: r.servings,
  );

  static final _rng = Random.secure();

  /// UUID v4 (sans dépendance externe) pour des ids stables local↔serveur.
  static String _uuid() {
    final bytes = List<int>.generate(16, (_) => _rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}

/// Combine 3 streams en émettant dès que les trois ont produit une valeur.
Stream<R> _combine3<A, B, C, R>(
  Stream<A> a,
  Stream<B> b,
  Stream<C> c,
  R Function(A, B, C) combine,
) {
  late StreamController<R> controller;
  A? va;
  B? vb;
  C? vc;
  var ha = false, hb = false, hc = false;
  final subs = <StreamSubscription<dynamic>>[];

  void emit() {
    if (ha && hb && hc) controller.add(combine(va as A, vb as B, vc as C));
  }

  controller = StreamController<R>(
    onListen: () {
      subs.add(a.listen((v) {
        va = v;
        ha = true;
        emit();
      }, onError: controller.addError));
      subs.add(b.listen((v) {
        vb = v;
        hb = true;
        emit();
      }, onError: controller.addError));
      subs.add(c.listen((v) {
        vc = v;
        hc = true;
        emit();
      }, onError: controller.addError));
    },
    onCancel: () async {
      for (final s in subs) {
        await s.cancel();
      }
    },
  );
  return controller.stream;
}
