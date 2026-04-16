import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:sqlite3/open.dart';

void main() {
  late AppDatabase database;

  setUpAll(() {
    if (Platform.isLinux) {
      open.overrideFor(
        OperatingSystem.linux,
        () => DynamicLibrary.open('libsqlite3.so.0'),
      );
    }
  });

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('deleteItem soft-deletes row and removes from active stream', () async {
    final itemId = await database.insertItem(
      MnemataItemsCompanion.insert(
        title: const drift.Value('Recycle me'),
        type: 'url',
        createdAt: DateTime.utc(2026, 4, 16),
      ),
    );

    await database.deleteItem(itemId);

    final activeItems = await database.watchAllItems().first;
    expect(activeItems.where((item) => item.id == itemId), isEmpty);

    final recycleItems = await database.watchRecycleBinItems().first;
    expect(recycleItems.map((item) => item.id), contains(itemId));
    expect(recycleItems.single.deletedAt, isNotNull);
  });

  test('deleteItems soft-deletes all ids in batch', () async {
    final firstId = await database.insertItem(
      MnemataItemsCompanion.insert(
        title: const drift.Value('A'),
        type: 'url',
        createdAt: DateTime.utc(2026, 4, 16, 10),
      ),
    );
    final secondId = await database.insertItem(
      MnemataItemsCompanion.insert(
        title: const drift.Value('B'),
        type: 'url',
        createdAt: DateTime.utc(2026, 4, 16, 11),
      ),
    );

    await database.deleteItems(<int>[firstId, secondId]);

    final activeItems = await database.watchAllItems().first;
    expect(activeItems, isEmpty);

    final recycleItems = await database.watchRecycleBinItems().first;
    expect(recycleItems.map((item) => item.id).toSet(),
        equals(<int>{firstId, secondId}));
  });
}
