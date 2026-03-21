import 'package:drift/drift.dart';

class MnemataItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().nullable()();
  TextColumn get url => text().nullable()();
  TextColumn get filePath => text().nullable()();
  TextColumn get content => text().nullable()(); // Extracted article content
  TextColumn get type => text()(); // 'url' or 'file'
  DateTimeColumn get createdAt => dateTime()();
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
