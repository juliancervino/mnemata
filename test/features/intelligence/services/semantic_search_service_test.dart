import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/features/intelligence/services/api_key_store.dart';
import 'package:mnemata/features/intelligence/services/semantic_indexer_service.dart';
import 'package:mnemata/features/intelligence/services/semantic_search_service.dart';
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

    await database.insertItem(
      MnemataItemsCompanion.insert(
        title: const Value('Automobile engineering notes'),
        url: const Value('https://example.com/auto'),
        content: const Value('This article discusses automobile engineering and EV design.'),
        type: 'url',
        createdAt: DateTime.now(),
      ),
    );
    await database.insertItem(
      MnemataItemsCompanion.insert(
        title: const Value('Keyword gardening reference'),
        url: const Value('https://example.com/garden'),
        content: const Value('Garden plants and soil composition.'),
        type: 'url',
        createdAt: DateTime.now(),
      ),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('semantic search returns concept-near matches when index is available', () async {
    await keyStore.saveKey('abc');

    final items = await database.watchAllItems().first;
    final indexer = SemanticIndexerService(
      database: database,
      apiKeyStore: keyStore,
      embeddingGenerator: (_) async => <double>[0.1, 0.2],
    );
    await indexer.enqueueIndexing(items.firstWhere((item) => item.title!.contains('Automobile')));
    await indexer.flushPending();

    final service = SemanticSearchService(database: database, apiKeyStore: keyStore);
    final result = await service.search('car design');

    expect(result.fallbackReason, SemanticFallbackReason.none);
    expect(result.items.first.title, contains('Automobile'));
  });

  test('missing key falls back to keyword search results', () async {
    final service = SemanticSearchService(database: database, apiKeyStore: keyStore);
    final result = await service.search('garden');

    expect(result.usedFallback, isTrue);
    expect(result.fallbackReason, SemanticFallbackReason.missingApiKey);
    expect(result.items, isNotEmpty);
  });

  test('weak semantic recall falls back to keyword path', () async {
    await keyStore.saveKey('abc');
    final items = await database.watchAllItems().first;
    final indexer = SemanticIndexerService(
      database: database,
      apiKeyStore: keyStore,
      embeddingGenerator: (_) async => <double>[0.2, 0.4],
    );
    await indexer.enqueueIndexing(items.first);
    await indexer.flushPending();

    final service = SemanticSearchService(database: database, apiKeyStore: keyStore);
    final result = await service.search('completely unrelated query term');

    expect(result.usedFallback, isTrue);
    expect(result.fallbackReason, SemanticFallbackReason.weakRecall);
  });
}
