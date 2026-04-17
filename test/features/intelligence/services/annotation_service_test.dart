import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/features/intelligence/services/annotation_service.dart';
import 'package:sqlite3/open.dart';

void main() {
  late AppDatabase database;
  late AnnotationService service;
  late int itemId;

  setUpAll(() {
    if (Platform.isLinux) {
      open.overrideFor(
        OperatingSystem.linux,
        () => DynamicLibrary.open('libsqlite3.so.0'),
      );
    }
  });

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    service = AnnotationService(database: database);
    itemId = await database.insertItem(
      MnemataItemsCompanion.insert(
        title: const drift.Value('Annotated article'),
        url: const drift.Value('https://example.com/annotated'),
        content: const drift.Value('Alpha beta gamma delta epsilon zeta.'),
        type: 'url',
        createdAt: DateTime.now(),
      ),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('creating annotation persists itemId + quote + anchor + optional note', () async {
    final id = await service.createAnnotation(
      itemId: itemId,
      quoteText: 'beta gamma',
      anchorJson: jsonEncode(<String, dynamic>{'start': 6, 'end': 16}),
      note: 'important',
    );

    final records = await service.listForItem(itemId);
    expect(records.any((r) => r.id == id), isTrue);
    expect(records.first.quoteText, 'beta gamma');
    expect(records.first.note, 'important');
  });

  test('reading annotations returns stable ordering for UI list', () async {
    await service.createAnnotation(
      itemId: itemId,
      quoteText: 'alpha',
      anchorJson: jsonEncode(<String, dynamic>{'start': 0, 'end': 5}),
    );
    await service.createAnnotation(
      itemId: itemId,
      quoteText: 'delta',
      anchorJson: jsonEncode(<String, dynamic>{'start': 18, 'end': 23}),
    );

    final records = await service.listForItem(itemId);
    expect(records.map((r) => r.quoteText).toList(), <String>['alpha', 'delta']);
  });

  test('deleting parent item cascades and removes annotation records', () async {
    await service.createAnnotation(
      itemId: itemId,
      quoteText: 'gamma',
      anchorJson: jsonEncode(<String, dynamic>{'start': 12, 'end': 17}),
    );

    await database.permanentlyDeleteItem(itemId);
    final records = await service.listForItem(itemId);

    expect(records, isEmpty);
  });
}
