import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:drift/drift.dart';

void main() {
  late AppDatabase database;

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
