import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:mnemata/core/database/tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [MnemataItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'mnemata_db');
  }

  Stream<List<MnemataItem>> watchAllItems() {
    return (select(mnemataItems)
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }

  Future<int> insertItem(MnemataItemsCompanion item) {
    return into(mnemataItems).insert(item);
  }
}
