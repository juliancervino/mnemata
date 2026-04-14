import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/features/intelligence/services/api_key_store.dart';
import 'package:mnemata/features/intelligence/services/semantic_indexer_service.dart';
import 'package:sqlite3/open.dart';

class _Store implements SecureKeyValueStore {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<void> delete(String key) async => _values.remove(key);

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write({required String key, required String value}) async {
    _values[key] = value;
  }
}

void main() {
  late AppDatabase database;
  late ApiKeyStore keyStore;
  late MnemataItem item;

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
    keyStore = ApiKeyStore(secureStore: _Store());

    final itemId = await database.insertItem(
      MnemataItemsCompanion.insert(
        title: const drift.Value('Semantic article'),
        url: const drift.Value('https://example.com/article'),
        content: const drift.Value('Automobile research with concept relationships.'),
        type: 'url',
        createdAt: DateTime.now(),
      ),
    );
    item = (await database.watchAllItems().first).firstWhere((i) => i.id == itemId);
  });

  tearDown(() async {
    await database.close();
  });

  test('indexer schedules/upserts semantic chunks asynchronously', () async {
    await keyStore.saveKey('abc');
    var calls = 0;
    final service = SemanticIndexerService(
      database: database,
      apiKeyStore: keyStore,
      embeddingGenerator: (text) async {
        calls += 1;
        return <double>[text.length / 100, 0.2, 0.3];
      },
    );

    await service.enqueueIndexing(item);
    await service.flushPending();

    final chunks = await database.readSemanticChunks(item.id);
    final state = await database.readSemanticIndexState(item.id);

    expect(calls, greaterThan(0));
    expect(chunks, isNotEmpty);
    expect(state, isNotNull);
    expect(state!.chunkCount, chunks.length);
  });
}
