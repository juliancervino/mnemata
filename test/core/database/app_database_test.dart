import 'dart:ffi';
import 'dart:io';
import 'package:sqlite3/open.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:drift/drift.dart';

void main() {
  late AppDatabase database;

  setUpAll(() {
    if (Platform.isLinux) {
      // Use the standard shared library name for sqlite3 on Linux
      // FTS5 is usually enabled in modern sqlite3 distributions
      open.overrideFor(OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
    }
  });

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('MnemataItems can be inserted and watched', () async {
    final item = MnemataItemsCompanion.insert(
      title: const Value('Test Item'),
      type: 'url',
      createdAt: DateTime.now(),
    );

    await database.insertItem(item);

    final items = await database.watchAllItems().first;
    expect(items.length, 1);
    expect(items.first.title, 'Test Item');
  });

  test('Search finds items by title or content', () async {
    final now = DateTime.now();
    await database.insertItem(MnemataItemsCompanion.insert(
      title: const Value('Flutter Development'),
      content: const Value('Learning how to build cross-platform apps.'),
      type: 'url',
      createdAt: now,
    ));
    await database.insertItem(MnemataItemsCompanion.insert(
      title: const Value('SQLite FTS5'),
      content: const Value('Powerful full-text search engine.'),
      type: 'url',
      createdAt: now,
    ));

    // Search by title
    var results = await database.searchItems('Flutter').first;
    expect(results.length, 1);
    expect(results.first.title, 'Flutter Development');

    // Search by content
    results = await database.searchItems('Powerful').first;
    expect(results.length, 1);
    expect(results.first.title, 'SQLite FTS5');
    
    // Search by partial/stemmed word (if porter tokenizer works)
    results = await database.searchItems('learn').first;
    expect(results.length, 1);
    expect(results.first.title, 'Flutter Development');
  });

  test('updateItemContent updates content and title correctly', () async {
    final now = DateTime.now();
    final id = await database.insertItem(MnemataItemsCompanion.insert(
      url: const Value('https://example.com'),
      type: 'url',
      createdAt: now,
    ));

    await database.updateItemContent(id, 'Updated Content', 'Updated Title');

    final items = await database.watchAllItems().first;
    expect(items.length, 1);
    expect(items.first.title, 'Updated Title');
    expect(items.first.content, 'Updated Content');
    
    // Verify FTS update
    final results = await database.searchItems('Updated').first;
    expect(results.length, 1);
  });

  test('MnemataItems are sorted by createdAt descending', () async {
    final now = DateTime.now();
    final item1 = MnemataItemsCompanion.insert(
      title: const Value('Old Item'),
      type: 'url',
      createdAt: now.subtract(const Duration(days: 1)),
    );
    final item2 = MnemataItemsCompanion.insert(
      title: const Value('New Item'),
      type: 'url',
      createdAt: now,
    );

    await database.insertItem(item1);
    await database.insertItem(item2);

    final items = await database.watchAllItems().first;
    expect(items.length, 2);
    expect(items.first.title, 'New Item');
    expect(items.last.title, 'Old Item');
  });
}
