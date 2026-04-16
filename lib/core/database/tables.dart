import 'package:drift/drift.dart';

class MnemataItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().nullable()();
  TextColumn get url => text().nullable()();
  TextColumn get filePath => text().nullable()();
  TextColumn get content => text().nullable()(); // Extracted article content
  TextColumn get author => text().nullable()();
  TextColumn get type => text()(); // 'url' or 'file'
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get lastOpenedAt => dateTime().nullable()();
  TextColumn get thumbnailUrl => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

class Labels extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get color => integer().nullable()();
  IntColumn get parentId => integer().nullable().references(Labels, #id)();
  BoolColumn get isFolder => boolean().withDefault(const Constant(false))();
}

class ItemLabels extends Table {
  IntColumn get itemId => integer().references(MnemataItems, #id)();
  IntColumn get labelId => integer().references(Labels, #id)();

  @override
  Set<Column> get primaryKey => {itemId, labelId};
}

class SummaryCaches extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get itemId =>
      integer().references(MnemataItems, #id, onDelete: KeyAction.cascade)();
  TextColumn get contentHash => text()();
  TextColumn get tldr => text()();
  TextColumn get keyPointsJson => text()();
  TextColumn get whyItMatters => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {itemId, contentHash},
  ];
}

class SemanticIndexStates extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get itemId =>
      integer().references(MnemataItems, #id, onDelete: KeyAction.cascade)();
  TextColumn get contentHash => text()();
  TextColumn get embeddingModel => text()();
  IntColumn get chunkCount => integer()();
  DateTimeColumn get indexedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {itemId},
  ];
}

class SemanticChunks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get itemId =>
      integer().references(MnemataItems, #id, onDelete: KeyAction.cascade)();
  IntColumn get chunkIndex => integer()();
  TextColumn get chunkText => text()();
  TextColumn get embeddingVectorJson => text()();
}

class AnnotationRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get itemId =>
      integer().references(MnemataItems, #id, onDelete: KeyAction.cascade)();
  TextColumn get quoteText => text()();
  TextColumn get anchorJson => text()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}
