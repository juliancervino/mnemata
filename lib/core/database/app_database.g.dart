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
  static const VerificationMeta _thumbnailUrlMeta = const VerificationMeta(
    'thumbnailUrl',
  );
  @override
  late final GeneratedColumn<String> thumbnailUrl = GeneratedColumn<String>(
    'thumbnail_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
    thumbnailUrl,
    sortOrder,
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
    if (data.containsKey('thumbnail_url')) {
      context.handle(
        _thumbnailUrlMeta,
        thumbnailUrl.isAcceptableOrUnknown(
          data['thumbnail_url']!,
          _thumbnailUrlMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
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
      thumbnailUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_url'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
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
  final String? thumbnailUrl;
  final int sortOrder;
  const MnemataItem({
    required this.id,
    this.title,
    this.url,
    this.filePath,
    this.content,
    required this.type,
    required this.createdAt,
    this.lastOpenedAt,
    this.thumbnailUrl,
    required this.sortOrder,
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
    if (!nullToAbsent || thumbnailUrl != null) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl);
    }
    map['sort_order'] = Variable<int>(sortOrder);
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
      thumbnailUrl: thumbnailUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailUrl),
      sortOrder: Value(sortOrder),
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
      thumbnailUrl: serializer.fromJson<String?>(json['thumbnailUrl']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
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
      'thumbnailUrl': serializer.toJson<String?>(thumbnailUrl),
      'sortOrder': serializer.toJson<int>(sortOrder),
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
    Value<String?> thumbnailUrl = const Value.absent(),
    int? sortOrder,
  }) => MnemataItem(
    id: id ?? this.id,
    title: title.present ? title.value : this.title,
    url: url.present ? url.value : this.url,
    filePath: filePath.present ? filePath.value : this.filePath,
    content: content.present ? content.value : this.content,
    type: type ?? this.type,
    createdAt: createdAt ?? this.createdAt,
    lastOpenedAt: lastOpenedAt.present ? lastOpenedAt.value : this.lastOpenedAt,
    thumbnailUrl: thumbnailUrl.present ? thumbnailUrl.value : this.thumbnailUrl,
    sortOrder: sortOrder ?? this.sortOrder,
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
      thumbnailUrl: data.thumbnailUrl.present
          ? data.thumbnailUrl.value
          : this.thumbnailUrl,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
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
          ..write('lastOpenedAt: $lastOpenedAt, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('sortOrder: $sortOrder')
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
    thumbnailUrl,
    sortOrder,
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
          other.lastOpenedAt == this.lastOpenedAt &&
          other.thumbnailUrl == this.thumbnailUrl &&
          other.sortOrder == this.sortOrder);
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
  final Value<String?> thumbnailUrl;
  final Value<int> sortOrder;
  const MnemataItemsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.url = const Value.absent(),
    this.filePath = const Value.absent(),
    this.content = const Value.absent(),
    this.type = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastOpenedAt = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.sortOrder = const Value.absent(),
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
    this.thumbnailUrl = const Value.absent(),
    this.sortOrder = const Value.absent(),
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
    Expression<String>? thumbnailUrl,
    Expression<int>? sortOrder,
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
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (sortOrder != null) 'sort_order': sortOrder,
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
    Value<String?>? thumbnailUrl,
    Value<int>? sortOrder,
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
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      sortOrder: sortOrder ?? this.sortOrder,
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
    if (thumbnailUrl.present) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
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
          ..write('lastOpenedAt: $lastOpenedAt, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('sortOrder: $sortOrder')
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

class $SummaryCachesTable extends SummaryCaches
    with TableInfo<$SummaryCachesTable, SummaryCache> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SummaryCachesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES mnemata_items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _contentHashMeta = const VerificationMeta(
    'contentHash',
  );
  @override
  late final GeneratedColumn<String> contentHash = GeneratedColumn<String>(
    'content_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tldrMeta = const VerificationMeta('tldr');
  @override
  late final GeneratedColumn<String> tldr = GeneratedColumn<String>(
    'tldr',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyPointsJsonMeta = const VerificationMeta(
    'keyPointsJson',
  );
  @override
  late final GeneratedColumn<String> keyPointsJson = GeneratedColumn<String>(
    'key_points_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _whyItMattersMeta = const VerificationMeta(
    'whyItMatters',
  );
  @override
  late final GeneratedColumn<String> whyItMatters = GeneratedColumn<String>(
    'why_it_matters',
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    contentHash,
    tldr,
    keyPointsJson,
    whyItMatters,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'summary_caches';
  @override
  VerificationContext validateIntegrity(
    Insertable<SummaryCache> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('content_hash')) {
      context.handle(
        _contentHashMeta,
        contentHash.isAcceptableOrUnknown(
          data['content_hash']!,
          _contentHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentHashMeta);
    }
    if (data.containsKey('tldr')) {
      context.handle(
        _tldrMeta,
        tldr.isAcceptableOrUnknown(data['tldr']!, _tldrMeta),
      );
    } else if (isInserting) {
      context.missing(_tldrMeta);
    }
    if (data.containsKey('key_points_json')) {
      context.handle(
        _keyPointsJsonMeta,
        keyPointsJson.isAcceptableOrUnknown(
          data['key_points_json']!,
          _keyPointsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_keyPointsJsonMeta);
    }
    if (data.containsKey('why_it_matters')) {
      context.handle(
        _whyItMattersMeta,
        whyItMatters.isAcceptableOrUnknown(
          data['why_it_matters']!,
          _whyItMattersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_whyItMattersMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {itemId, contentHash},
  ];
  @override
  SummaryCache map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SummaryCache(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_id'],
      )!,
      contentHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_hash'],
      )!,
      tldr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tldr'],
      )!,
      keyPointsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key_points_json'],
      )!,
      whyItMatters: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}why_it_matters'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SummaryCachesTable createAlias(String alias) {
    return $SummaryCachesTable(attachedDatabase, alias);
  }
}

class SummaryCache extends DataClass implements Insertable<SummaryCache> {
  final int id;
  final int itemId;
  final String contentHash;
  final String tldr;
  final String keyPointsJson;
  final String whyItMatters;
  final DateTime createdAt;
  const SummaryCache({
    required this.id,
    required this.itemId,
    required this.contentHash,
    required this.tldr,
    required this.keyPointsJson,
    required this.whyItMatters,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['item_id'] = Variable<int>(itemId);
    map['content_hash'] = Variable<String>(contentHash);
    map['tldr'] = Variable<String>(tldr);
    map['key_points_json'] = Variable<String>(keyPointsJson);
    map['why_it_matters'] = Variable<String>(whyItMatters);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SummaryCachesCompanion toCompanion(bool nullToAbsent) {
    return SummaryCachesCompanion(
      id: Value(id),
      itemId: Value(itemId),
      contentHash: Value(contentHash),
      tldr: Value(tldr),
      keyPointsJson: Value(keyPointsJson),
      whyItMatters: Value(whyItMatters),
      createdAt: Value(createdAt),
    );
  }

  factory SummaryCache.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SummaryCache(
      id: serializer.fromJson<int>(json['id']),
      itemId: serializer.fromJson<int>(json['itemId']),
      contentHash: serializer.fromJson<String>(json['contentHash']),
      tldr: serializer.fromJson<String>(json['tldr']),
      keyPointsJson: serializer.fromJson<String>(json['keyPointsJson']),
      whyItMatters: serializer.fromJson<String>(json['whyItMatters']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'itemId': serializer.toJson<int>(itemId),
      'contentHash': serializer.toJson<String>(contentHash),
      'tldr': serializer.toJson<String>(tldr),
      'keyPointsJson': serializer.toJson<String>(keyPointsJson),
      'whyItMatters': serializer.toJson<String>(whyItMatters),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SummaryCache copyWith({
    int? id,
    int? itemId,
    String? contentHash,
    String? tldr,
    String? keyPointsJson,
    String? whyItMatters,
    DateTime? createdAt,
  }) => SummaryCache(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    contentHash: contentHash ?? this.contentHash,
    tldr: tldr ?? this.tldr,
    keyPointsJson: keyPointsJson ?? this.keyPointsJson,
    whyItMatters: whyItMatters ?? this.whyItMatters,
    createdAt: createdAt ?? this.createdAt,
  );
  SummaryCache copyWithCompanion(SummaryCachesCompanion data) {
    return SummaryCache(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      contentHash: data.contentHash.present
          ? data.contentHash.value
          : this.contentHash,
      tldr: data.tldr.present ? data.tldr.value : this.tldr,
      keyPointsJson: data.keyPointsJson.present
          ? data.keyPointsJson.value
          : this.keyPointsJson,
      whyItMatters: data.whyItMatters.present
          ? data.whyItMatters.value
          : this.whyItMatters,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SummaryCache(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('contentHash: $contentHash, ')
          ..write('tldr: $tldr, ')
          ..write('keyPointsJson: $keyPointsJson, ')
          ..write('whyItMatters: $whyItMatters, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    itemId,
    contentHash,
    tldr,
    keyPointsJson,
    whyItMatters,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SummaryCache &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.contentHash == this.contentHash &&
          other.tldr == this.tldr &&
          other.keyPointsJson == this.keyPointsJson &&
          other.whyItMatters == this.whyItMatters &&
          other.createdAt == this.createdAt);
}

class SummaryCachesCompanion extends UpdateCompanion<SummaryCache> {
  final Value<int> id;
  final Value<int> itemId;
  final Value<String> contentHash;
  final Value<String> tldr;
  final Value<String> keyPointsJson;
  final Value<String> whyItMatters;
  final Value<DateTime> createdAt;
  const SummaryCachesCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.tldr = const Value.absent(),
    this.keyPointsJson = const Value.absent(),
    this.whyItMatters = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SummaryCachesCompanion.insert({
    this.id = const Value.absent(),
    required int itemId,
    required String contentHash,
    required String tldr,
    required String keyPointsJson,
    required String whyItMatters,
    this.createdAt = const Value.absent(),
  }) : itemId = Value(itemId),
       contentHash = Value(contentHash),
       tldr = Value(tldr),
       keyPointsJson = Value(keyPointsJson),
       whyItMatters = Value(whyItMatters);
  static Insertable<SummaryCache> custom({
    Expression<int>? id,
    Expression<int>? itemId,
    Expression<String>? contentHash,
    Expression<String>? tldr,
    Expression<String>? keyPointsJson,
    Expression<String>? whyItMatters,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (contentHash != null) 'content_hash': contentHash,
      if (tldr != null) 'tldr': tldr,
      if (keyPointsJson != null) 'key_points_json': keyPointsJson,
      if (whyItMatters != null) 'why_it_matters': whyItMatters,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SummaryCachesCompanion copyWith({
    Value<int>? id,
    Value<int>? itemId,
    Value<String>? contentHash,
    Value<String>? tldr,
    Value<String>? keyPointsJson,
    Value<String>? whyItMatters,
    Value<DateTime>? createdAt,
  }) {
    return SummaryCachesCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      contentHash: contentHash ?? this.contentHash,
      tldr: tldr ?? this.tldr,
      keyPointsJson: keyPointsJson ?? this.keyPointsJson,
      whyItMatters: whyItMatters ?? this.whyItMatters,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (contentHash.present) {
      map['content_hash'] = Variable<String>(contentHash.value);
    }
    if (tldr.present) {
      map['tldr'] = Variable<String>(tldr.value);
    }
    if (keyPointsJson.present) {
      map['key_points_json'] = Variable<String>(keyPointsJson.value);
    }
    if (whyItMatters.present) {
      map['why_it_matters'] = Variable<String>(whyItMatters.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SummaryCachesCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('contentHash: $contentHash, ')
          ..write('tldr: $tldr, ')
          ..write('keyPointsJson: $keyPointsJson, ')
          ..write('whyItMatters: $whyItMatters, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SemanticIndexStatesTable extends SemanticIndexStates
    with TableInfo<$SemanticIndexStatesTable, SemanticIndexState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SemanticIndexStatesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES mnemata_items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _contentHashMeta = const VerificationMeta(
    'contentHash',
  );
  @override
  late final GeneratedColumn<String> contentHash = GeneratedColumn<String>(
    'content_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _embeddingModelMeta = const VerificationMeta(
    'embeddingModel',
  );
  @override
  late final GeneratedColumn<String> embeddingModel = GeneratedColumn<String>(
    'embedding_model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chunkCountMeta = const VerificationMeta(
    'chunkCount',
  );
  @override
  late final GeneratedColumn<int> chunkCount = GeneratedColumn<int>(
    'chunk_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _indexedAtMeta = const VerificationMeta(
    'indexedAt',
  );
  @override
  late final GeneratedColumn<DateTime> indexedAt = GeneratedColumn<DateTime>(
    'indexed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    contentHash,
    embeddingModel,
    chunkCount,
    indexedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'semantic_index_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<SemanticIndexState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('content_hash')) {
      context.handle(
        _contentHashMeta,
        contentHash.isAcceptableOrUnknown(
          data['content_hash']!,
          _contentHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentHashMeta);
    }
    if (data.containsKey('embedding_model')) {
      context.handle(
        _embeddingModelMeta,
        embeddingModel.isAcceptableOrUnknown(
          data['embedding_model']!,
          _embeddingModelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_embeddingModelMeta);
    }
    if (data.containsKey('chunk_count')) {
      context.handle(
        _chunkCountMeta,
        chunkCount.isAcceptableOrUnknown(data['chunk_count']!, _chunkCountMeta),
      );
    } else if (isInserting) {
      context.missing(_chunkCountMeta);
    }
    if (data.containsKey('indexed_at')) {
      context.handle(
        _indexedAtMeta,
        indexedAt.isAcceptableOrUnknown(data['indexed_at']!, _indexedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {itemId},
  ];
  @override
  SemanticIndexState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SemanticIndexState(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_id'],
      )!,
      contentHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_hash'],
      )!,
      embeddingModel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}embedding_model'],
      )!,
      chunkCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chunk_count'],
      )!,
      indexedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}indexed_at'],
      )!,
    );
  }

  @override
  $SemanticIndexStatesTable createAlias(String alias) {
    return $SemanticIndexStatesTable(attachedDatabase, alias);
  }
}

class SemanticIndexState extends DataClass
    implements Insertable<SemanticIndexState> {
  final int id;
  final int itemId;
  final String contentHash;
  final String embeddingModel;
  final int chunkCount;
  final DateTime indexedAt;
  const SemanticIndexState({
    required this.id,
    required this.itemId,
    required this.contentHash,
    required this.embeddingModel,
    required this.chunkCount,
    required this.indexedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['item_id'] = Variable<int>(itemId);
    map['content_hash'] = Variable<String>(contentHash);
    map['embedding_model'] = Variable<String>(embeddingModel);
    map['chunk_count'] = Variable<int>(chunkCount);
    map['indexed_at'] = Variable<DateTime>(indexedAt);
    return map;
  }

  SemanticIndexStatesCompanion toCompanion(bool nullToAbsent) {
    return SemanticIndexStatesCompanion(
      id: Value(id),
      itemId: Value(itemId),
      contentHash: Value(contentHash),
      embeddingModel: Value(embeddingModel),
      chunkCount: Value(chunkCount),
      indexedAt: Value(indexedAt),
    );
  }

  factory SemanticIndexState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SemanticIndexState(
      id: serializer.fromJson<int>(json['id']),
      itemId: serializer.fromJson<int>(json['itemId']),
      contentHash: serializer.fromJson<String>(json['contentHash']),
      embeddingModel: serializer.fromJson<String>(json['embeddingModel']),
      chunkCount: serializer.fromJson<int>(json['chunkCount']),
      indexedAt: serializer.fromJson<DateTime>(json['indexedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'itemId': serializer.toJson<int>(itemId),
      'contentHash': serializer.toJson<String>(contentHash),
      'embeddingModel': serializer.toJson<String>(embeddingModel),
      'chunkCount': serializer.toJson<int>(chunkCount),
      'indexedAt': serializer.toJson<DateTime>(indexedAt),
    };
  }

  SemanticIndexState copyWith({
    int? id,
    int? itemId,
    String? contentHash,
    String? embeddingModel,
    int? chunkCount,
    DateTime? indexedAt,
  }) => SemanticIndexState(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    contentHash: contentHash ?? this.contentHash,
    embeddingModel: embeddingModel ?? this.embeddingModel,
    chunkCount: chunkCount ?? this.chunkCount,
    indexedAt: indexedAt ?? this.indexedAt,
  );
  SemanticIndexState copyWithCompanion(SemanticIndexStatesCompanion data) {
    return SemanticIndexState(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      contentHash: data.contentHash.present
          ? data.contentHash.value
          : this.contentHash,
      embeddingModel: data.embeddingModel.present
          ? data.embeddingModel.value
          : this.embeddingModel,
      chunkCount: data.chunkCount.present
          ? data.chunkCount.value
          : this.chunkCount,
      indexedAt: data.indexedAt.present ? data.indexedAt.value : this.indexedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SemanticIndexState(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('contentHash: $contentHash, ')
          ..write('embeddingModel: $embeddingModel, ')
          ..write('chunkCount: $chunkCount, ')
          ..write('indexedAt: $indexedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    itemId,
    contentHash,
    embeddingModel,
    chunkCount,
    indexedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SemanticIndexState &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.contentHash == this.contentHash &&
          other.embeddingModel == this.embeddingModel &&
          other.chunkCount == this.chunkCount &&
          other.indexedAt == this.indexedAt);
}

class SemanticIndexStatesCompanion extends UpdateCompanion<SemanticIndexState> {
  final Value<int> id;
  final Value<int> itemId;
  final Value<String> contentHash;
  final Value<String> embeddingModel;
  final Value<int> chunkCount;
  final Value<DateTime> indexedAt;
  const SemanticIndexStatesCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.embeddingModel = const Value.absent(),
    this.chunkCount = const Value.absent(),
    this.indexedAt = const Value.absent(),
  });
  SemanticIndexStatesCompanion.insert({
    this.id = const Value.absent(),
    required int itemId,
    required String contentHash,
    required String embeddingModel,
    required int chunkCount,
    this.indexedAt = const Value.absent(),
  }) : itemId = Value(itemId),
       contentHash = Value(contentHash),
       embeddingModel = Value(embeddingModel),
       chunkCount = Value(chunkCount);
  static Insertable<SemanticIndexState> custom({
    Expression<int>? id,
    Expression<int>? itemId,
    Expression<String>? contentHash,
    Expression<String>? embeddingModel,
    Expression<int>? chunkCount,
    Expression<DateTime>? indexedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (contentHash != null) 'content_hash': contentHash,
      if (embeddingModel != null) 'embedding_model': embeddingModel,
      if (chunkCount != null) 'chunk_count': chunkCount,
      if (indexedAt != null) 'indexed_at': indexedAt,
    });
  }

  SemanticIndexStatesCompanion copyWith({
    Value<int>? id,
    Value<int>? itemId,
    Value<String>? contentHash,
    Value<String>? embeddingModel,
    Value<int>? chunkCount,
    Value<DateTime>? indexedAt,
  }) {
    return SemanticIndexStatesCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      contentHash: contentHash ?? this.contentHash,
      embeddingModel: embeddingModel ?? this.embeddingModel,
      chunkCount: chunkCount ?? this.chunkCount,
      indexedAt: indexedAt ?? this.indexedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (contentHash.present) {
      map['content_hash'] = Variable<String>(contentHash.value);
    }
    if (embeddingModel.present) {
      map['embedding_model'] = Variable<String>(embeddingModel.value);
    }
    if (chunkCount.present) {
      map['chunk_count'] = Variable<int>(chunkCount.value);
    }
    if (indexedAt.present) {
      map['indexed_at'] = Variable<DateTime>(indexedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SemanticIndexStatesCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('contentHash: $contentHash, ')
          ..write('embeddingModel: $embeddingModel, ')
          ..write('chunkCount: $chunkCount, ')
          ..write('indexedAt: $indexedAt')
          ..write(')'))
        .toString();
  }
}

class $SemanticChunksTable extends SemanticChunks
    with TableInfo<$SemanticChunksTable, SemanticChunk> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SemanticChunksTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES mnemata_items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _chunkIndexMeta = const VerificationMeta(
    'chunkIndex',
  );
  @override
  late final GeneratedColumn<int> chunkIndex = GeneratedColumn<int>(
    'chunk_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chunkTextMeta = const VerificationMeta(
    'chunkText',
  );
  @override
  late final GeneratedColumn<String> chunkText = GeneratedColumn<String>(
    'chunk_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _embeddingVectorJsonMeta =
      const VerificationMeta('embeddingVectorJson');
  @override
  late final GeneratedColumn<String> embeddingVectorJson =
      GeneratedColumn<String>(
        'embedding_vector_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    chunkIndex,
    chunkText,
    embeddingVectorJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'semantic_chunks';
  @override
  VerificationContext validateIntegrity(
    Insertable<SemanticChunk> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('chunk_index')) {
      context.handle(
        _chunkIndexMeta,
        chunkIndex.isAcceptableOrUnknown(data['chunk_index']!, _chunkIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_chunkIndexMeta);
    }
    if (data.containsKey('chunk_text')) {
      context.handle(
        _chunkTextMeta,
        chunkText.isAcceptableOrUnknown(data['chunk_text']!, _chunkTextMeta),
      );
    } else if (isInserting) {
      context.missing(_chunkTextMeta);
    }
    if (data.containsKey('embedding_vector_json')) {
      context.handle(
        _embeddingVectorJsonMeta,
        embeddingVectorJson.isAcceptableOrUnknown(
          data['embedding_vector_json']!,
          _embeddingVectorJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_embeddingVectorJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SemanticChunk map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SemanticChunk(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_id'],
      )!,
      chunkIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chunk_index'],
      )!,
      chunkText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chunk_text'],
      )!,
      embeddingVectorJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}embedding_vector_json'],
      )!,
    );
  }

  @override
  $SemanticChunksTable createAlias(String alias) {
    return $SemanticChunksTable(attachedDatabase, alias);
  }
}

class SemanticChunk extends DataClass implements Insertable<SemanticChunk> {
  final int id;
  final int itemId;
  final int chunkIndex;
  final String chunkText;
  final String embeddingVectorJson;
  const SemanticChunk({
    required this.id,
    required this.itemId,
    required this.chunkIndex,
    required this.chunkText,
    required this.embeddingVectorJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['item_id'] = Variable<int>(itemId);
    map['chunk_index'] = Variable<int>(chunkIndex);
    map['chunk_text'] = Variable<String>(chunkText);
    map['embedding_vector_json'] = Variable<String>(embeddingVectorJson);
    return map;
  }

  SemanticChunksCompanion toCompanion(bool nullToAbsent) {
    return SemanticChunksCompanion(
      id: Value(id),
      itemId: Value(itemId),
      chunkIndex: Value(chunkIndex),
      chunkText: Value(chunkText),
      embeddingVectorJson: Value(embeddingVectorJson),
    );
  }

  factory SemanticChunk.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SemanticChunk(
      id: serializer.fromJson<int>(json['id']),
      itemId: serializer.fromJson<int>(json['itemId']),
      chunkIndex: serializer.fromJson<int>(json['chunkIndex']),
      chunkText: serializer.fromJson<String>(json['chunkText']),
      embeddingVectorJson: serializer.fromJson<String>(
        json['embeddingVectorJson'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'itemId': serializer.toJson<int>(itemId),
      'chunkIndex': serializer.toJson<int>(chunkIndex),
      'chunkText': serializer.toJson<String>(chunkText),
      'embeddingVectorJson': serializer.toJson<String>(embeddingVectorJson),
    };
  }

  SemanticChunk copyWith({
    int? id,
    int? itemId,
    int? chunkIndex,
    String? chunkText,
    String? embeddingVectorJson,
  }) => SemanticChunk(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    chunkIndex: chunkIndex ?? this.chunkIndex,
    chunkText: chunkText ?? this.chunkText,
    embeddingVectorJson: embeddingVectorJson ?? this.embeddingVectorJson,
  );
  SemanticChunk copyWithCompanion(SemanticChunksCompanion data) {
    return SemanticChunk(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      chunkIndex: data.chunkIndex.present
          ? data.chunkIndex.value
          : this.chunkIndex,
      chunkText: data.chunkText.present ? data.chunkText.value : this.chunkText,
      embeddingVectorJson: data.embeddingVectorJson.present
          ? data.embeddingVectorJson.value
          : this.embeddingVectorJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SemanticChunk(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('chunkIndex: $chunkIndex, ')
          ..write('chunkText: $chunkText, ')
          ..write('embeddingVectorJson: $embeddingVectorJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, itemId, chunkIndex, chunkText, embeddingVectorJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SemanticChunk &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.chunkIndex == this.chunkIndex &&
          other.chunkText == this.chunkText &&
          other.embeddingVectorJson == this.embeddingVectorJson);
}

class SemanticChunksCompanion extends UpdateCompanion<SemanticChunk> {
  final Value<int> id;
  final Value<int> itemId;
  final Value<int> chunkIndex;
  final Value<String> chunkText;
  final Value<String> embeddingVectorJson;
  const SemanticChunksCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.chunkIndex = const Value.absent(),
    this.chunkText = const Value.absent(),
    this.embeddingVectorJson = const Value.absent(),
  });
  SemanticChunksCompanion.insert({
    this.id = const Value.absent(),
    required int itemId,
    required int chunkIndex,
    required String chunkText,
    required String embeddingVectorJson,
  }) : itemId = Value(itemId),
       chunkIndex = Value(chunkIndex),
       chunkText = Value(chunkText),
       embeddingVectorJson = Value(embeddingVectorJson);
  static Insertable<SemanticChunk> custom({
    Expression<int>? id,
    Expression<int>? itemId,
    Expression<int>? chunkIndex,
    Expression<String>? chunkText,
    Expression<String>? embeddingVectorJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (chunkIndex != null) 'chunk_index': chunkIndex,
      if (chunkText != null) 'chunk_text': chunkText,
      if (embeddingVectorJson != null)
        'embedding_vector_json': embeddingVectorJson,
    });
  }

  SemanticChunksCompanion copyWith({
    Value<int>? id,
    Value<int>? itemId,
    Value<int>? chunkIndex,
    Value<String>? chunkText,
    Value<String>? embeddingVectorJson,
  }) {
    return SemanticChunksCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      chunkIndex: chunkIndex ?? this.chunkIndex,
      chunkText: chunkText ?? this.chunkText,
      embeddingVectorJson: embeddingVectorJson ?? this.embeddingVectorJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (chunkIndex.present) {
      map['chunk_index'] = Variable<int>(chunkIndex.value);
    }
    if (chunkText.present) {
      map['chunk_text'] = Variable<String>(chunkText.value);
    }
    if (embeddingVectorJson.present) {
      map['embedding_vector_json'] = Variable<String>(
        embeddingVectorJson.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SemanticChunksCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('chunkIndex: $chunkIndex, ')
          ..write('chunkText: $chunkText, ')
          ..write('embeddingVectorJson: $embeddingVectorJson')
          ..write(')'))
        .toString();
  }
}

class $AnnotationRecordsTable extends AnnotationRecords
    with TableInfo<$AnnotationRecordsTable, AnnotationRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnnotationRecordsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES mnemata_items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _quoteTextMeta = const VerificationMeta(
    'quoteText',
  );
  @override
  late final GeneratedColumn<String> quoteText = GeneratedColumn<String>(
    'quote_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _anchorJsonMeta = const VerificationMeta(
    'anchorJson',
  );
  @override
  late final GeneratedColumn<String> anchorJson = GeneratedColumn<String>(
    'anchor_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    quoteText,
    anchorJson,
    note,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'annotation_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<AnnotationRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('quote_text')) {
      context.handle(
        _quoteTextMeta,
        quoteText.isAcceptableOrUnknown(data['quote_text']!, _quoteTextMeta),
      );
    } else if (isInserting) {
      context.missing(_quoteTextMeta);
    }
    if (data.containsKey('anchor_json')) {
      context.handle(
        _anchorJsonMeta,
        anchorJson.isAcceptableOrUnknown(data['anchor_json']!, _anchorJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_anchorJsonMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AnnotationRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnnotationRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_id'],
      )!,
      quoteText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quote_text'],
      )!,
      anchorJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}anchor_json'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $AnnotationRecordsTable createAlias(String alias) {
    return $AnnotationRecordsTable(attachedDatabase, alias);
  }
}

class AnnotationRecord extends DataClass
    implements Insertable<AnnotationRecord> {
  final int id;
  final int itemId;
  final String quoteText;
  final String anchorJson;
  final String? note;
  final DateTime createdAt;
  final DateTime? updatedAt;
  const AnnotationRecord({
    required this.id,
    required this.itemId,
    required this.quoteText,
    required this.anchorJson,
    this.note,
    required this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['item_id'] = Variable<int>(itemId);
    map['quote_text'] = Variable<String>(quoteText);
    map['anchor_json'] = Variable<String>(anchorJson);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  AnnotationRecordsCompanion toCompanion(bool nullToAbsent) {
    return AnnotationRecordsCompanion(
      id: Value(id),
      itemId: Value(itemId),
      quoteText: Value(quoteText),
      anchorJson: Value(anchorJson),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory AnnotationRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnnotationRecord(
      id: serializer.fromJson<int>(json['id']),
      itemId: serializer.fromJson<int>(json['itemId']),
      quoteText: serializer.fromJson<String>(json['quoteText']),
      anchorJson: serializer.fromJson<String>(json['anchorJson']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'itemId': serializer.toJson<int>(itemId),
      'quoteText': serializer.toJson<String>(quoteText),
      'anchorJson': serializer.toJson<String>(anchorJson),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  AnnotationRecord copyWith({
    int? id,
    int? itemId,
    String? quoteText,
    String? anchorJson,
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => AnnotationRecord(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    quoteText: quoteText ?? this.quoteText,
    anchorJson: anchorJson ?? this.anchorJson,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  AnnotationRecord copyWithCompanion(AnnotationRecordsCompanion data) {
    return AnnotationRecord(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      quoteText: data.quoteText.present ? data.quoteText.value : this.quoteText,
      anchorJson: data.anchorJson.present
          ? data.anchorJson.value
          : this.anchorJson,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnnotationRecord(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('quoteText: $quoteText, ')
          ..write('anchorJson: $anchorJson, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    itemId,
    quoteText,
    anchorJson,
    note,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnnotationRecord &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.quoteText == this.quoteText &&
          other.anchorJson == this.anchorJson &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AnnotationRecordsCompanion extends UpdateCompanion<AnnotationRecord> {
  final Value<int> id;
  final Value<int> itemId;
  final Value<String> quoteText;
  final Value<String> anchorJson;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  const AnnotationRecordsCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.quoteText = const Value.absent(),
    this.anchorJson = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AnnotationRecordsCompanion.insert({
    this.id = const Value.absent(),
    required int itemId,
    required String quoteText,
    required String anchorJson,
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : itemId = Value(itemId),
       quoteText = Value(quoteText),
       anchorJson = Value(anchorJson);
  static Insertable<AnnotationRecord> custom({
    Expression<int>? id,
    Expression<int>? itemId,
    Expression<String>? quoteText,
    Expression<String>? anchorJson,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (quoteText != null) 'quote_text': quoteText,
      if (anchorJson != null) 'anchor_json': anchorJson,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AnnotationRecordsCompanion copyWith({
    Value<int>? id,
    Value<int>? itemId,
    Value<String>? quoteText,
    Value<String>? anchorJson,
    Value<String?>? note,
    Value<DateTime>? createdAt,
    Value<DateTime?>? updatedAt,
  }) {
    return AnnotationRecordsCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      quoteText: quoteText ?? this.quoteText,
      anchorJson: anchorJson ?? this.anchorJson,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (quoteText.present) {
      map['quote_text'] = Variable<String>(quoteText.value);
    }
    if (anchorJson.present) {
      map['anchor_json'] = Variable<String>(anchorJson.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnnotationRecordsCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('quoteText: $quoteText, ')
          ..write('anchorJson: $anchorJson, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
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
  late final $SummaryCachesTable summaryCaches = $SummaryCachesTable(this);
  late final $SemanticIndexStatesTable semanticIndexStates =
      $SemanticIndexStatesTable(this);
  late final $SemanticChunksTable semanticChunks = $SemanticChunksTable(this);
  late final $AnnotationRecordsTable annotationRecords =
      $AnnotationRecordsTable(this);
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
    summaryCaches,
    semanticIndexStates,
    semanticChunks,
    annotationRecords,
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
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'mnemata_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('summary_caches', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'mnemata_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('semantic_index_states', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'mnemata_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('semantic_chunks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'mnemata_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('annotation_records', kind: UpdateKind.delete)],
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
      Value<String?> thumbnailUrl,
      Value<int> sortOrder,
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
      Value<String?> thumbnailUrl,
      Value<int> sortOrder,
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

  static MultiTypedResultKey<$SummaryCachesTable, List<SummaryCache>>
  _summaryCachesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.summaryCaches,
    aliasName: $_aliasNameGenerator(
      db.mnemataItems.id,
      db.summaryCaches.itemId,
    ),
  );

  $$SummaryCachesTableProcessedTableManager get summaryCachesRefs {
    final manager = $$SummaryCachesTableTableManager(
      $_db,
      $_db.summaryCaches,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_summaryCachesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $SemanticIndexStatesTable,
    List<SemanticIndexState>
  >
  _semanticIndexStatesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.semanticIndexStates,
        aliasName: $_aliasNameGenerator(
          db.mnemataItems.id,
          db.semanticIndexStates.itemId,
        ),
      );

  $$SemanticIndexStatesTableProcessedTableManager get semanticIndexStatesRefs {
    final manager = $$SemanticIndexStatesTableTableManager(
      $_db,
      $_db.semanticIndexStates,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _semanticIndexStatesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SemanticChunksTable, List<SemanticChunk>>
  _semanticChunksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.semanticChunks,
    aliasName: $_aliasNameGenerator(
      db.mnemataItems.id,
      db.semanticChunks.itemId,
    ),
  );

  $$SemanticChunksTableProcessedTableManager get semanticChunksRefs {
    final manager = $$SemanticChunksTableTableManager(
      $_db,
      $_db.semanticChunks,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_semanticChunksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AnnotationRecordsTable, List<AnnotationRecord>>
  _annotationRecordsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.annotationRecords,
        aliasName: $_aliasNameGenerator(
          db.mnemataItems.id,
          db.annotationRecords.itemId,
        ),
      );

  $$AnnotationRecordsTableProcessedTableManager get annotationRecordsRefs {
    final manager = $$AnnotationRecordsTableTableManager(
      $_db,
      $_db.annotationRecords,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _annotationRecordsRefsTable($_db),
    );
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

  ColumnFilters<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
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

  Expression<bool> summaryCachesRefs(
    Expression<bool> Function($$SummaryCachesTableFilterComposer f) f,
  ) {
    final $$SummaryCachesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.summaryCaches,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SummaryCachesTableFilterComposer(
            $db: $db,
            $table: $db.summaryCaches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> semanticIndexStatesRefs(
    Expression<bool> Function($$SemanticIndexStatesTableFilterComposer f) f,
  ) {
    final $$SemanticIndexStatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.semanticIndexStates,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemanticIndexStatesTableFilterComposer(
            $db: $db,
            $table: $db.semanticIndexStates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> semanticChunksRefs(
    Expression<bool> Function($$SemanticChunksTableFilterComposer f) f,
  ) {
    final $$SemanticChunksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.semanticChunks,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemanticChunksTableFilterComposer(
            $db: $db,
            $table: $db.semanticChunks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> annotationRecordsRefs(
    Expression<bool> Function($$AnnotationRecordsTableFilterComposer f) f,
  ) {
    final $$AnnotationRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.annotationRecords,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnnotationRecordsTableFilterComposer(
            $db: $db,
            $table: $db.annotationRecords,
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

  ColumnOrderings<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
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

  GeneratedColumn<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

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

  Expression<T> summaryCachesRefs<T extends Object>(
    Expression<T> Function($$SummaryCachesTableAnnotationComposer a) f,
  ) {
    final $$SummaryCachesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.summaryCaches,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SummaryCachesTableAnnotationComposer(
            $db: $db,
            $table: $db.summaryCaches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> semanticIndexStatesRefs<T extends Object>(
    Expression<T> Function($$SemanticIndexStatesTableAnnotationComposer a) f,
  ) {
    final $$SemanticIndexStatesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.semanticIndexStates,
          getReferencedColumn: (t) => t.itemId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SemanticIndexStatesTableAnnotationComposer(
                $db: $db,
                $table: $db.semanticIndexStates,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> semanticChunksRefs<T extends Object>(
    Expression<T> Function($$SemanticChunksTableAnnotationComposer a) f,
  ) {
    final $$SemanticChunksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.semanticChunks,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemanticChunksTableAnnotationComposer(
            $db: $db,
            $table: $db.semanticChunks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> annotationRecordsRefs<T extends Object>(
    Expression<T> Function($$AnnotationRecordsTableAnnotationComposer a) f,
  ) {
    final $$AnnotationRecordsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.annotationRecords,
          getReferencedColumn: (t) => t.itemId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AnnotationRecordsTableAnnotationComposer(
                $db: $db,
                $table: $db.annotationRecords,
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
          PrefetchHooks Function({
            bool itemLabelsRefs,
            bool summaryCachesRefs,
            bool semanticIndexStatesRefs,
            bool semanticChunksRefs,
            bool annotationRecordsRefs,
          })
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
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => MnemataItemsCompanion(
                id: id,
                title: title,
                url: url,
                filePath: filePath,
                content: content,
                type: type,
                createdAt: createdAt,
                lastOpenedAt: lastOpenedAt,
                thumbnailUrl: thumbnailUrl,
                sortOrder: sortOrder,
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
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => MnemataItemsCompanion.insert(
                id: id,
                title: title,
                url: url,
                filePath: filePath,
                content: content,
                type: type,
                createdAt: createdAt,
                lastOpenedAt: lastOpenedAt,
                thumbnailUrl: thumbnailUrl,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MnemataItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                itemLabelsRefs = false,
                summaryCachesRefs = false,
                semanticIndexStatesRefs = false,
                semanticChunksRefs = false,
                annotationRecordsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (itemLabelsRefs) db.itemLabels,
                    if (summaryCachesRefs) db.summaryCaches,
                    if (semanticIndexStatesRefs) db.semanticIndexStates,
                    if (semanticChunksRefs) db.semanticChunks,
                    if (annotationRecordsRefs) db.annotationRecords,
                  ],
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
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.itemId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (summaryCachesRefs)
                        await $_getPrefetchedData<
                          MnemataItem,
                          $MnemataItemsTable,
                          SummaryCache
                        >(
                          currentTable: table,
                          referencedTable: $$MnemataItemsTableReferences
                              ._summaryCachesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MnemataItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).summaryCachesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.itemId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (semanticIndexStatesRefs)
                        await $_getPrefetchedData<
                          MnemataItem,
                          $MnemataItemsTable,
                          SemanticIndexState
                        >(
                          currentTable: table,
                          referencedTable: $$MnemataItemsTableReferences
                              ._semanticIndexStatesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MnemataItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).semanticIndexStatesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.itemId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (semanticChunksRefs)
                        await $_getPrefetchedData<
                          MnemataItem,
                          $MnemataItemsTable,
                          SemanticChunk
                        >(
                          currentTable: table,
                          referencedTable: $$MnemataItemsTableReferences
                              ._semanticChunksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MnemataItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).semanticChunksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.itemId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (annotationRecordsRefs)
                        await $_getPrefetchedData<
                          MnemataItem,
                          $MnemataItemsTable,
                          AnnotationRecord
                        >(
                          currentTable: table,
                          referencedTable: $$MnemataItemsTableReferences
                              ._annotationRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MnemataItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).annotationRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.itemId == item.id,
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
      PrefetchHooks Function({
        bool itemLabelsRefs,
        bool summaryCachesRefs,
        bool semanticIndexStatesRefs,
        bool semanticChunksRefs,
        bool annotationRecordsRefs,
      })
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
typedef $$SummaryCachesTableCreateCompanionBuilder =
    SummaryCachesCompanion Function({
      Value<int> id,
      required int itemId,
      required String contentHash,
      required String tldr,
      required String keyPointsJson,
      required String whyItMatters,
      Value<DateTime> createdAt,
    });
typedef $$SummaryCachesTableUpdateCompanionBuilder =
    SummaryCachesCompanion Function({
      Value<int> id,
      Value<int> itemId,
      Value<String> contentHash,
      Value<String> tldr,
      Value<String> keyPointsJson,
      Value<String> whyItMatters,
      Value<DateTime> createdAt,
    });

final class $$SummaryCachesTableReferences
    extends BaseReferences<_$AppDatabase, $SummaryCachesTable, SummaryCache> {
  $$SummaryCachesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $MnemataItemsTable _itemIdTable(_$AppDatabase db) =>
      db.mnemataItems.createAlias(
        $_aliasNameGenerator(db.summaryCaches.itemId, db.mnemataItems.id),
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
}

class $$SummaryCachesTableFilterComposer
    extends Composer<_$AppDatabase, $SummaryCachesTable> {
  $$SummaryCachesTableFilterComposer({
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

  ColumnFilters<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tldr => $composableBuilder(
    column: $table.tldr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get keyPointsJson => $composableBuilder(
    column: $table.keyPointsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get whyItMatters => $composableBuilder(
    column: $table.whyItMatters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

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
}

class $$SummaryCachesTableOrderingComposer
    extends Composer<_$AppDatabase, $SummaryCachesTable> {
  $$SummaryCachesTableOrderingComposer({
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

  ColumnOrderings<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tldr => $composableBuilder(
    column: $table.tldr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get keyPointsJson => $composableBuilder(
    column: $table.keyPointsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get whyItMatters => $composableBuilder(
    column: $table.whyItMatters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

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
}

class $$SummaryCachesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SummaryCachesTable> {
  $$SummaryCachesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tldr =>
      $composableBuilder(column: $table.tldr, builder: (column) => column);

  GeneratedColumn<String> get keyPointsJson => $composableBuilder(
    column: $table.keyPointsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get whyItMatters => $composableBuilder(
    column: $table.whyItMatters,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

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
}

class $$SummaryCachesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SummaryCachesTable,
          SummaryCache,
          $$SummaryCachesTableFilterComposer,
          $$SummaryCachesTableOrderingComposer,
          $$SummaryCachesTableAnnotationComposer,
          $$SummaryCachesTableCreateCompanionBuilder,
          $$SummaryCachesTableUpdateCompanionBuilder,
          (SummaryCache, $$SummaryCachesTableReferences),
          SummaryCache,
          PrefetchHooks Function({bool itemId})
        > {
  $$SummaryCachesTableTableManager(_$AppDatabase db, $SummaryCachesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SummaryCachesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SummaryCachesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SummaryCachesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> itemId = const Value.absent(),
                Value<String> contentHash = const Value.absent(),
                Value<String> tldr = const Value.absent(),
                Value<String> keyPointsJson = const Value.absent(),
                Value<String> whyItMatters = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SummaryCachesCompanion(
                id: id,
                itemId: itemId,
                contentHash: contentHash,
                tldr: tldr,
                keyPointsJson: keyPointsJson,
                whyItMatters: whyItMatters,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int itemId,
                required String contentHash,
                required String tldr,
                required String keyPointsJson,
                required String whyItMatters,
                Value<DateTime> createdAt = const Value.absent(),
              }) => SummaryCachesCompanion.insert(
                id: id,
                itemId: itemId,
                contentHash: contentHash,
                tldr: tldr,
                keyPointsJson: keyPointsJson,
                whyItMatters: whyItMatters,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SummaryCachesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false}) {
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
                                referencedTable: $$SummaryCachesTableReferences
                                    ._itemIdTable(db),
                                referencedColumn: $$SummaryCachesTableReferences
                                    ._itemIdTable(db)
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

typedef $$SummaryCachesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SummaryCachesTable,
      SummaryCache,
      $$SummaryCachesTableFilterComposer,
      $$SummaryCachesTableOrderingComposer,
      $$SummaryCachesTableAnnotationComposer,
      $$SummaryCachesTableCreateCompanionBuilder,
      $$SummaryCachesTableUpdateCompanionBuilder,
      (SummaryCache, $$SummaryCachesTableReferences),
      SummaryCache,
      PrefetchHooks Function({bool itemId})
    >;
typedef $$SemanticIndexStatesTableCreateCompanionBuilder =
    SemanticIndexStatesCompanion Function({
      Value<int> id,
      required int itemId,
      required String contentHash,
      required String embeddingModel,
      required int chunkCount,
      Value<DateTime> indexedAt,
    });
typedef $$SemanticIndexStatesTableUpdateCompanionBuilder =
    SemanticIndexStatesCompanion Function({
      Value<int> id,
      Value<int> itemId,
      Value<String> contentHash,
      Value<String> embeddingModel,
      Value<int> chunkCount,
      Value<DateTime> indexedAt,
    });

final class $$SemanticIndexStatesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $SemanticIndexStatesTable,
          SemanticIndexState
        > {
  $$SemanticIndexStatesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $MnemataItemsTable _itemIdTable(_$AppDatabase db) =>
      db.mnemataItems.createAlias(
        $_aliasNameGenerator(db.semanticIndexStates.itemId, db.mnemataItems.id),
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
}

class $$SemanticIndexStatesTableFilterComposer
    extends Composer<_$AppDatabase, $SemanticIndexStatesTable> {
  $$SemanticIndexStatesTableFilterComposer({
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

  ColumnFilters<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get embeddingModel => $composableBuilder(
    column: $table.embeddingModel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chunkCount => $composableBuilder(
    column: $table.chunkCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get indexedAt => $composableBuilder(
    column: $table.indexedAt,
    builder: (column) => ColumnFilters(column),
  );

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
}

class $$SemanticIndexStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $SemanticIndexStatesTable> {
  $$SemanticIndexStatesTableOrderingComposer({
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

  ColumnOrderings<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get embeddingModel => $composableBuilder(
    column: $table.embeddingModel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chunkCount => $composableBuilder(
    column: $table.chunkCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get indexedAt => $composableBuilder(
    column: $table.indexedAt,
    builder: (column) => ColumnOrderings(column),
  );

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
}

class $$SemanticIndexStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SemanticIndexStatesTable> {
  $$SemanticIndexStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get embeddingModel => $composableBuilder(
    column: $table.embeddingModel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get chunkCount => $composableBuilder(
    column: $table.chunkCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get indexedAt =>
      $composableBuilder(column: $table.indexedAt, builder: (column) => column);

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
}

class $$SemanticIndexStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SemanticIndexStatesTable,
          SemanticIndexState,
          $$SemanticIndexStatesTableFilterComposer,
          $$SemanticIndexStatesTableOrderingComposer,
          $$SemanticIndexStatesTableAnnotationComposer,
          $$SemanticIndexStatesTableCreateCompanionBuilder,
          $$SemanticIndexStatesTableUpdateCompanionBuilder,
          (SemanticIndexState, $$SemanticIndexStatesTableReferences),
          SemanticIndexState,
          PrefetchHooks Function({bool itemId})
        > {
  $$SemanticIndexStatesTableTableManager(
    _$AppDatabase db,
    $SemanticIndexStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SemanticIndexStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SemanticIndexStatesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SemanticIndexStatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> itemId = const Value.absent(),
                Value<String> contentHash = const Value.absent(),
                Value<String> embeddingModel = const Value.absent(),
                Value<int> chunkCount = const Value.absent(),
                Value<DateTime> indexedAt = const Value.absent(),
              }) => SemanticIndexStatesCompanion(
                id: id,
                itemId: itemId,
                contentHash: contentHash,
                embeddingModel: embeddingModel,
                chunkCount: chunkCount,
                indexedAt: indexedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int itemId,
                required String contentHash,
                required String embeddingModel,
                required int chunkCount,
                Value<DateTime> indexedAt = const Value.absent(),
              }) => SemanticIndexStatesCompanion.insert(
                id: id,
                itemId: itemId,
                contentHash: contentHash,
                embeddingModel: embeddingModel,
                chunkCount: chunkCount,
                indexedAt: indexedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SemanticIndexStatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false}) {
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
                                referencedTable:
                                    $$SemanticIndexStatesTableReferences
                                        ._itemIdTable(db),
                                referencedColumn:
                                    $$SemanticIndexStatesTableReferences
                                        ._itemIdTable(db)
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

typedef $$SemanticIndexStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SemanticIndexStatesTable,
      SemanticIndexState,
      $$SemanticIndexStatesTableFilterComposer,
      $$SemanticIndexStatesTableOrderingComposer,
      $$SemanticIndexStatesTableAnnotationComposer,
      $$SemanticIndexStatesTableCreateCompanionBuilder,
      $$SemanticIndexStatesTableUpdateCompanionBuilder,
      (SemanticIndexState, $$SemanticIndexStatesTableReferences),
      SemanticIndexState,
      PrefetchHooks Function({bool itemId})
    >;
typedef $$SemanticChunksTableCreateCompanionBuilder =
    SemanticChunksCompanion Function({
      Value<int> id,
      required int itemId,
      required int chunkIndex,
      required String chunkText,
      required String embeddingVectorJson,
    });
typedef $$SemanticChunksTableUpdateCompanionBuilder =
    SemanticChunksCompanion Function({
      Value<int> id,
      Value<int> itemId,
      Value<int> chunkIndex,
      Value<String> chunkText,
      Value<String> embeddingVectorJson,
    });

final class $$SemanticChunksTableReferences
    extends BaseReferences<_$AppDatabase, $SemanticChunksTable, SemanticChunk> {
  $$SemanticChunksTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $MnemataItemsTable _itemIdTable(_$AppDatabase db) =>
      db.mnemataItems.createAlias(
        $_aliasNameGenerator(db.semanticChunks.itemId, db.mnemataItems.id),
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
}

class $$SemanticChunksTableFilterComposer
    extends Composer<_$AppDatabase, $SemanticChunksTable> {
  $$SemanticChunksTableFilterComposer({
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

  ColumnFilters<int> get chunkIndex => $composableBuilder(
    column: $table.chunkIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get chunkText => $composableBuilder(
    column: $table.chunkText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get embeddingVectorJson => $composableBuilder(
    column: $table.embeddingVectorJson,
    builder: (column) => ColumnFilters(column),
  );

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
}

class $$SemanticChunksTableOrderingComposer
    extends Composer<_$AppDatabase, $SemanticChunksTable> {
  $$SemanticChunksTableOrderingComposer({
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

  ColumnOrderings<int> get chunkIndex => $composableBuilder(
    column: $table.chunkIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chunkText => $composableBuilder(
    column: $table.chunkText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get embeddingVectorJson => $composableBuilder(
    column: $table.embeddingVectorJson,
    builder: (column) => ColumnOrderings(column),
  );

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
}

class $$SemanticChunksTableAnnotationComposer
    extends Composer<_$AppDatabase, $SemanticChunksTable> {
  $$SemanticChunksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get chunkIndex => $composableBuilder(
    column: $table.chunkIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get chunkText =>
      $composableBuilder(column: $table.chunkText, builder: (column) => column);

  GeneratedColumn<String> get embeddingVectorJson => $composableBuilder(
    column: $table.embeddingVectorJson,
    builder: (column) => column,
  );

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
}

class $$SemanticChunksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SemanticChunksTable,
          SemanticChunk,
          $$SemanticChunksTableFilterComposer,
          $$SemanticChunksTableOrderingComposer,
          $$SemanticChunksTableAnnotationComposer,
          $$SemanticChunksTableCreateCompanionBuilder,
          $$SemanticChunksTableUpdateCompanionBuilder,
          (SemanticChunk, $$SemanticChunksTableReferences),
          SemanticChunk,
          PrefetchHooks Function({bool itemId})
        > {
  $$SemanticChunksTableTableManager(
    _$AppDatabase db,
    $SemanticChunksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SemanticChunksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SemanticChunksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SemanticChunksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> itemId = const Value.absent(),
                Value<int> chunkIndex = const Value.absent(),
                Value<String> chunkText = const Value.absent(),
                Value<String> embeddingVectorJson = const Value.absent(),
              }) => SemanticChunksCompanion(
                id: id,
                itemId: itemId,
                chunkIndex: chunkIndex,
                chunkText: chunkText,
                embeddingVectorJson: embeddingVectorJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int itemId,
                required int chunkIndex,
                required String chunkText,
                required String embeddingVectorJson,
              }) => SemanticChunksCompanion.insert(
                id: id,
                itemId: itemId,
                chunkIndex: chunkIndex,
                chunkText: chunkText,
                embeddingVectorJson: embeddingVectorJson,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SemanticChunksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false}) {
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
                                referencedTable: $$SemanticChunksTableReferences
                                    ._itemIdTable(db),
                                referencedColumn:
                                    $$SemanticChunksTableReferences
                                        ._itemIdTable(db)
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

typedef $$SemanticChunksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SemanticChunksTable,
      SemanticChunk,
      $$SemanticChunksTableFilterComposer,
      $$SemanticChunksTableOrderingComposer,
      $$SemanticChunksTableAnnotationComposer,
      $$SemanticChunksTableCreateCompanionBuilder,
      $$SemanticChunksTableUpdateCompanionBuilder,
      (SemanticChunk, $$SemanticChunksTableReferences),
      SemanticChunk,
      PrefetchHooks Function({bool itemId})
    >;
typedef $$AnnotationRecordsTableCreateCompanionBuilder =
    AnnotationRecordsCompanion Function({
      Value<int> id,
      required int itemId,
      required String quoteText,
      required String anchorJson,
      Value<String?> note,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
    });
typedef $$AnnotationRecordsTableUpdateCompanionBuilder =
    AnnotationRecordsCompanion Function({
      Value<int> id,
      Value<int> itemId,
      Value<String> quoteText,
      Value<String> anchorJson,
      Value<String?> note,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
    });

final class $$AnnotationRecordsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $AnnotationRecordsTable,
          AnnotationRecord
        > {
  $$AnnotationRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $MnemataItemsTable _itemIdTable(_$AppDatabase db) =>
      db.mnemataItems.createAlias(
        $_aliasNameGenerator(db.annotationRecords.itemId, db.mnemataItems.id),
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
}

class $$AnnotationRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $AnnotationRecordsTable> {
  $$AnnotationRecordsTableFilterComposer({
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

  ColumnFilters<String> get quoteText => $composableBuilder(
    column: $table.quoteText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get anchorJson => $composableBuilder(
    column: $table.anchorJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

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
}

class $$AnnotationRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $AnnotationRecordsTable> {
  $$AnnotationRecordsTableOrderingComposer({
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

  ColumnOrderings<String> get quoteText => $composableBuilder(
    column: $table.quoteText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get anchorJson => $composableBuilder(
    column: $table.anchorJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

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
}

class $$AnnotationRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AnnotationRecordsTable> {
  $$AnnotationRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get quoteText =>
      $composableBuilder(column: $table.quoteText, builder: (column) => column);

  GeneratedColumn<String> get anchorJson => $composableBuilder(
    column: $table.anchorJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

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
}

class $$AnnotationRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AnnotationRecordsTable,
          AnnotationRecord,
          $$AnnotationRecordsTableFilterComposer,
          $$AnnotationRecordsTableOrderingComposer,
          $$AnnotationRecordsTableAnnotationComposer,
          $$AnnotationRecordsTableCreateCompanionBuilder,
          $$AnnotationRecordsTableUpdateCompanionBuilder,
          (AnnotationRecord, $$AnnotationRecordsTableReferences),
          AnnotationRecord,
          PrefetchHooks Function({bool itemId})
        > {
  $$AnnotationRecordsTableTableManager(
    _$AppDatabase db,
    $AnnotationRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnnotationRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnnotationRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnnotationRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> itemId = const Value.absent(),
                Value<String> quoteText = const Value.absent(),
                Value<String> anchorJson = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
              }) => AnnotationRecordsCompanion(
                id: id,
                itemId: itemId,
                quoteText: quoteText,
                anchorJson: anchorJson,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int itemId,
                required String quoteText,
                required String anchorJson,
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
              }) => AnnotationRecordsCompanion.insert(
                id: id,
                itemId: itemId,
                quoteText: quoteText,
                anchorJson: anchorJson,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AnnotationRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false}) {
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
                                referencedTable:
                                    $$AnnotationRecordsTableReferences
                                        ._itemIdTable(db),
                                referencedColumn:
                                    $$AnnotationRecordsTableReferences
                                        ._itemIdTable(db)
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

typedef $$AnnotationRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AnnotationRecordsTable,
      AnnotationRecord,
      $$AnnotationRecordsTableFilterComposer,
      $$AnnotationRecordsTableOrderingComposer,
      $$AnnotationRecordsTableAnnotationComposer,
      $$AnnotationRecordsTableCreateCompanionBuilder,
      $$AnnotationRecordsTableUpdateCompanionBuilder,
      (AnnotationRecord, $$AnnotationRecordsTableReferences),
      AnnotationRecord,
      PrefetchHooks Function({bool itemId})
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
  $$SummaryCachesTableTableManager get summaryCaches =>
      $$SummaryCachesTableTableManager(_db, _db.summaryCaches);
  $$SemanticIndexStatesTableTableManager get semanticIndexStates =>
      $$SemanticIndexStatesTableTableManager(_db, _db.semanticIndexStates);
  $$SemanticChunksTableTableManager get semanticChunks =>
      $$SemanticChunksTableTableManager(_db, _db.semanticChunks);
  $$AnnotationRecordsTableTableManager get annotationRecords =>
      $$AnnotationRecordsTableTableManager(_db, _db.annotationRecords);
}
