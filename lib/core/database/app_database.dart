import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:mnemata/core/database/tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [MnemataItems, Labels, ItemLabels], include: {'tables.drift'})
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await m.addColumn(mnemataItems, mnemataItems.content);
          await m.create(mnemataSearch);
        }
        if (from < 3) {
          await m.addColumn(mnemataItems, mnemataItems.lastOpenedAt);
          await m.createTable(labels);
          await m.createTable(itemLabels);
        }
      },
    );
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'mnemata_db');
  }

  Stream<List<MnemataItem>> watchAllItems() {
    return (select(mnemataItems)
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }

  Stream<List<MnemataItem>> watchRecentlyOpened(int limit) {
    return (select(mnemataItems)
          ..where((t) => t.lastOpenedAt.isNotNull())
          ..orderBy([(t) => OrderingTerm(expression: t.lastOpenedAt, mode: OrderingMode.desc)])
          ..limit(limit))
        .watch();
  }

  Future<int> insertItem(MnemataItemsCompanion item) {
    return into(mnemataItems).insert(item);
  }

  Future<int> deleteItem(int id) {
    return (delete(mnemataItems)..where((t) => t.id.equals(id))).go();
  }

  Future<void> updateItemContent(int id, String content, String? title) {
    return (update(mnemataItems)..where((t) => t.id.equals(id))).write(
      MnemataItemsCompanion(
        content: Value(content),
        title: title != null ? Value(title) : const Value.absent(),
      ),
    );
  }

  Future<void> updateLastOpenedAt(int id) {
    return (update(mnemataItems)..where((t) => t.id.equals(id))).write(
      MnemataItemsCompanion(
        lastOpenedAt: Value(DateTime.now()),
      ),
    );
  }

  // Label Operations
  Future<int> insertLabel(LabelsCompanion label) => into(labels).insert(label);
  Future<bool> updateLabel(LabelsCompanion label) => update(labels).replace(label);
  Future<int> deleteLabel(int id) => (delete(labels)..where((t) => t.id.equals(id))).go();

  Stream<List<Label>> watchAllLabels() {
    return (select(labels)..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .watch();
  }

  // Item Label Operations
  Future<void> assignLabelToItem(int itemId, int labelId) {
    return into(itemLabels).insert(
      ItemLabelsCompanion.insert(itemId: itemId, labelId: labelId),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<int> removeLabelFromItem(int itemId, int labelId) {
    return (delete(itemLabels)
          ..where((t) => t.itemId.equals(itemId) & t.labelId.equals(labelId)))
        .go();
  }

  Stream<List<Label>> watchLabelsForItem(int itemId) {
    final query = select(labels).join([
      innerJoin(itemLabels, itemLabels.labelId.equalsExp(labels.id)),
    ])
      ..where(itemLabels.itemId.equals(itemId));

    return query.watch().map((rows) {
      return rows.map((row) => row.readTable(labels)).toList();
    });
  }

  Stream<List<MnemataItem>> watchItemsByLabel(int labelId) {
    final query = select(mnemataItems).join([
      innerJoin(itemLabels, itemLabels.itemId.equalsExp(mnemataItems.id)),
    ])
      ..where(itemLabels.labelId.equals(labelId))
      ..orderBy([OrderingTerm(expression: mnemataItems.createdAt, mode: OrderingMode.desc)]);

    return query.watch().map((rows) {
      return rows.map((row) => row.readTable(mnemataItems)).toList();
    });
  }

  Stream<List<MnemataItem>> searchItems(String query) {
    return customSelect(
      'SELECT i.* FROM mnemata_items i '
      'INNER JOIN mnemata_search s ON s.rowid = i.id '
      'WHERE mnemata_search MATCH ?',
      variables: [Variable(query)],
      readsFrom: {mnemataItems, mnemataSearch},
    ).watch().map((rows) {
      return rows.map((row) => mnemataItems.map(row.data)).toList();
    });
  }
}
