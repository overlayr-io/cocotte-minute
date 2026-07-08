// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_database.dart';

// ignore_for_file: type=lint
class $LocalShoppingListsTable extends LocalShoppingLists
    with TableInfo<$LocalShoppingListsTable, LocalShoppingList> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalShoppingListsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _clientUpdatedAtMeta = const VerificationMeta(
    'clientUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> clientUpdatedAt =
      GeneratedColumn<DateTime>(
        'client_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncStateMeta = const VerificationMeta(
    'syncState',
  );
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
    'sync_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(SyncState.synced),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    isArchived,
    clientUpdatedAt,
    createdAt,
    deleted,
    syncState,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_shopping_lists';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalShoppingList> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('client_updated_at')) {
      context.handle(
        _clientUpdatedAtMeta,
        clientUpdatedAt.isAcceptableOrUnknown(
          data['client_updated_at']!,
          _clientUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientUpdatedAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('sync_state')) {
      context.handle(
        _syncStateMeta,
        syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalShoppingList map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalShoppingList(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      clientUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}client_updated_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      syncState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_state'],
      )!,
    );
  }

  @override
  $LocalShoppingListsTable createAlias(String alias) {
    return $LocalShoppingListsTable(attachedDatabase, alias);
  }
}

class LocalShoppingList extends DataClass
    implements Insertable<LocalShoppingList> {
  final String id;
  final String name;
  final bool isArchived;
  final DateTime clientUpdatedAt;
  final DateTime createdAt;

  /// Soft-delete local (« vidée ») en attente de propagation au serveur.
  final bool deleted;
  final String syncState;
  const LocalShoppingList({
    required this.id,
    required this.name,
    required this.isArchived,
    required this.clientUpdatedAt,
    required this.createdAt,
    required this.deleted,
    required this.syncState,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['is_archived'] = Variable<bool>(isArchived);
    map['client_updated_at'] = Variable<DateTime>(clientUpdatedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['deleted'] = Variable<bool>(deleted);
    map['sync_state'] = Variable<String>(syncState);
    return map;
  }

  LocalShoppingListsCompanion toCompanion(bool nullToAbsent) {
    return LocalShoppingListsCompanion(
      id: Value(id),
      name: Value(name),
      isArchived: Value(isArchived),
      clientUpdatedAt: Value(clientUpdatedAt),
      createdAt: Value(createdAt),
      deleted: Value(deleted),
      syncState: Value(syncState),
    );
  }

  factory LocalShoppingList.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalShoppingList(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      clientUpdatedAt: serializer.fromJson<DateTime>(json['clientUpdatedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      syncState: serializer.fromJson<String>(json['syncState']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'isArchived': serializer.toJson<bool>(isArchived),
      'clientUpdatedAt': serializer.toJson<DateTime>(clientUpdatedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'deleted': serializer.toJson<bool>(deleted),
      'syncState': serializer.toJson<String>(syncState),
    };
  }

  LocalShoppingList copyWith({
    String? id,
    String? name,
    bool? isArchived,
    DateTime? clientUpdatedAt,
    DateTime? createdAt,
    bool? deleted,
    String? syncState,
  }) => LocalShoppingList(
    id: id ?? this.id,
    name: name ?? this.name,
    isArchived: isArchived ?? this.isArchived,
    clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
    createdAt: createdAt ?? this.createdAt,
    deleted: deleted ?? this.deleted,
    syncState: syncState ?? this.syncState,
  );
  LocalShoppingList copyWithCompanion(LocalShoppingListsCompanion data) {
    return LocalShoppingList(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      clientUpdatedAt: data.clientUpdatedAt.present
          ? data.clientUpdatedAt.value
          : this.clientUpdatedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalShoppingList(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isArchived: $isArchived, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('deleted: $deleted, ')
          ..write('syncState: $syncState')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    isArchived,
    clientUpdatedAt,
    createdAt,
    deleted,
    syncState,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalShoppingList &&
          other.id == this.id &&
          other.name == this.name &&
          other.isArchived == this.isArchived &&
          other.clientUpdatedAt == this.clientUpdatedAt &&
          other.createdAt == this.createdAt &&
          other.deleted == this.deleted &&
          other.syncState == this.syncState);
}

class LocalShoppingListsCompanion extends UpdateCompanion<LocalShoppingList> {
  final Value<String> id;
  final Value<String> name;
  final Value<bool> isArchived;
  final Value<DateTime> clientUpdatedAt;
  final Value<DateTime> createdAt;
  final Value<bool> deleted;
  final Value<String> syncState;
  final Value<int> rowid;
  const LocalShoppingListsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.clientUpdatedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.syncState = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalShoppingListsCompanion.insert({
    required String id,
    required String name,
    this.isArchived = const Value.absent(),
    required DateTime clientUpdatedAt,
    required DateTime createdAt,
    this.deleted = const Value.absent(),
    this.syncState = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       clientUpdatedAt = Value(clientUpdatedAt),
       createdAt = Value(createdAt);
  static Insertable<LocalShoppingList> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<bool>? isArchived,
    Expression<DateTime>? clientUpdatedAt,
    Expression<DateTime>? createdAt,
    Expression<bool>? deleted,
    Expression<String>? syncState,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (isArchived != null) 'is_archived': isArchived,
      if (clientUpdatedAt != null) 'client_updated_at': clientUpdatedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (deleted != null) 'deleted': deleted,
      if (syncState != null) 'sync_state': syncState,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalShoppingListsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<bool>? isArchived,
    Value<DateTime>? clientUpdatedAt,
    Value<DateTime>? createdAt,
    Value<bool>? deleted,
    Value<String>? syncState,
    Value<int>? rowid,
  }) {
    return LocalShoppingListsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      isArchived: isArchived ?? this.isArchived,
      clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
      createdAt: createdAt ?? this.createdAt,
      deleted: deleted ?? this.deleted,
      syncState: syncState ?? this.syncState,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (clientUpdatedAt.present) {
      map['client_updated_at'] = Variable<DateTime>(clientUpdatedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalShoppingListsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isArchived: $isArchived, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('deleted: $deleted, ')
          ..write('syncState: $syncState, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalShoppingItemsTable extends LocalShoppingItems
    with TableInfo<$LocalShoppingItemsTable, LocalShoppingItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalShoppingItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _listIdMeta = const VerificationMeta('listId');
  @override
  late final GeneratedColumn<String> listId = GeneratedColumn<String>(
    'list_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES local_shopping_lists (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _ingredientIdMeta = const VerificationMeta(
    'ingredientId',
  );
  @override
  late final GeneratedColumn<String> ingredientId = GeneratedColumn<String>(
    'ingredient_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customLabelMeta = const VerificationMeta(
    'customLabel',
  );
  @override
  late final GeneratedColumn<String> customLabel = GeneratedColumn<String>(
    'custom_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isCheckedMeta = const VerificationMeta(
    'isChecked',
  );
  @override
  late final GeneratedColumn<bool> isChecked = GeneratedColumn<bool>(
    'is_checked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_checked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _replacedByAlternativeIdMeta =
      const VerificationMeta('replacedByAlternativeId');
  @override
  late final GeneratedColumn<String> replacedByAlternativeId =
      GeneratedColumn<String>(
        'replaced_by_alternative_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _replacementNameMeta = const VerificationMeta(
    'replacementName',
  );
  @override
  late final GeneratedColumn<String> replacementName = GeneratedColumn<String>(
    'replacement_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourcesJsonMeta = const VerificationMeta(
    'sourcesJson',
  );
  @override
  late final GeneratedColumn<String> sourcesJson = GeneratedColumn<String>(
    'sources_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _clientUpdatedAtMeta = const VerificationMeta(
    'clientUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> clientUpdatedAt =
      GeneratedColumn<DateTime>(
        'client_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncStateMeta = const VerificationMeta(
    'syncState',
  );
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
    'sync_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(SyncState.synced),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    listId,
    ingredientId,
    customLabel,
    name,
    quantity,
    unit,
    isChecked,
    replacedByAlternativeId,
    replacementName,
    sourcesJson,
    position,
    clientUpdatedAt,
    deleted,
    syncState,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_shopping_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalShoppingItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('list_id')) {
      context.handle(
        _listIdMeta,
        listId.isAcceptableOrUnknown(data['list_id']!, _listIdMeta),
      );
    } else if (isInserting) {
      context.missing(_listIdMeta);
    }
    if (data.containsKey('ingredient_id')) {
      context.handle(
        _ingredientIdMeta,
        ingredientId.isAcceptableOrUnknown(
          data['ingredient_id']!,
          _ingredientIdMeta,
        ),
      );
    }
    if (data.containsKey('custom_label')) {
      context.handle(
        _customLabelMeta,
        customLabel.isAcceptableOrUnknown(
          data['custom_label']!,
          _customLabelMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('is_checked')) {
      context.handle(
        _isCheckedMeta,
        isChecked.isAcceptableOrUnknown(data['is_checked']!, _isCheckedMeta),
      );
    }
    if (data.containsKey('replaced_by_alternative_id')) {
      context.handle(
        _replacedByAlternativeIdMeta,
        replacedByAlternativeId.isAcceptableOrUnknown(
          data['replaced_by_alternative_id']!,
          _replacedByAlternativeIdMeta,
        ),
      );
    }
    if (data.containsKey('replacement_name')) {
      context.handle(
        _replacementNameMeta,
        replacementName.isAcceptableOrUnknown(
          data['replacement_name']!,
          _replacementNameMeta,
        ),
      );
    }
    if (data.containsKey('sources_json')) {
      context.handle(
        _sourcesJsonMeta,
        sourcesJson.isAcceptableOrUnknown(
          data['sources_json']!,
          _sourcesJsonMeta,
        ),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    if (data.containsKey('client_updated_at')) {
      context.handle(
        _clientUpdatedAtMeta,
        clientUpdatedAt.isAcceptableOrUnknown(
          data['client_updated_at']!,
          _clientUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientUpdatedAtMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('sync_state')) {
      context.handle(
        _syncStateMeta,
        syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalShoppingItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalShoppingItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      listId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}list_id'],
      )!,
      ingredientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ingredient_id'],
      ),
      customLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_label'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      isChecked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_checked'],
      )!,
      replacedByAlternativeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}replaced_by_alternative_id'],
      ),
      replacementName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}replacement_name'],
      ),
      sourcesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sources_json'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      clientUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}client_updated_at'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      syncState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_state'],
      )!,
    );
  }

  @override
  $LocalShoppingItemsTable createAlias(String alias) {
    return $LocalShoppingItemsTable(attachedDatabase, alias);
  }
}

class LocalShoppingItem extends DataClass
    implements Insertable<LocalShoppingItem> {
  final String id;
  final String listId;

  /// Ingrédient source (null = article libre).
  final String? ingredientId;
  final String? customLabel;
  final String name;
  final double? quantity;
  final String? unit;
  final bool isChecked;
  final String? replacedByAlternativeId;
  final String? replacementName;

  /// Contributions par recette, sérialisées en JSON ([{recipeId, quantity}]).
  final String sourcesJson;
  final int position;
  final DateTime clientUpdatedAt;
  final bool deleted;
  final String syncState;
  const LocalShoppingItem({
    required this.id,
    required this.listId,
    this.ingredientId,
    this.customLabel,
    required this.name,
    this.quantity,
    this.unit,
    required this.isChecked,
    this.replacedByAlternativeId,
    this.replacementName,
    required this.sourcesJson,
    required this.position,
    required this.clientUpdatedAt,
    required this.deleted,
    required this.syncState,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['list_id'] = Variable<String>(listId);
    if (!nullToAbsent || ingredientId != null) {
      map['ingredient_id'] = Variable<String>(ingredientId);
    }
    if (!nullToAbsent || customLabel != null) {
      map['custom_label'] = Variable<String>(customLabel);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || quantity != null) {
      map['quantity'] = Variable<double>(quantity);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    map['is_checked'] = Variable<bool>(isChecked);
    if (!nullToAbsent || replacedByAlternativeId != null) {
      map['replaced_by_alternative_id'] = Variable<String>(
        replacedByAlternativeId,
      );
    }
    if (!nullToAbsent || replacementName != null) {
      map['replacement_name'] = Variable<String>(replacementName);
    }
    map['sources_json'] = Variable<String>(sourcesJson);
    map['position'] = Variable<int>(position);
    map['client_updated_at'] = Variable<DateTime>(clientUpdatedAt);
    map['deleted'] = Variable<bool>(deleted);
    map['sync_state'] = Variable<String>(syncState);
    return map;
  }

  LocalShoppingItemsCompanion toCompanion(bool nullToAbsent) {
    return LocalShoppingItemsCompanion(
      id: Value(id),
      listId: Value(listId),
      ingredientId: ingredientId == null && nullToAbsent
          ? const Value.absent()
          : Value(ingredientId),
      customLabel: customLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(customLabel),
      name: Value(name),
      quantity: quantity == null && nullToAbsent
          ? const Value.absent()
          : Value(quantity),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      isChecked: Value(isChecked),
      replacedByAlternativeId: replacedByAlternativeId == null && nullToAbsent
          ? const Value.absent()
          : Value(replacedByAlternativeId),
      replacementName: replacementName == null && nullToAbsent
          ? const Value.absent()
          : Value(replacementName),
      sourcesJson: Value(sourcesJson),
      position: Value(position),
      clientUpdatedAt: Value(clientUpdatedAt),
      deleted: Value(deleted),
      syncState: Value(syncState),
    );
  }

  factory LocalShoppingItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalShoppingItem(
      id: serializer.fromJson<String>(json['id']),
      listId: serializer.fromJson<String>(json['listId']),
      ingredientId: serializer.fromJson<String?>(json['ingredientId']),
      customLabel: serializer.fromJson<String?>(json['customLabel']),
      name: serializer.fromJson<String>(json['name']),
      quantity: serializer.fromJson<double?>(json['quantity']),
      unit: serializer.fromJson<String?>(json['unit']),
      isChecked: serializer.fromJson<bool>(json['isChecked']),
      replacedByAlternativeId: serializer.fromJson<String?>(
        json['replacedByAlternativeId'],
      ),
      replacementName: serializer.fromJson<String?>(json['replacementName']),
      sourcesJson: serializer.fromJson<String>(json['sourcesJson']),
      position: serializer.fromJson<int>(json['position']),
      clientUpdatedAt: serializer.fromJson<DateTime>(json['clientUpdatedAt']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      syncState: serializer.fromJson<String>(json['syncState']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'listId': serializer.toJson<String>(listId),
      'ingredientId': serializer.toJson<String?>(ingredientId),
      'customLabel': serializer.toJson<String?>(customLabel),
      'name': serializer.toJson<String>(name),
      'quantity': serializer.toJson<double?>(quantity),
      'unit': serializer.toJson<String?>(unit),
      'isChecked': serializer.toJson<bool>(isChecked),
      'replacedByAlternativeId': serializer.toJson<String?>(
        replacedByAlternativeId,
      ),
      'replacementName': serializer.toJson<String?>(replacementName),
      'sourcesJson': serializer.toJson<String>(sourcesJson),
      'position': serializer.toJson<int>(position),
      'clientUpdatedAt': serializer.toJson<DateTime>(clientUpdatedAt),
      'deleted': serializer.toJson<bool>(deleted),
      'syncState': serializer.toJson<String>(syncState),
    };
  }

  LocalShoppingItem copyWith({
    String? id,
    String? listId,
    Value<String?> ingredientId = const Value.absent(),
    Value<String?> customLabel = const Value.absent(),
    String? name,
    Value<double?> quantity = const Value.absent(),
    Value<String?> unit = const Value.absent(),
    bool? isChecked,
    Value<String?> replacedByAlternativeId = const Value.absent(),
    Value<String?> replacementName = const Value.absent(),
    String? sourcesJson,
    int? position,
    DateTime? clientUpdatedAt,
    bool? deleted,
    String? syncState,
  }) => LocalShoppingItem(
    id: id ?? this.id,
    listId: listId ?? this.listId,
    ingredientId: ingredientId.present ? ingredientId.value : this.ingredientId,
    customLabel: customLabel.present ? customLabel.value : this.customLabel,
    name: name ?? this.name,
    quantity: quantity.present ? quantity.value : this.quantity,
    unit: unit.present ? unit.value : this.unit,
    isChecked: isChecked ?? this.isChecked,
    replacedByAlternativeId: replacedByAlternativeId.present
        ? replacedByAlternativeId.value
        : this.replacedByAlternativeId,
    replacementName: replacementName.present
        ? replacementName.value
        : this.replacementName,
    sourcesJson: sourcesJson ?? this.sourcesJson,
    position: position ?? this.position,
    clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
    deleted: deleted ?? this.deleted,
    syncState: syncState ?? this.syncState,
  );
  LocalShoppingItem copyWithCompanion(LocalShoppingItemsCompanion data) {
    return LocalShoppingItem(
      id: data.id.present ? data.id.value : this.id,
      listId: data.listId.present ? data.listId.value : this.listId,
      ingredientId: data.ingredientId.present
          ? data.ingredientId.value
          : this.ingredientId,
      customLabel: data.customLabel.present
          ? data.customLabel.value
          : this.customLabel,
      name: data.name.present ? data.name.value : this.name,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unit: data.unit.present ? data.unit.value : this.unit,
      isChecked: data.isChecked.present ? data.isChecked.value : this.isChecked,
      replacedByAlternativeId: data.replacedByAlternativeId.present
          ? data.replacedByAlternativeId.value
          : this.replacedByAlternativeId,
      replacementName: data.replacementName.present
          ? data.replacementName.value
          : this.replacementName,
      sourcesJson: data.sourcesJson.present
          ? data.sourcesJson.value
          : this.sourcesJson,
      position: data.position.present ? data.position.value : this.position,
      clientUpdatedAt: data.clientUpdatedAt.present
          ? data.clientUpdatedAt.value
          : this.clientUpdatedAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalShoppingItem(')
          ..write('id: $id, ')
          ..write('listId: $listId, ')
          ..write('ingredientId: $ingredientId, ')
          ..write('customLabel: $customLabel, ')
          ..write('name: $name, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('isChecked: $isChecked, ')
          ..write('replacedByAlternativeId: $replacedByAlternativeId, ')
          ..write('replacementName: $replacementName, ')
          ..write('sourcesJson: $sourcesJson, ')
          ..write('position: $position, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('syncState: $syncState')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    listId,
    ingredientId,
    customLabel,
    name,
    quantity,
    unit,
    isChecked,
    replacedByAlternativeId,
    replacementName,
    sourcesJson,
    position,
    clientUpdatedAt,
    deleted,
    syncState,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalShoppingItem &&
          other.id == this.id &&
          other.listId == this.listId &&
          other.ingredientId == this.ingredientId &&
          other.customLabel == this.customLabel &&
          other.name == this.name &&
          other.quantity == this.quantity &&
          other.unit == this.unit &&
          other.isChecked == this.isChecked &&
          other.replacedByAlternativeId == this.replacedByAlternativeId &&
          other.replacementName == this.replacementName &&
          other.sourcesJson == this.sourcesJson &&
          other.position == this.position &&
          other.clientUpdatedAt == this.clientUpdatedAt &&
          other.deleted == this.deleted &&
          other.syncState == this.syncState);
}

class LocalShoppingItemsCompanion extends UpdateCompanion<LocalShoppingItem> {
  final Value<String> id;
  final Value<String> listId;
  final Value<String?> ingredientId;
  final Value<String?> customLabel;
  final Value<String> name;
  final Value<double?> quantity;
  final Value<String?> unit;
  final Value<bool> isChecked;
  final Value<String?> replacedByAlternativeId;
  final Value<String?> replacementName;
  final Value<String> sourcesJson;
  final Value<int> position;
  final Value<DateTime> clientUpdatedAt;
  final Value<bool> deleted;
  final Value<String> syncState;
  final Value<int> rowid;
  const LocalShoppingItemsCompanion({
    this.id = const Value.absent(),
    this.listId = const Value.absent(),
    this.ingredientId = const Value.absent(),
    this.customLabel = const Value.absent(),
    this.name = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.isChecked = const Value.absent(),
    this.replacedByAlternativeId = const Value.absent(),
    this.replacementName = const Value.absent(),
    this.sourcesJson = const Value.absent(),
    this.position = const Value.absent(),
    this.clientUpdatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.syncState = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalShoppingItemsCompanion.insert({
    required String id,
    required String listId,
    this.ingredientId = const Value.absent(),
    this.customLabel = const Value.absent(),
    required String name,
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.isChecked = const Value.absent(),
    this.replacedByAlternativeId = const Value.absent(),
    this.replacementName = const Value.absent(),
    this.sourcesJson = const Value.absent(),
    this.position = const Value.absent(),
    required DateTime clientUpdatedAt,
    this.deleted = const Value.absent(),
    this.syncState = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       listId = Value(listId),
       name = Value(name),
       clientUpdatedAt = Value(clientUpdatedAt);
  static Insertable<LocalShoppingItem> custom({
    Expression<String>? id,
    Expression<String>? listId,
    Expression<String>? ingredientId,
    Expression<String>? customLabel,
    Expression<String>? name,
    Expression<double>? quantity,
    Expression<String>? unit,
    Expression<bool>? isChecked,
    Expression<String>? replacedByAlternativeId,
    Expression<String>? replacementName,
    Expression<String>? sourcesJson,
    Expression<int>? position,
    Expression<DateTime>? clientUpdatedAt,
    Expression<bool>? deleted,
    Expression<String>? syncState,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (listId != null) 'list_id': listId,
      if (ingredientId != null) 'ingredient_id': ingredientId,
      if (customLabel != null) 'custom_label': customLabel,
      if (name != null) 'name': name,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (isChecked != null) 'is_checked': isChecked,
      if (replacedByAlternativeId != null)
        'replaced_by_alternative_id': replacedByAlternativeId,
      if (replacementName != null) 'replacement_name': replacementName,
      if (sourcesJson != null) 'sources_json': sourcesJson,
      if (position != null) 'position': position,
      if (clientUpdatedAt != null) 'client_updated_at': clientUpdatedAt,
      if (deleted != null) 'deleted': deleted,
      if (syncState != null) 'sync_state': syncState,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalShoppingItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? listId,
    Value<String?>? ingredientId,
    Value<String?>? customLabel,
    Value<String>? name,
    Value<double?>? quantity,
    Value<String?>? unit,
    Value<bool>? isChecked,
    Value<String?>? replacedByAlternativeId,
    Value<String?>? replacementName,
    Value<String>? sourcesJson,
    Value<int>? position,
    Value<DateTime>? clientUpdatedAt,
    Value<bool>? deleted,
    Value<String>? syncState,
    Value<int>? rowid,
  }) {
    return LocalShoppingItemsCompanion(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      ingredientId: ingredientId ?? this.ingredientId,
      customLabel: customLabel ?? this.customLabel,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      isChecked: isChecked ?? this.isChecked,
      replacedByAlternativeId:
          replacedByAlternativeId ?? this.replacedByAlternativeId,
      replacementName: replacementName ?? this.replacementName,
      sourcesJson: sourcesJson ?? this.sourcesJson,
      position: position ?? this.position,
      clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
      deleted: deleted ?? this.deleted,
      syncState: syncState ?? this.syncState,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (listId.present) {
      map['list_id'] = Variable<String>(listId.value);
    }
    if (ingredientId.present) {
      map['ingredient_id'] = Variable<String>(ingredientId.value);
    }
    if (customLabel.present) {
      map['custom_label'] = Variable<String>(customLabel.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (isChecked.present) {
      map['is_checked'] = Variable<bool>(isChecked.value);
    }
    if (replacedByAlternativeId.present) {
      map['replaced_by_alternative_id'] = Variable<String>(
        replacedByAlternativeId.value,
      );
    }
    if (replacementName.present) {
      map['replacement_name'] = Variable<String>(replacementName.value);
    }
    if (sourcesJson.present) {
      map['sources_json'] = Variable<String>(sourcesJson.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (clientUpdatedAt.present) {
      map['client_updated_at'] = Variable<DateTime>(clientUpdatedAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalShoppingItemsCompanion(')
          ..write('id: $id, ')
          ..write('listId: $listId, ')
          ..write('ingredientId: $ingredientId, ')
          ..write('customLabel: $customLabel, ')
          ..write('name: $name, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('isChecked: $isChecked, ')
          ..write('replacedByAlternativeId: $replacedByAlternativeId, ')
          ..write('replacementName: $replacementName, ')
          ..write('sourcesJson: $sourcesJson, ')
          ..write('position: $position, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('syncState: $syncState, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalShoppingRecipesTable extends LocalShoppingRecipes
    with TableInfo<$LocalShoppingRecipesTable, LocalShoppingRecipe> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalShoppingRecipesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _listIdMeta = const VerificationMeta('listId');
  @override
  late final GeneratedColumn<String> listId = GeneratedColumn<String>(
    'list_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES local_shopping_lists (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _recipeIdMeta = const VerificationMeta(
    'recipeId',
  );
  @override
  late final GeneratedColumn<String> recipeId = GeneratedColumn<String>(
    'recipe_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recipeNameMeta = const VerificationMeta(
    'recipeName',
  );
  @override
  late final GeneratedColumn<String> recipeName = GeneratedColumn<String>(
    'recipe_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _photoUrlMeta = const VerificationMeta(
    'photoUrl',
  );
  @override
  late final GeneratedColumn<String> photoUrl = GeneratedColumn<String>(
    'photo_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _servingsMeta = const VerificationMeta(
    'servings',
  );
  @override
  late final GeneratedColumn<int> servings = GeneratedColumn<int>(
    'servings',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    listId,
    recipeId,
    recipeName,
    photoUrl,
    servings,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_shopping_recipes';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalShoppingRecipe> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('list_id')) {
      context.handle(
        _listIdMeta,
        listId.isAcceptableOrUnknown(data['list_id']!, _listIdMeta),
      );
    } else if (isInserting) {
      context.missing(_listIdMeta);
    }
    if (data.containsKey('recipe_id')) {
      context.handle(
        _recipeIdMeta,
        recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recipeIdMeta);
    }
    if (data.containsKey('recipe_name')) {
      context.handle(
        _recipeNameMeta,
        recipeName.isAcceptableOrUnknown(data['recipe_name']!, _recipeNameMeta),
      );
    } else if (isInserting) {
      context.missing(_recipeNameMeta);
    }
    if (data.containsKey('photo_url')) {
      context.handle(
        _photoUrlMeta,
        photoUrl.isAcceptableOrUnknown(data['photo_url']!, _photoUrlMeta),
      );
    }
    if (data.containsKey('servings')) {
      context.handle(
        _servingsMeta,
        servings.isAcceptableOrUnknown(data['servings']!, _servingsMeta),
      );
    } else if (isInserting) {
      context.missing(_servingsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {listId, recipeId};
  @override
  LocalShoppingRecipe map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalShoppingRecipe(
      listId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}list_id'],
      )!,
      recipeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipe_id'],
      )!,
      recipeName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipe_name'],
      )!,
      photoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_url'],
      ),
      servings: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}servings'],
      )!,
    );
  }

  @override
  $LocalShoppingRecipesTable createAlias(String alias) {
    return $LocalShoppingRecipesTable(attachedDatabase, alias);
  }
}

class LocalShoppingRecipe extends DataClass
    implements Insertable<LocalShoppingRecipe> {
  final String listId;
  final String recipeId;
  final String recipeName;
  final String? photoUrl;
  final int servings;
  const LocalShoppingRecipe({
    required this.listId,
    required this.recipeId,
    required this.recipeName,
    this.photoUrl,
    required this.servings,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['list_id'] = Variable<String>(listId);
    map['recipe_id'] = Variable<String>(recipeId);
    map['recipe_name'] = Variable<String>(recipeName);
    if (!nullToAbsent || photoUrl != null) {
      map['photo_url'] = Variable<String>(photoUrl);
    }
    map['servings'] = Variable<int>(servings);
    return map;
  }

  LocalShoppingRecipesCompanion toCompanion(bool nullToAbsent) {
    return LocalShoppingRecipesCompanion(
      listId: Value(listId),
      recipeId: Value(recipeId),
      recipeName: Value(recipeName),
      photoUrl: photoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(photoUrl),
      servings: Value(servings),
    );
  }

  factory LocalShoppingRecipe.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalShoppingRecipe(
      listId: serializer.fromJson<String>(json['listId']),
      recipeId: serializer.fromJson<String>(json['recipeId']),
      recipeName: serializer.fromJson<String>(json['recipeName']),
      photoUrl: serializer.fromJson<String?>(json['photoUrl']),
      servings: serializer.fromJson<int>(json['servings']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'listId': serializer.toJson<String>(listId),
      'recipeId': serializer.toJson<String>(recipeId),
      'recipeName': serializer.toJson<String>(recipeName),
      'photoUrl': serializer.toJson<String?>(photoUrl),
      'servings': serializer.toJson<int>(servings),
    };
  }

  LocalShoppingRecipe copyWith({
    String? listId,
    String? recipeId,
    String? recipeName,
    Value<String?> photoUrl = const Value.absent(),
    int? servings,
  }) => LocalShoppingRecipe(
    listId: listId ?? this.listId,
    recipeId: recipeId ?? this.recipeId,
    recipeName: recipeName ?? this.recipeName,
    photoUrl: photoUrl.present ? photoUrl.value : this.photoUrl,
    servings: servings ?? this.servings,
  );
  LocalShoppingRecipe copyWithCompanion(LocalShoppingRecipesCompanion data) {
    return LocalShoppingRecipe(
      listId: data.listId.present ? data.listId.value : this.listId,
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      recipeName: data.recipeName.present
          ? data.recipeName.value
          : this.recipeName,
      photoUrl: data.photoUrl.present ? data.photoUrl.value : this.photoUrl,
      servings: data.servings.present ? data.servings.value : this.servings,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalShoppingRecipe(')
          ..write('listId: $listId, ')
          ..write('recipeId: $recipeId, ')
          ..write('recipeName: $recipeName, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('servings: $servings')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(listId, recipeId, recipeName, photoUrl, servings);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalShoppingRecipe &&
          other.listId == this.listId &&
          other.recipeId == this.recipeId &&
          other.recipeName == this.recipeName &&
          other.photoUrl == this.photoUrl &&
          other.servings == this.servings);
}

class LocalShoppingRecipesCompanion
    extends UpdateCompanion<LocalShoppingRecipe> {
  final Value<String> listId;
  final Value<String> recipeId;
  final Value<String> recipeName;
  final Value<String?> photoUrl;
  final Value<int> servings;
  final Value<int> rowid;
  const LocalShoppingRecipesCompanion({
    this.listId = const Value.absent(),
    this.recipeId = const Value.absent(),
    this.recipeName = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.servings = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalShoppingRecipesCompanion.insert({
    required String listId,
    required String recipeId,
    required String recipeName,
    this.photoUrl = const Value.absent(),
    required int servings,
    this.rowid = const Value.absent(),
  }) : listId = Value(listId),
       recipeId = Value(recipeId),
       recipeName = Value(recipeName),
       servings = Value(servings);
  static Insertable<LocalShoppingRecipe> custom({
    Expression<String>? listId,
    Expression<String>? recipeId,
    Expression<String>? recipeName,
    Expression<String>? photoUrl,
    Expression<int>? servings,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (listId != null) 'list_id': listId,
      if (recipeId != null) 'recipe_id': recipeId,
      if (recipeName != null) 'recipe_name': recipeName,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (servings != null) 'servings': servings,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalShoppingRecipesCompanion copyWith({
    Value<String>? listId,
    Value<String>? recipeId,
    Value<String>? recipeName,
    Value<String?>? photoUrl,
    Value<int>? servings,
    Value<int>? rowid,
  }) {
    return LocalShoppingRecipesCompanion(
      listId: listId ?? this.listId,
      recipeId: recipeId ?? this.recipeId,
      recipeName: recipeName ?? this.recipeName,
      photoUrl: photoUrl ?? this.photoUrl,
      servings: servings ?? this.servings,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (listId.present) {
      map['list_id'] = Variable<String>(listId.value);
    }
    if (recipeId.present) {
      map['recipe_id'] = Variable<String>(recipeId.value);
    }
    if (recipeName.present) {
      map['recipe_name'] = Variable<String>(recipeName.value);
    }
    if (photoUrl.present) {
      map['photo_url'] = Variable<String>(photoUrl.value);
    }
    if (servings.present) {
      map['servings'] = Variable<int>(servings.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalShoppingRecipesCompanion(')
          ..write('listId: $listId, ')
          ..write('recipeId: $recipeId, ')
          ..write('recipeName: $recipeName, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('servings: $servings, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$ShoppingDatabase extends GeneratedDatabase {
  _$ShoppingDatabase(QueryExecutor e) : super(e);
  $ShoppingDatabaseManager get managers => $ShoppingDatabaseManager(this);
  late final $LocalShoppingListsTable localShoppingLists =
      $LocalShoppingListsTable(this);
  late final $LocalShoppingItemsTable localShoppingItems =
      $LocalShoppingItemsTable(this);
  late final $LocalShoppingRecipesTable localShoppingRecipes =
      $LocalShoppingRecipesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localShoppingLists,
    localShoppingItems,
    localShoppingRecipes,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'local_shopping_lists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('local_shopping_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'local_shopping_lists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('local_shopping_recipes', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$LocalShoppingListsTableCreateCompanionBuilder =
    LocalShoppingListsCompanion Function({
      required String id,
      required String name,
      Value<bool> isArchived,
      required DateTime clientUpdatedAt,
      required DateTime createdAt,
      Value<bool> deleted,
      Value<String> syncState,
      Value<int> rowid,
    });
typedef $$LocalShoppingListsTableUpdateCompanionBuilder =
    LocalShoppingListsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<bool> isArchived,
      Value<DateTime> clientUpdatedAt,
      Value<DateTime> createdAt,
      Value<bool> deleted,
      Value<String> syncState,
      Value<int> rowid,
    });

final class $$LocalShoppingListsTableReferences
    extends
        BaseReferences<
          _$ShoppingDatabase,
          $LocalShoppingListsTable,
          LocalShoppingList
        > {
  $$LocalShoppingListsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$LocalShoppingItemsTable, List<LocalShoppingItem>>
  _localShoppingItemsRefsTable(_$ShoppingDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.localShoppingItems,
        aliasName: $_aliasNameGenerator(
          db.localShoppingLists.id,
          db.localShoppingItems.listId,
        ),
      );

  $$LocalShoppingItemsTableProcessedTableManager get localShoppingItemsRefs {
    final manager = $$LocalShoppingItemsTableTableManager(
      $_db,
      $_db.localShoppingItems,
    ).filter((f) => f.listId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _localShoppingItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $LocalShoppingRecipesTable,
    List<LocalShoppingRecipe>
  >
  _localShoppingRecipesRefsTable(_$ShoppingDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.localShoppingRecipes,
        aliasName: $_aliasNameGenerator(
          db.localShoppingLists.id,
          db.localShoppingRecipes.listId,
        ),
      );

  $$LocalShoppingRecipesTableProcessedTableManager
  get localShoppingRecipesRefs {
    final manager = $$LocalShoppingRecipesTableTableManager(
      $_db,
      $_db.localShoppingRecipes,
    ).filter((f) => f.listId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _localShoppingRecipesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LocalShoppingListsTableFilterComposer
    extends Composer<_$ShoppingDatabase, $LocalShoppingListsTable> {
  $$LocalShoppingListsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> localShoppingItemsRefs(
    Expression<bool> Function($$LocalShoppingItemsTableFilterComposer f) f,
  ) {
    final $$LocalShoppingItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.localShoppingItems,
      getReferencedColumn: (t) => t.listId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalShoppingItemsTableFilterComposer(
            $db: $db,
            $table: $db.localShoppingItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> localShoppingRecipesRefs(
    Expression<bool> Function($$LocalShoppingRecipesTableFilterComposer f) f,
  ) {
    final $$LocalShoppingRecipesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.localShoppingRecipes,
      getReferencedColumn: (t) => t.listId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalShoppingRecipesTableFilterComposer(
            $db: $db,
            $table: $db.localShoppingRecipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LocalShoppingListsTableOrderingComposer
    extends Composer<_$ShoppingDatabase, $LocalShoppingListsTable> {
  $$LocalShoppingListsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalShoppingListsTableAnnotationComposer
    extends Composer<_$ShoppingDatabase, $LocalShoppingListsTable> {
  $$LocalShoppingListsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  Expression<T> localShoppingItemsRefs<T extends Object>(
    Expression<T> Function($$LocalShoppingItemsTableAnnotationComposer a) f,
  ) {
    final $$LocalShoppingItemsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.localShoppingItems,
          getReferencedColumn: (t) => t.listId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LocalShoppingItemsTableAnnotationComposer(
                $db: $db,
                $table: $db.localShoppingItems,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> localShoppingRecipesRefs<T extends Object>(
    Expression<T> Function($$LocalShoppingRecipesTableAnnotationComposer a) f,
  ) {
    final $$LocalShoppingRecipesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.localShoppingRecipes,
          getReferencedColumn: (t) => t.listId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LocalShoppingRecipesTableAnnotationComposer(
                $db: $db,
                $table: $db.localShoppingRecipes,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$LocalShoppingListsTableTableManager
    extends
        RootTableManager<
          _$ShoppingDatabase,
          $LocalShoppingListsTable,
          LocalShoppingList,
          $$LocalShoppingListsTableFilterComposer,
          $$LocalShoppingListsTableOrderingComposer,
          $$LocalShoppingListsTableAnnotationComposer,
          $$LocalShoppingListsTableCreateCompanionBuilder,
          $$LocalShoppingListsTableUpdateCompanionBuilder,
          (LocalShoppingList, $$LocalShoppingListsTableReferences),
          LocalShoppingList,
          PrefetchHooks Function({
            bool localShoppingItemsRefs,
            bool localShoppingRecipesRefs,
          })
        > {
  $$LocalShoppingListsTableTableManager(
    _$ShoppingDatabase db,
    $LocalShoppingListsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalShoppingListsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalShoppingListsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalShoppingListsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<DateTime> clientUpdatedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalShoppingListsCompanion(
                id: id,
                name: name,
                isArchived: isArchived,
                clientUpdatedAt: clientUpdatedAt,
                createdAt: createdAt,
                deleted: deleted,
                syncState: syncState,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<bool> isArchived = const Value.absent(),
                required DateTime clientUpdatedAt,
                required DateTime createdAt,
                Value<bool> deleted = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalShoppingListsCompanion.insert(
                id: id,
                name: name,
                isArchived: isArchived,
                clientUpdatedAt: clientUpdatedAt,
                createdAt: createdAt,
                deleted: deleted,
                syncState: syncState,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LocalShoppingListsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                localShoppingItemsRefs = false,
                localShoppingRecipesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (localShoppingItemsRefs) db.localShoppingItems,
                    if (localShoppingRecipesRefs) db.localShoppingRecipes,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (localShoppingItemsRefs)
                        await $_getPrefetchedData<
                          LocalShoppingList,
                          $LocalShoppingListsTable,
                          LocalShoppingItem
                        >(
                          currentTable: table,
                          referencedTable: $$LocalShoppingListsTableReferences
                              ._localShoppingItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LocalShoppingListsTableReferences(
                                db,
                                table,
                                p0,
                              ).localShoppingItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.listId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (localShoppingRecipesRefs)
                        await $_getPrefetchedData<
                          LocalShoppingList,
                          $LocalShoppingListsTable,
                          LocalShoppingRecipe
                        >(
                          currentTable: table,
                          referencedTable: $$LocalShoppingListsTableReferences
                              ._localShoppingRecipesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LocalShoppingListsTableReferences(
                                db,
                                table,
                                p0,
                              ).localShoppingRecipesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.listId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$LocalShoppingListsTableProcessedTableManager =
    ProcessedTableManager<
      _$ShoppingDatabase,
      $LocalShoppingListsTable,
      LocalShoppingList,
      $$LocalShoppingListsTableFilterComposer,
      $$LocalShoppingListsTableOrderingComposer,
      $$LocalShoppingListsTableAnnotationComposer,
      $$LocalShoppingListsTableCreateCompanionBuilder,
      $$LocalShoppingListsTableUpdateCompanionBuilder,
      (LocalShoppingList, $$LocalShoppingListsTableReferences),
      LocalShoppingList,
      PrefetchHooks Function({
        bool localShoppingItemsRefs,
        bool localShoppingRecipesRefs,
      })
    >;
typedef $$LocalShoppingItemsTableCreateCompanionBuilder =
    LocalShoppingItemsCompanion Function({
      required String id,
      required String listId,
      Value<String?> ingredientId,
      Value<String?> customLabel,
      required String name,
      Value<double?> quantity,
      Value<String?> unit,
      Value<bool> isChecked,
      Value<String?> replacedByAlternativeId,
      Value<String?> replacementName,
      Value<String> sourcesJson,
      Value<int> position,
      required DateTime clientUpdatedAt,
      Value<bool> deleted,
      Value<String> syncState,
      Value<int> rowid,
    });
typedef $$LocalShoppingItemsTableUpdateCompanionBuilder =
    LocalShoppingItemsCompanion Function({
      Value<String> id,
      Value<String> listId,
      Value<String?> ingredientId,
      Value<String?> customLabel,
      Value<String> name,
      Value<double?> quantity,
      Value<String?> unit,
      Value<bool> isChecked,
      Value<String?> replacedByAlternativeId,
      Value<String?> replacementName,
      Value<String> sourcesJson,
      Value<int> position,
      Value<DateTime> clientUpdatedAt,
      Value<bool> deleted,
      Value<String> syncState,
      Value<int> rowid,
    });

final class $$LocalShoppingItemsTableReferences
    extends
        BaseReferences<
          _$ShoppingDatabase,
          $LocalShoppingItemsTable,
          LocalShoppingItem
        > {
  $$LocalShoppingItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LocalShoppingListsTable _listIdTable(_$ShoppingDatabase db) =>
      db.localShoppingLists.createAlias(
        $_aliasNameGenerator(
          db.localShoppingItems.listId,
          db.localShoppingLists.id,
        ),
      );

  $$LocalShoppingListsTableProcessedTableManager get listId {
    final $_column = $_itemColumn<String>('list_id')!;

    final manager = $$LocalShoppingListsTableTableManager(
      $_db,
      $_db.localShoppingLists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_listIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LocalShoppingItemsTableFilterComposer
    extends Composer<_$ShoppingDatabase, $LocalShoppingItemsTable> {
  $$LocalShoppingItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ingredientId => $composableBuilder(
    column: $table.ingredientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customLabel => $composableBuilder(
    column: $table.customLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isChecked => $composableBuilder(
    column: $table.isChecked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get replacedByAlternativeId => $composableBuilder(
    column: $table.replacedByAlternativeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get replacementName => $composableBuilder(
    column: $table.replacementName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourcesJson => $composableBuilder(
    column: $table.sourcesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnFilters(column),
  );

  $$LocalShoppingListsTableFilterComposer get listId {
    final $$LocalShoppingListsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listId,
      referencedTable: $db.localShoppingLists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalShoppingListsTableFilterComposer(
            $db: $db,
            $table: $db.localShoppingLists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalShoppingItemsTableOrderingComposer
    extends Composer<_$ShoppingDatabase, $LocalShoppingItemsTable> {
  $$LocalShoppingItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ingredientId => $composableBuilder(
    column: $table.ingredientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customLabel => $composableBuilder(
    column: $table.customLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isChecked => $composableBuilder(
    column: $table.isChecked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get replacedByAlternativeId => $composableBuilder(
    column: $table.replacedByAlternativeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get replacementName => $composableBuilder(
    column: $table.replacementName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourcesJson => $composableBuilder(
    column: $table.sourcesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocalShoppingListsTableOrderingComposer get listId {
    final $$LocalShoppingListsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listId,
      referencedTable: $db.localShoppingLists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalShoppingListsTableOrderingComposer(
            $db: $db,
            $table: $db.localShoppingLists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalShoppingItemsTableAnnotationComposer
    extends Composer<_$ShoppingDatabase, $LocalShoppingItemsTable> {
  $$LocalShoppingItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ingredientId => $composableBuilder(
    column: $table.ingredientId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customLabel => $composableBuilder(
    column: $table.customLabel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<bool> get isChecked =>
      $composableBuilder(column: $table.isChecked, builder: (column) => column);

  GeneratedColumn<String> get replacedByAlternativeId => $composableBuilder(
    column: $table.replacedByAlternativeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get replacementName => $composableBuilder(
    column: $table.replacementName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourcesJson => $composableBuilder(
    column: $table.sourcesJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  $$LocalShoppingListsTableAnnotationComposer get listId {
    final $$LocalShoppingListsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.listId,
          referencedTable: $db.localShoppingLists,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LocalShoppingListsTableAnnotationComposer(
                $db: $db,
                $table: $db.localShoppingLists,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$LocalShoppingItemsTableTableManager
    extends
        RootTableManager<
          _$ShoppingDatabase,
          $LocalShoppingItemsTable,
          LocalShoppingItem,
          $$LocalShoppingItemsTableFilterComposer,
          $$LocalShoppingItemsTableOrderingComposer,
          $$LocalShoppingItemsTableAnnotationComposer,
          $$LocalShoppingItemsTableCreateCompanionBuilder,
          $$LocalShoppingItemsTableUpdateCompanionBuilder,
          (LocalShoppingItem, $$LocalShoppingItemsTableReferences),
          LocalShoppingItem,
          PrefetchHooks Function({bool listId})
        > {
  $$LocalShoppingItemsTableTableManager(
    _$ShoppingDatabase db,
    $LocalShoppingItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalShoppingItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalShoppingItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalShoppingItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> listId = const Value.absent(),
                Value<String?> ingredientId = const Value.absent(),
                Value<String?> customLabel = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double?> quantity = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<bool> isChecked = const Value.absent(),
                Value<String?> replacedByAlternativeId = const Value.absent(),
                Value<String?> replacementName = const Value.absent(),
                Value<String> sourcesJson = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<DateTime> clientUpdatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalShoppingItemsCompanion(
                id: id,
                listId: listId,
                ingredientId: ingredientId,
                customLabel: customLabel,
                name: name,
                quantity: quantity,
                unit: unit,
                isChecked: isChecked,
                replacedByAlternativeId: replacedByAlternativeId,
                replacementName: replacementName,
                sourcesJson: sourcesJson,
                position: position,
                clientUpdatedAt: clientUpdatedAt,
                deleted: deleted,
                syncState: syncState,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String listId,
                Value<String?> ingredientId = const Value.absent(),
                Value<String?> customLabel = const Value.absent(),
                required String name,
                Value<double?> quantity = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<bool> isChecked = const Value.absent(),
                Value<String?> replacedByAlternativeId = const Value.absent(),
                Value<String?> replacementName = const Value.absent(),
                Value<String> sourcesJson = const Value.absent(),
                Value<int> position = const Value.absent(),
                required DateTime clientUpdatedAt,
                Value<bool> deleted = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalShoppingItemsCompanion.insert(
                id: id,
                listId: listId,
                ingredientId: ingredientId,
                customLabel: customLabel,
                name: name,
                quantity: quantity,
                unit: unit,
                isChecked: isChecked,
                replacedByAlternativeId: replacedByAlternativeId,
                replacementName: replacementName,
                sourcesJson: sourcesJson,
                position: position,
                clientUpdatedAt: clientUpdatedAt,
                deleted: deleted,
                syncState: syncState,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LocalShoppingItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({listId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (listId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.listId,
                                referencedTable:
                                    $$LocalShoppingItemsTableReferences
                                        ._listIdTable(db),
                                referencedColumn:
                                    $$LocalShoppingItemsTableReferences
                                        ._listIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LocalShoppingItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$ShoppingDatabase,
      $LocalShoppingItemsTable,
      LocalShoppingItem,
      $$LocalShoppingItemsTableFilterComposer,
      $$LocalShoppingItemsTableOrderingComposer,
      $$LocalShoppingItemsTableAnnotationComposer,
      $$LocalShoppingItemsTableCreateCompanionBuilder,
      $$LocalShoppingItemsTableUpdateCompanionBuilder,
      (LocalShoppingItem, $$LocalShoppingItemsTableReferences),
      LocalShoppingItem,
      PrefetchHooks Function({bool listId})
    >;
typedef $$LocalShoppingRecipesTableCreateCompanionBuilder =
    LocalShoppingRecipesCompanion Function({
      required String listId,
      required String recipeId,
      required String recipeName,
      Value<String?> photoUrl,
      required int servings,
      Value<int> rowid,
    });
typedef $$LocalShoppingRecipesTableUpdateCompanionBuilder =
    LocalShoppingRecipesCompanion Function({
      Value<String> listId,
      Value<String> recipeId,
      Value<String> recipeName,
      Value<String?> photoUrl,
      Value<int> servings,
      Value<int> rowid,
    });

final class $$LocalShoppingRecipesTableReferences
    extends
        BaseReferences<
          _$ShoppingDatabase,
          $LocalShoppingRecipesTable,
          LocalShoppingRecipe
        > {
  $$LocalShoppingRecipesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LocalShoppingListsTable _listIdTable(_$ShoppingDatabase db) =>
      db.localShoppingLists.createAlias(
        $_aliasNameGenerator(
          db.localShoppingRecipes.listId,
          db.localShoppingLists.id,
        ),
      );

  $$LocalShoppingListsTableProcessedTableManager get listId {
    final $_column = $_itemColumn<String>('list_id')!;

    final manager = $$LocalShoppingListsTableTableManager(
      $_db,
      $_db.localShoppingLists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_listIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LocalShoppingRecipesTableFilterComposer
    extends Composer<_$ShoppingDatabase, $LocalShoppingRecipesTable> {
  $$LocalShoppingRecipesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get recipeId => $composableBuilder(
    column: $table.recipeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recipeName => $composableBuilder(
    column: $table.recipeName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoUrl => $composableBuilder(
    column: $table.photoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get servings => $composableBuilder(
    column: $table.servings,
    builder: (column) => ColumnFilters(column),
  );

  $$LocalShoppingListsTableFilterComposer get listId {
    final $$LocalShoppingListsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listId,
      referencedTable: $db.localShoppingLists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalShoppingListsTableFilterComposer(
            $db: $db,
            $table: $db.localShoppingLists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalShoppingRecipesTableOrderingComposer
    extends Composer<_$ShoppingDatabase, $LocalShoppingRecipesTable> {
  $$LocalShoppingRecipesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get recipeId => $composableBuilder(
    column: $table.recipeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recipeName => $composableBuilder(
    column: $table.recipeName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoUrl => $composableBuilder(
    column: $table.photoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get servings => $composableBuilder(
    column: $table.servings,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocalShoppingListsTableOrderingComposer get listId {
    final $$LocalShoppingListsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listId,
      referencedTable: $db.localShoppingLists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalShoppingListsTableOrderingComposer(
            $db: $db,
            $table: $db.localShoppingLists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalShoppingRecipesTableAnnotationComposer
    extends Composer<_$ShoppingDatabase, $LocalShoppingRecipesTable> {
  $$LocalShoppingRecipesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get recipeId =>
      $composableBuilder(column: $table.recipeId, builder: (column) => column);

  GeneratedColumn<String> get recipeName => $composableBuilder(
    column: $table.recipeName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get photoUrl =>
      $composableBuilder(column: $table.photoUrl, builder: (column) => column);

  GeneratedColumn<int> get servings =>
      $composableBuilder(column: $table.servings, builder: (column) => column);

  $$LocalShoppingListsTableAnnotationComposer get listId {
    final $$LocalShoppingListsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.listId,
          referencedTable: $db.localShoppingLists,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LocalShoppingListsTableAnnotationComposer(
                $db: $db,
                $table: $db.localShoppingLists,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$LocalShoppingRecipesTableTableManager
    extends
        RootTableManager<
          _$ShoppingDatabase,
          $LocalShoppingRecipesTable,
          LocalShoppingRecipe,
          $$LocalShoppingRecipesTableFilterComposer,
          $$LocalShoppingRecipesTableOrderingComposer,
          $$LocalShoppingRecipesTableAnnotationComposer,
          $$LocalShoppingRecipesTableCreateCompanionBuilder,
          $$LocalShoppingRecipesTableUpdateCompanionBuilder,
          (LocalShoppingRecipe, $$LocalShoppingRecipesTableReferences),
          LocalShoppingRecipe,
          PrefetchHooks Function({bool listId})
        > {
  $$LocalShoppingRecipesTableTableManager(
    _$ShoppingDatabase db,
    $LocalShoppingRecipesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalShoppingRecipesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalShoppingRecipesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalShoppingRecipesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> listId = const Value.absent(),
                Value<String> recipeId = const Value.absent(),
                Value<String> recipeName = const Value.absent(),
                Value<String?> photoUrl = const Value.absent(),
                Value<int> servings = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalShoppingRecipesCompanion(
                listId: listId,
                recipeId: recipeId,
                recipeName: recipeName,
                photoUrl: photoUrl,
                servings: servings,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String listId,
                required String recipeId,
                required String recipeName,
                Value<String?> photoUrl = const Value.absent(),
                required int servings,
                Value<int> rowid = const Value.absent(),
              }) => LocalShoppingRecipesCompanion.insert(
                listId: listId,
                recipeId: recipeId,
                recipeName: recipeName,
                photoUrl: photoUrl,
                servings: servings,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LocalShoppingRecipesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({listId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (listId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.listId,
                                referencedTable:
                                    $$LocalShoppingRecipesTableReferences
                                        ._listIdTable(db),
                                referencedColumn:
                                    $$LocalShoppingRecipesTableReferences
                                        ._listIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LocalShoppingRecipesTableProcessedTableManager =
    ProcessedTableManager<
      _$ShoppingDatabase,
      $LocalShoppingRecipesTable,
      LocalShoppingRecipe,
      $$LocalShoppingRecipesTableFilterComposer,
      $$LocalShoppingRecipesTableOrderingComposer,
      $$LocalShoppingRecipesTableAnnotationComposer,
      $$LocalShoppingRecipesTableCreateCompanionBuilder,
      $$LocalShoppingRecipesTableUpdateCompanionBuilder,
      (LocalShoppingRecipe, $$LocalShoppingRecipesTableReferences),
      LocalShoppingRecipe,
      PrefetchHooks Function({bool listId})
    >;

class $ShoppingDatabaseManager {
  final _$ShoppingDatabase _db;
  $ShoppingDatabaseManager(this._db);
  $$LocalShoppingListsTableTableManager get localShoppingLists =>
      $$LocalShoppingListsTableTableManager(_db, _db.localShoppingLists);
  $$LocalShoppingItemsTableTableManager get localShoppingItems =>
      $$LocalShoppingItemsTableTableManager(_db, _db.localShoppingItems);
  $$LocalShoppingRecipesTableTableManager get localShoppingRecipes =>
      $$LocalShoppingRecipesTableTableManager(_db, _db.localShoppingRecipes);
}
