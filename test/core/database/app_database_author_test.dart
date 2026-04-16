import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:sqlite3/open.dart';

void main() {
  setUpAll(() {
    if (Platform.isLinux) {
      open.overrideFor(
        OperatingSystem.linux,
        () => DynamicLibrary.open('libsqlite3.so.0'),
      );
    }
  });

  group('author persistence', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    test('stores and reads author field on insert', () async {
      final itemId = await database.insertItem(
        MnemataItemsCompanion.insert(
          title: const Value('Author test'),
          author: const Value('Ada Lovelace'),
          type: 'url',
          createdAt: DateTime.now(),
        ),
      );

      final items = await database.getItemsByIds(<int>[itemId]);

      expect(items.single.author, 'Ada Lovelace');
    });
  });

  group('author migration', () {
    test('adds nullable author column while preserving existing rows', () async {
      final executor = NativeDatabase.memory(
        setup: (rawDb) {
          rawDb.execute('''
            CREATE TABLE mnemata_items (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              title TEXT,
              url TEXT,
              file_path TEXT,
              content TEXT,
              type TEXT NOT NULL,
              created_at INTEGER NOT NULL,
              last_opened_at INTEGER,
              thumbnail_url TEXT,
              sort_order INTEGER NOT NULL DEFAULT 0
            );
          ''');
          rawDb.execute(
            "INSERT INTO mnemata_items (title, type, created_at, sort_order) VALUES ('legacy', 'url', 1713225600000, 0);",
          );
          rawDb.execute('PRAGMA user_version = 7;');
        },
      );

      final database = AppDatabase.forTesting(executor);
      addTearDown(() async => database.close());

      final rows = await database.customSelect(
        'PRAGMA table_info(mnemata_items);',
      ).get();
      final hasAuthorColumn = rows.any(
        (row) => row.data['name'] == 'author',
      );

      final item = await database.watchAllItems().first;

      expect(hasAuthorColumn, isTrue);
      expect(item.single.title, 'legacy');
      expect(item.single.author, isNull);
    });
  });
}