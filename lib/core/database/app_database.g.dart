// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $MnemataItemsTable extends MnemataItems
    with TableInfo<$MnemataItemsTable, MnemataItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MnemataItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  static const VerificationMeta _lastOpenedAtMeta = const VerificationMeta(
    'lastOpenedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastOpenedAt = GeneratedColumn<DateTime>(
    'last_opened_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    url,
    filePath,
    content,
    type,
    createdAt,
    lastOpenedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mnemata_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<MnemataItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_opened_at')) {
      context.handle(
        _lastOpenedAtMeta,
        lastOpenedAt.isAcceptableOrUnknown(
          data['last_opened_at']!,
          _lastOpenedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MnemataItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MnemataItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      ),
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      ),
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastOpenedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_opened_at'],
      ),
    );
  }

  @override
  $MnemataItemsTable createAlias(String alias) {
    return $MnemataItemsTable(attachedDatabase, alias);
  }
}

class MnemataItem extends DataClass implements Insertable<MnemataItem> {
  final int id;
  final String? title;
  final String? url;
  final String? filePath;
  final String? content;
  final String type;
  final DateTime createdAt;
  final DateTime? lastOpenedAt;
  const MnemataItem({
    required this.id,
    this.title,
    this.url,
    this.filePath,
    this.content,
    required this.type,
    required this.createdAt,
    this.lastOpenedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    if (!nullToAbsent || filePath != null) {
      map['file_path'] = Variable<String>(filePath);
    }
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    map['type'] = Variable<String>(type);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || lastOpenedAt != null) {
      map['last_opened_at'] = Variable<DateTime>(lastOpenedAt);
    }
    return map;
  }

  MnemataItemsCompanion toCompanion(bool nullToAbsent) {
    return MnemataItemsCompanion(
      id: Value(id),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
      filePath: filePath == null && nullToAbsent
          ? const Value.absent()
          : Value(filePath),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      type: Value(type),
      createdAt: Value(createdAt),
      lastOpenedAt: lastOpenedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastOpenedAt),
    );
  }

  factory MnemataItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MnemataItem(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String?>(json['title']),
      url: serializer.fromJson<String?>(json['url']),
      filePath: serializer.fromJson<String?>(json['filePath']),
      content: serializer.fromJson<String?>(json['content']),
      type: serializer.fromJson<String>(json['type']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastOpenedAt: serializer.fromJson<DateTime?>(json['lastOpenedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String?>(title),
      'url': serializer.toJson<String?>(url),
      'filePath': serializer.toJson<String?>(filePath),
      'content': serializer.toJson<String?>(content),
      'type': serializer.toJson<String>(type),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastOpenedAt': serializer.toJson<DateTime?>(lastOpenedAt),
    };
  }

  MnemataItem copyWith({
    int? id,
    Value<String?> title = const Value.absent(),
    Value<String?> url = const Value.absent(),
    Value<String?> filePath = const Value.absent(),
    Value<String?> content = const Value.absent(),
    String? type,
    DateTime? createdAt,
    Value<DateTime?> lastOpenedAt = const Value.absent(),
  }) => MnemataItem(
    id: id ?? this.id,
    title: title.present ? title.value : this.title,
    url: url.present ? url.value : this.url,
    filePath: filePath.present ? filePath.value : this.filePath,
    content: content.present ? content.value : this.content,
    type: type ?? this.type,
    createdAt: createdAt ?? this.createdAt,
    lastOpenedAt: lastOpenedAt.present ? lastOpenedAt.value : this.lastOpenedAt,
  );
  MnemataItem copyWithCompanion(MnemataItemsCompanion data) {
    return MnemataItem(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      url: data.url.present ? data.url.value : this.url,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      content: data.content.present ? data.content.value : this.content,
      type: data.type.present ? data.type.value : this.type,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastOpenedAt: data.lastOpenedAt.present
          ? data.lastOpenedAt.value
          : this.lastOpenedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MnemataItem(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('url: $url, ')
          ..write('filePath: $filePath, ')
          ..write('content: $content, ')
          ..write('type: $type, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastOpenedAt: $lastOpenedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    url,
    filePath,
    content,
    type,
    createdAt,
    lastOpenedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MnemataItem &&
          other.id == this.id &&
          other.title == this.title &&
          other.url == this.url &&
          other.filePath == this.filePath &&
          other.content == this.content &&
          other.type == this.type &&
          other.createdAt == this.createdAt &&
          other.lastOpenedAt == this.lastOpenedAt);
}

class MnemataItemsCompanion extends UpdateCompanion<MnemataItem> {
  final Value<int> id;
  final Value<String?> title;
  final Value<String?> url;
  final Value<String?> filePath;
  final Value<String?> content;
  final Value<String> type;
  final Value<DateTime> createdAt;
  final Value<DateTime?> lastOpenedAt;
  const MnemataItemsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.url = const Value.absent(),
    this.filePath = const Value.absent(),
    this.content = const Value.absent(),
    this.type = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastOpenedAt = const Value.absent(),
  });
  MnemataItemsCompanion.insert({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.url = const Value.absent(),
    this.filePath = const Value.absent(),
    this.content = const Value.absent(),
    required String type,
    required DateTime createdAt,
    this.lastOpenedAt = const Value.absent(),
  }) : type = Value(type),
       createdAt = Value(createdAt);
  static Insertable<MnemataItem> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? url,
    Expression<String>? filePath,
    Expression<String>? content,
    Expression<String>? type,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastOpenedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (url != null) 'url': url,
      if (filePath != null) 'file_path': filePath,
      if (content != null) 'content': content,
      if (type != null) 'type': type,
      if (createdAt != null) 'created_at': createdAt,
      if (lastOpenedAt != null) 'last_opened_at': lastOpenedAt,
    });
  }

  MnemataItemsCompanion copyWith({
    Value<int>? id,
    Value<String?>? title,
    Value<String?>? url,
    Value<String?>? filePath,
    Value<String?>? content,
    Value<String>? type,
    Value<DateTime>? createdAt,
    Value<DateTime?>? lastOpenedAt,
  }) {
    return MnemataItemsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      filePath: filePath ?? this.filePath,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastOpenedAt.present) {
      map['last_opened_at'] = Variable<DateTime>(lastOpenedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MnemataItemsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('url: $url, ')
          ..write('filePath: $filePath, ')
          ..write('content: $content, ')
          ..write('type: $type, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastOpenedAt: $lastOpenedAt')
          ..write(')'))
        .toString();
  }
}

