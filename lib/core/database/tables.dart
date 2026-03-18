import 'package:drift/drift.dart';

class MnemataItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().nullable()();
  TextColumn get url => text().nullable()();
  TextColumn get filePath => text().nullable()();
  TextColumn get type => text()(); // 'url' or 'file'
  DateTimeColumn get createdAt => dateTime()();
}