class MnemataSearch extends Table
    with
        TableInfo<MnemataSearch, MnemataSearchData>,
        VirtualTableInfo<MnemataSearch, MnemataSearchData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  MnemataSearch(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: '',
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [title, content];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mnemata_search';
  @override
  VerificationContext validateIntegrity(
    Insertable<MnemataSearchData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  MnemataSearchData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MnemataSearchData(
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
    );
  }

  @override
  MnemataSearch createAlias(String alias) {
    return MnemataSearch(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
  @override
  String get moduleAndArgs =>
      'fts5(title, content, content=\'mnemata_items\', content_rowid=\'id\', tokenize=\'porter\')';
}

class MnemataSearchData extends DataClass
    implements Insertable<MnemataSearchData> {
  final String title;
  final String content;
  const MnemataSearchData({required this.title, required this.content});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['title'] = Variable<String>(title);
    map['content'] = Variable<String>(content);
    return map;
  }

  MnemataSearchCompanion toCompanion(bool nullToAbsent) {
    return MnemataSearchCompanion(title: Value(title), content: Value(content));
  }

  factory MnemataSearchData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MnemataSearchData(
      title: serializer.fromJson<String>(json['title']),
      content: serializer.fromJson<String>(json['content']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'title': serializer.toJson<String>(title),
      'content': serializer.toJson<String>(content),
    };
  }

  MnemataSearchData copyWith({String? title, String? content}) =>
      MnemataSearchData(
        title: title ?? this.title,
        content: content ?? this.content,
      );
  MnemataSearchData copyWithCompanion(MnemataSearchCompanion data) {
    return MnemataSearchData(
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MnemataSearchData(')
          ..write('title: $title, ')
          ..write('content: $content')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(title, content);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MnemataSearchData &&
          other.title == this.title &&
          other.content == this.content);
}

class MnemataSearchCompanion extends UpdateCompanion<MnemataSearchData> {
  final Value<String> title;
  final Value<String> content;
  final Value<int> rowid;
  const MnemataSearchCompanion({
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MnemataSearchCompanion.insert({
    required String title,
    required String content,
    this.rowid = const Value.absent(),
  }) : title = Value(title),
       content = Value(content);
  static Insertable<MnemataSearchData> custom({
    Expression<String>? title,
    Expression<String>? content,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MnemataSearchCompanion copyWith({
    Value<String>? title,
    Value<String>? content,
    Value<int>? rowid,
  }) {
    return MnemataSearchCompanion(
      title: title ?? this.title,
      content: content ?? this.content,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MnemataSearchCompanion(')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LabelsTable extends Labels with TableInfo<$LabelsTable, Label> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LabelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
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
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<int> parentId = GeneratedColumn<int>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES labels (id)',
    ),
  );
  static const VerificationMeta _isFolderMeta = const VerificationMeta(
    'isFolder',
  );
  @override
  late final GeneratedColumn<bool> isFolder = GeneratedColumn<bool>(
    'is_folder',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_folder" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, color, parentId, isFolder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'labels';
  @override
  VerificationContext validateIntegrity(
    Insertable<Label> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('is_folder')) {
      context.handle(
        _isFolderMeta,
        isFolder.isAcceptableOrUnknown(data['is_folder']!, _isFolderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Label map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Label(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      ),
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}parent_id'],
      ),
      isFolder: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_folder'],
      )!,
    );
  }

  @override
  $LabelsTable createAlias(String alias) {
    return $LabelsTable(attachedDatabase, alias);
  }
}

class Label extends DataClass implements Insertable<Label> {
  final int id;
  final String name;
  final int? color;
  final int? parentId;
  final bool isFolder;
  const Label({
    required this.id,
    required this.name,
    this.color,
    this.parentId,
    required this.isFolder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<int>(color);
    }
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<int>(parentId);
    }
    map['is_folder'] = Variable<bool>(isFolder);
    return map;
  }

  LabelsCompanion toCompanion(bool nullToAbsent) {
    return LabelsCompanion(
      id: Value(id),
      name: Value(name),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      isFolder: Value(isFolder),
    );
  }

  factory Label.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Label(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<int?>(json['color']),
      parentId: serializer.fromJson<int?>(json['parentId']),
      isFolder: serializer.fromJson<bool>(json['isFolder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<int?>(color),
      'parentId': serializer.toJson<int?>(parentId),
      'isFolder': serializer.toJson<bool>(isFolder),
    };
  }

  Label copyWith({
    int? id,
    String? name,
    Value<int?> color = const Value.absent(),
    Value<int?> parentId = const Value.absent(),
    bool? isFolder,
  }) => Label(
    id: id ?? this.id,
    name: name ?? this.name,
    color: color.present ? color.value : this.color,
    parentId: parentId.present ? parentId.value : this.parentId,
    isFolder: isFolder ?? this.isFolder,
  );
  Label copyWithCompanion(LabelsCompanion data) {
    return Label(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      isFolder: data.isFolder.present ? data.isFolder.value : this.isFolder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Label(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('parentId: $parentId, ')
          ..write('isFolder: $isFolder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, color, parentId, isFolder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Label &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color &&
          other.parentId == this.parentId &&
          other.isFolder == this.isFolder);
}

class LabelsCompanion extends UpdateCompanion<Label> {
  final Value<int> id;
  final Value<String> name;
  final Value<int?> color;
  final Value<int?> parentId;
  final Value<bool> isFolder;
  const LabelsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.parentId = const Value.absent(),
    this.isFolder = const Value.absent(),
  });
  LabelsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.color = const Value.absent(),
    this.parentId = const Value.absent(),
    this.isFolder = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Label> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? color,
    Expression<int>? parentId,
    Expression<bool>? isFolder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (parentId != null) 'parent_id': parentId,
      if (isFolder != null) 'is_folder': isFolder,
    });
  }

  LabelsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int?>? color,
    Value<int?>? parentId,
    Value<bool>? isFolder,
  }) {
    return LabelsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      parentId: parentId ?? this.parentId,
      isFolder: isFolder ?? this.isFolder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<int>(parentId.value);
    }
    if (isFolder.present) {
      map['is_folder'] = Variable<bool>(isFolder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LabelsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('parentId: $parentId, ')
          ..write('isFolder: $isFolder')
          ..write(')'))
        .toString();
  }
}

class $ItemLabelsTable extends ItemLabels
    with TableInfo<$ItemLabelsTable, ItemLabel> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemLabelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES mnemata_items (id)',
    ),
  );
  static const VerificationMeta _labelIdMeta = const VerificationMeta(
    'labelId',
  );
  @override
  late final GeneratedColumn<int> labelId = GeneratedColumn<int>(
    'label_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES labels (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [itemId, labelId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'item_labels';
  @override
  VerificationContext validateIntegrity(
    Insertable<ItemLabel> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('label_id')) {
      context.handle(
        _labelIdMeta,
        labelId.isAcceptableOrUnknown(data['label_id']!, _labelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_labelIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {itemId, labelId};
  @override
  ItemLabel map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemLabel(
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_id'],
      )!,
      labelId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}label_id'],
      )!,
    );
  }

  @override
  $ItemLabelsTable createAlias(String alias) {
    return $ItemLabelsTable(attachedDatabase, alias);
  }
}

class ItemLabel extends DataClass implements Insertable<ItemLabel> {
  final int itemId;
  final int labelId;
  const ItemLabel({required this.itemId, required this.labelId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['item_id'] = Variable<int>(itemId);
    map['label_id'] = Variable<int>(labelId);
    return map;
  }

  ItemLabelsCompanion toCompanion(bool nullToAbsent) {
    return ItemLabelsCompanion(itemId: Value(itemId), labelId: Value(labelId));
  }

  factory ItemLabel.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemLabel(
      itemId: serializer.fromJson<int>(json['itemId']),
      labelId: serializer.fromJson<int>(json['labelId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'itemId': serializer.toJson<int>(itemId),
      'labelId': serializer.toJson<int>(labelId),
    };
  }

  ItemLabel copyWith({int? itemId, int? labelId}) => ItemLabel(
    itemId: itemId ?? this.itemId,
    labelId: labelId ?? this.labelId,
  );
  ItemLabel copyWithCompanion(ItemLabelsCompanion data) {
    return ItemLabel(
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      labelId: data.labelId.present ? data.labelId.value : this.labelId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemLabel(')
          ..write('itemId: $itemId, ')
          ..write('labelId: $labelId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(itemId, labelId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemLabel &&
          other.itemId == this.itemId &&
          other.labelId == this.labelId);
}

class ItemLabelsCompanion extends UpdateCompanion<ItemLabel> {
  final Value<int> itemId;
  final Value<int> labelId;
  final Value<int> rowid;
  const ItemLabelsCompanion({
    this.itemId = const Value.absent(),
    this.labelId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItemLabelsCompanion.insert({
    required int itemId,
    required int labelId,
    this.rowid = const Value.absent(),
  }) : itemId = Value(itemId),
       labelId = Value(labelId);
  static Insertable<ItemLabel> custom({
    Expression<int>? itemId,
    Expression<int>? labelId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (itemId != null) 'item_id': itemId,
      if (labelId != null) 'label_id': labelId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItemLabelsCompanion copyWith({
    Value<int>? itemId,
    Value<int>? labelId,
    Value<int>? rowid,
  }) {
    return ItemLabelsCompanion(
      itemId: itemId ?? this.itemId,
      labelId: labelId ?? this.labelId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (labelId.present) {
      map['label_id'] = Variable<int>(labelId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemLabelsCompanion(')
          ..write('itemId: $itemId, ')
          ..write('labelId: $labelId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MnemataItemsTable mnemataItems = $MnemataItemsTable(this);
  late final MnemataSearch mnemataSearch = MnemataSearch(this);
  late final Trigger mnemataItemsAi = Trigger(
    'CREATE TRIGGER mnemata_items_ai AFTER INSERT ON mnemata_items BEGIN INSERT INTO mnemata_search ("rowid", title, content) VALUES (new.id, new.title, new.content);END',
    'mnemata_items_ai',
  );
  late final Trigger mnemataItemsAd = Trigger(
    'CREATE TRIGGER mnemata_items_ad AFTER DELETE ON mnemata_items BEGIN INSERT INTO mnemata_search (mnemata_search, "rowid", title, content) VALUES (\'delete\', old.id, old.title, old.content);END',
    'mnemata_items_ad',
  );
  late final Trigger mnemataItemsAu = Trigger(
    'CREATE TRIGGER mnemata_items_au AFTER UPDATE ON mnemata_items BEGIN INSERT INTO mnemata_search (mnemata_search, "rowid", title, content) VALUES (\'delete\', old.id, old.title, old.content);INSERT INTO mnemata_search ("rowid", title, content) VALUES (new.id, new.title, new.content);END',
    'mnemata_items_au',
  );
  late final $LabelsTable labels = $LabelsTable(this);
  late final $ItemLabelsTable itemLabels = $ItemLabelsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    mnemataItems,
    mnemataSearch,
    mnemataItemsAi,
    mnemataItemsAd,
    mnemataItemsAu,
    labels,
    itemLabels,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'mnemata_items',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [TableUpdate('mnemata_search', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'mnemata_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('mnemata_search', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'mnemata_items',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('mnemata_search', kind: UpdateKind.insert)],
    ),
  ]);
}

typedef $$MnemataItemsTableCreateCompanionBuilder =
    MnemataItemsCompanion Function({
      Value<int> id,
      Value<String?> title,
      Value<String?> url,
      Value<String?> filePath,
      Value<String?> content,
      required String type,
      required DateTime createdAt,
      Value<DateTime?> lastOpenedAt,
    });
typedef $$MnemataItemsTableUpdateCompanionBuilder =
    MnemataItemsCompanion Function({
      Value<int> id,
      Value<String?> title,
      Value<String?> url,
      Value<String?> filePath,
      Value<String?> content,
      Value<String> type,
      Value<DateTime> createdAt,
      Value<DateTime?> lastOpenedAt,
    });

final class $$MnemataItemsTableReferences
    extends BaseReferences<_$AppDatabase, $MnemataItemsTable, MnemataItem> {
  $$MnemataItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ItemLabelsTable, List<ItemLabel>>
  _itemLabelsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.itemLabels,
    aliasName: $_aliasNameGenerator(db.mnemataItems.id, db.itemLabels.itemId),
  );

  $$ItemLabelsTableProcessedTableManager get itemLabelsRefs {
    final manager = $$ItemLabelsTableTableManager(
      $_db,
      $_db.itemLabels,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_itemLabelsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MnemataItemsTableFilterComposer
    extends Composer<_$AppDatabase, $MnemataItemsTable> {
  $$MnemataItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> itemLabelsRefs(
    Expression<bool> Function($$ItemLabelsTableFilterComposer f) f,
  ) {
    final $$ItemLabelsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.itemLabels,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemLabelsTableFilterComposer(
            $db: $db,
            $table: $db.itemLabels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MnemataItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $MnemataItemsTable> {
  $$MnemataItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MnemataItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MnemataItemsTable> {
  $$MnemataItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => column,
  );

  Expression<T> itemLabelsRefs<T extends Object>(
    Expression<T> Function($$ItemLabelsTableAnnotationComposer a) f,
  ) {
    final $$ItemLabelsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.itemLabels,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemLabelsTableAnnotationComposer(
            $db: $db,
            $table: $db.itemLabels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MnemataItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MnemataItemsTable,
          MnemataItem,
          $$MnemataItemsTableFilterComposer,
          $$MnemataItemsTableOrderingComposer,
          $$MnemataItemsTableAnnotationComposer,
          $$MnemataItemsTableCreateCompanionBuilder,
          $$MnemataItemsTableUpdateCompanionBuilder,
          (MnemataItem, $$MnemataItemsTableReferences),
          MnemataItem,
          PrefetchHooks Function({bool itemLabelsRefs})
        > {
  $$MnemataItemsTableTableManager(_$AppDatabase db, $MnemataItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MnemataItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MnemataItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MnemataItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<String?> filePath = const Value.absent(),
                Value<String?> content = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> lastOpenedAt = const Value.absent(),
              }) => MnemataItemsCompanion(
                id: id,
                title: title,
                url: url,
                filePath: filePath,
                content: content,
                type: type,
                createdAt: createdAt,
                lastOpenedAt: lastOpenedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<String?> filePath = const Value.absent(),
                Value<String?> content = const Value.absent(),
                required String type,
                required DateTime createdAt,
                Value<DateTime?> lastOpenedAt = const Value.absent(),
              }) => MnemataItemsCompanion.insert(
                id: id,
                title: title,
                url: url,
                filePath: filePath,
                content: content,
                type: type,
                createdAt: createdAt,
                lastOpenedAt: lastOpenedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MnemataItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemLabelsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (itemLabelsRefs) db.itemLabels],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (itemLabelsRefs)
                    await $_getPrefetchedData<
                      MnemataItem,
                      $MnemataItemsTable,
                      ItemLabel
                    >(
                      currentTable: table,
                      referencedTable: $$MnemataItemsTableReferences
                          ._itemLabelsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$MnemataItemsTableReferences(
                            db,
                            table,
                            p0,
                          ).itemLabelsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.itemId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$MnemataItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MnemataItemsTable,
      MnemataItem,
      $$MnemataItemsTableFilterComposer,
      $$MnemataItemsTableOrderingComposer,
      $$MnemataItemsTableAnnotationComposer,
      $$MnemataItemsTableCreateCompanionBuilder,
      $$MnemataItemsTableUpdateCompanionBuilder,
      (MnemataItem, $$MnemataItemsTableReferences),
      MnemataItem,
      PrefetchHooks Function({bool itemLabelsRefs})
    >;
typedef $MnemataSearchCreateCompanionBuilder =
    MnemataSearchCompanion Function({
      required String title,
      required String content,
      Value<int> rowid,
    });
typedef $MnemataSearchUpdateCompanionBuilder =
    MnemataSearchCompanion Function({
      Value<String> title,
      Value<String> content,
      Value<int> rowid,
    });

class $MnemataSearchFilterComposer
    extends Composer<_$AppDatabase, MnemataSearch> {
  $MnemataSearchFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );
}

class $MnemataSearchOrderingComposer
    extends Composer<_$AppDatabase, MnemataSearch> {
  $MnemataSearchOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );
}

class $MnemataSearchAnnotationComposer
    extends Composer<_$AppDatabase, MnemataSearch> {
  $MnemataSearchAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);
}

class $MnemataSearchTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          MnemataSearch,
          MnemataSearchData,
          $MnemataSearchFilterComposer,
          $MnemataSearchOrderingComposer,
          $MnemataSearchAnnotationComposer,
          $MnemataSearchCreateCompanionBuilder,
          $MnemataSearchUpdateCompanionBuilder,
          (
            MnemataSearchData,
            BaseReferences<_$AppDatabase, MnemataSearch, MnemataSearchData>,
          ),
          MnemataSearchData,
          PrefetchHooks Function()
        > {
  $MnemataSearchTableManager(_$AppDatabase db, MnemataSearch table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $MnemataSearchFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $MnemataSearchOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $MnemataSearchAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> title = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MnemataSearchCompanion(
                title: title,
                content: content,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String title,
                required String content,
                Value<int> rowid = const Value.absent(),
              }) => MnemataSearchCompanion.insert(
                title: title,
                content: content,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $MnemataSearchProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      MnemataSearch,
      MnemataSearchData,
      $MnemataSearchFilterComposer,
      $MnemataSearchOrderingComposer,
      $MnemataSearchAnnotationComposer,
      $MnemataSearchCreateCompanionBuilder,
      $MnemataSearchUpdateCompanionBuilder,
      (
        MnemataSearchData,
        BaseReferences<_$AppDatabase, MnemataSearch, MnemataSearchData>,
      ),
      MnemataSearchData,
      PrefetchHooks Function()
    >;
typedef $$LabelsTableCreateCompanionBuilder =
    LabelsCompanion Function({
      Value<int> id,
      required String name,
      Value<int?> color,
      Value<int?> parentId,
      Value<bool> isFolder,
    });
typedef $$LabelsTableUpdateCompanionBuilder =
    LabelsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int?> color,
      Value<int?> parentId,
      Value<bool> isFolder,
    });

final class $$LabelsTableReferences
    extends BaseReferences<_$AppDatabase, $LabelsTable, Label> {
  $$LabelsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LabelsTable _parentIdTable(_$AppDatabase db) => db.labels.createAlias(
    $_aliasNameGenerator(db.labels.parentId, db.labels.id),
  );

  $$LabelsTableProcessedTableManager? get parentId {
    final $_column = $_itemColumn<int>('parent_id');
    if ($_column == null) return null;
    final manager = $$LabelsTableTableManager(
      $_db,
      $_db.labels,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ItemLabelsTable, List<ItemLabel>>
  _itemLabelsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.itemLabels,
    aliasName: $_aliasNameGenerator(db.labels.id, db.itemLabels.labelId),
  );

  $$ItemLabelsTableProcessedTableManager get itemLabelsRefs {
    final manager = $$ItemLabelsTableTableManager(
      $_db,
      $_db.itemLabels,
    ).filter((f) => f.labelId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_itemLabelsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LabelsTableFilterComposer
    extends Composer<_$AppDatabase, $LabelsTable> {
  $$LabelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFolder => $composableBuilder(
    column: $table.isFolder,
    builder: (column) => ColumnFilters(column),
  );

  $$LabelsTableFilterComposer get parentId {
    final $$LabelsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.labels,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LabelsTableFilterComposer(
            $db: $db,
            $table: $db.labels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> itemLabelsRefs(
    Expression<bool> Function($$ItemLabelsTableFilterComposer f) f,
  ) {
    final $$ItemLabelsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.itemLabels,
      getReferencedColumn: (t) => t.labelId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemLabelsTableFilterComposer(
            $db: $db,
            $table: $db.itemLabels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LabelsTableOrderingComposer
    extends Composer<_$AppDatabase, $LabelsTable> {
  $$LabelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFolder => $composableBuilder(
    column: $table.isFolder,
    builder: (column) => ColumnOrderings(column),
  );

  $$LabelsTableOrderingComposer get parentId {
    final $$LabelsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.labels,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LabelsTableOrderingComposer(
            $db: $db,
            $table: $db.labels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LabelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LabelsTable> {
  $$LabelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<bool> get isFolder =>
      $composableBuilder(column: $table.isFolder, builder: (column) => column);

  $$LabelsTableAnnotationComposer get parentId {
    final $$LabelsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.labels,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LabelsTableAnnotationComposer(
            $db: $db,
            $table: $db.labels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> itemLabelsRefs<T extends Object>(
    Expression<T> Function($$ItemLabelsTableAnnotationComposer a) f,
  ) {
    final $$ItemLabelsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.itemLabels,
      getReferencedColumn: (t) => t.labelId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemLabelsTableAnnotationComposer(
            $db: $db,
            $table: $db.itemLabels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LabelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LabelsTable,
          Label,
          $$LabelsTableFilterComposer,
          $$LabelsTableOrderingComposer,
          $$LabelsTableAnnotationComposer,
          $$LabelsTableCreateCompanionBuilder,
          $$LabelsTableUpdateCompanionBuilder,
          (Label, $$LabelsTableReferences),
          Label,
          PrefetchHooks Function({bool parentId, bool itemLabelsRefs})
        > {
  $$LabelsTableTableManager(_$AppDatabase db, $LabelsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LabelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LabelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LabelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int?> color = const Value.absent(),
                Value<int?> parentId = const Value.absent(),
                Value<bool> isFolder = const Value.absent(),
              }) => LabelsCompanion(
                id: id,
                name: name,
                color: color,
                parentId: parentId,
                isFolder: isFolder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<int?> color = const Value.absent(),
                Value<int?> parentId = const Value.absent(),
                Value<bool> isFolder = const Value.absent(),
              }) => LabelsCompanion.insert(
                id: id,
                name: name,
                color: color,
                parentId: parentId,
                isFolder: isFolder,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$LabelsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({parentId = false, itemLabelsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (itemLabelsRefs) db.itemLabels],
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
                    if (parentId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.parentId,
                                referencedTable: $$LabelsTableReferences
                                    ._parentIdTable(db),
                                referencedColumn: $$LabelsTableReferences
                                    ._parentIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (itemLabelsRefs)
                    await $_getPrefetchedData<Label, $LabelsTable, ItemLabel>(
                      currentTable: table,
                      referencedTable: $$LabelsTableReferences
                          ._itemLabelsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$LabelsTableReferences(db, table, p0).itemLabelsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.labelId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$LabelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LabelsTable,
      Label,
      $$LabelsTableFilterComposer,
      $$LabelsTableOrderingComposer,
      $$LabelsTableAnnotationComposer,
      $$LabelsTableCreateCompanionBuilder,
      $$LabelsTableUpdateCompanionBuilder,
      (Label, $$LabelsTableReferences),
      Label,
      PrefetchHooks Function({bool parentId, bool itemLabelsRefs})
    >;
typedef $$ItemLabelsTableCreateCompanionBuilder =
    ItemLabelsCompanion Function({
      required int itemId,
      required int labelId,
      Value<int> rowid,
    });
typedef $$ItemLabelsTableUpdateCompanionBuilder =
    ItemLabelsCompanion Function({
      Value<int> itemId,
      Value<int> labelId,
      Value<int> rowid,
    });

final class $$ItemLabelsTableReferences
    extends BaseReferences<_$AppDatabase, $ItemLabelsTable, ItemLabel> {
  $$ItemLabelsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MnemataItemsTable _itemIdTable(_$AppDatabase db) =>
      db.mnemataItems.createAlias(
        $_aliasNameGenerator(db.itemLabels.itemId, db.mnemataItems.id),
      );

  $$MnemataItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<int>('item_id')!;

    final manager = $$MnemataItemsTableTableManager(
      $_db,
      $_db.mnemataItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $LabelsTable _labelIdTable(_$AppDatabase db) => db.labels.createAlias(
    $_aliasNameGenerator(db.itemLabels.labelId, db.labels.id),
  );

  $$LabelsTableProcessedTableManager get labelId {
    final $_column = $_itemColumn<int>('label_id')!;

    final manager = $$LabelsTableTableManager(
      $_db,
      $_db.labels,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_labelIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ItemLabelsTableFilterComposer
    extends Composer<_$AppDatabase, $ItemLabelsTable> {
  $$ItemLabelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$MnemataItemsTableFilterComposer get itemId {
    final $$MnemataItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.mnemataItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MnemataItemsTableFilterComposer(
            $db: $db,
            $table: $db.mnemataItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LabelsTableFilterComposer get labelId {
    final $$LabelsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.labelId,
      referencedTable: $db.labels,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LabelsTableFilterComposer(
            $db: $db,
            $table: $db.labels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemLabelsTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemLabelsTable> {
  $$ItemLabelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$MnemataItemsTableOrderingComposer get itemId {
    final $$MnemataItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.mnemataItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MnemataItemsTableOrderingComposer(
            $db: $db,
            $table: $db.mnemataItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LabelsTableOrderingComposer get labelId {
    final $$LabelsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.labelId,
      referencedTable: $db.labels,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LabelsTableOrderingComposer(
            $db: $db,
            $table: $db.labels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemLabelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemLabelsTable> {
  $$ItemLabelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$MnemataItemsTableAnnotationComposer get itemId {
    final $$MnemataItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.mnemataItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MnemataItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.mnemataItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LabelsTableAnnotationComposer get labelId {
    final $$LabelsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.labelId,
      referencedTable: $db.labels,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LabelsTableAnnotationComposer(
            $db: $db,
            $table: $db.labels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemLabelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ItemLabelsTable,
          ItemLabel,
          $$ItemLabelsTableFilterComposer,
          $$ItemLabelsTableOrderingComposer,
          $$ItemLabelsTableAnnotationComposer,
          $$ItemLabelsTableCreateCompanionBuilder,
          $$ItemLabelsTableUpdateCompanionBuilder,
          (ItemLabel, $$ItemLabelsTableReferences),
          ItemLabel,
          PrefetchHooks Function({bool itemId, bool labelId})
        > {
  $$ItemLabelsTableTableManager(_$AppDatabase db, $ItemLabelsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemLabelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemLabelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemLabelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> itemId = const Value.absent(),
                Value<int> labelId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemLabelsCompanion(
                itemId: itemId,
                labelId: labelId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int itemId,
                required int labelId,
                Value<int> rowid = const Value.absent(),
              }) => ItemLabelsCompanion.insert(
                itemId: itemId,
                labelId: labelId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ItemLabelsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false, labelId = false}) {
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
                    if (itemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.itemId,
                                referencedTable: $$ItemLabelsTableReferences
                                    ._itemIdTable(db),
                                referencedColumn: $$ItemLabelsTableReferences
                                    ._itemIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (labelId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.labelId,
                                referencedTable: $$ItemLabelsTableReferences
                                    ._labelIdTable(db),
                                referencedColumn: $$ItemLabelsTableReferences
                                    ._labelIdTable(db)
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

typedef $$ItemLabelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ItemLabelsTable,
      ItemLabel,
      $$ItemLabelsTableFilterComposer,
      $$ItemLabelsTableOrderingComposer,
      $$ItemLabelsTableAnnotationComposer,
      $$ItemLabelsTableCreateCompanionBuilder,
      $$ItemLabelsTableUpdateCompanionBuilder,
      (ItemLabel, $$ItemLabelsTableReferences),
      ItemLabel,
      PrefetchHooks Function({bool itemId, bool labelId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MnemataItemsTableTableManager get mnemataItems =>
      $$MnemataItemsTableTableManager(_db, _db.mnemataItems);
  $MnemataSearchTableManager get mnemataSearch =>
      $MnemataSearchTableManager(_db, _db.mnemataSearch);
  $$LabelsTableTableManager get labels =>
      $$LabelsTableTableManager(_db, _db.labels);
  $$ItemLabelsTableTableManager get itemLabels =>
      $$ItemLabelsTableTableManager(_db, _db.itemLabels);
}
