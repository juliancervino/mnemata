import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/features/intelligence/domain/intelligence_errors.dart';
import 'package:mnemata/features/intelligence/services/ai_provider_client.dart';
import 'package:mnemata/features/intelligence/services/api_key_store.dart';
import 'package:mnemata/features/intelligence/services/summary_service.dart';
import 'package:mnemata/features/settings/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/open.dart';

class _InMemorySecureStore implements SecureKeyValueStore {
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
  late ApiKeyStore apiKeyStore;
  late SettingsService settingsService;
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
    itemId = await database.insertItem(
      MnemataItemsCompanion.insert(
        title: const Value('Test article'),
        url: const Value('https://example.com'),
        content: const Value('Alpha beta gamma delta epsilon'),
        type: 'url',
        createdAt: DateTime.now(),
      ),
    );
    apiKeyStore = ApiKeyStore(secureStore: _InMemorySecureStore());
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    settingsService = SettingsService(prefs);
    await settingsService.setAiProvider('gemini');
  });

  tearDown(() async {
    await database.close();
  });

  test('missing API key returns missingApiKey with setup guidance', () async {
    final provider = AIProviderClient(
      executor: (_) async => <String, dynamic>{},
    );
    final service = SummaryService(
      database: database,
      apiKeyStore: apiKeyStore,
      providerClient: provider,
      settingsService: settingsService,
    );

    final item = (await database.watchAllItems().first).firstWhere(
      (i) => i.id == itemId,
    );
    final result = await service.generateSummary(item);

    expect(result.isSuccess, isFalse);
    expect(result.errorCode, IntelligenceErrorCode.missingApiKey);
    expect(result.guidance, contains('Settings'));
  });

  test('unsupported item states return explicit unsupported result', () async {
    final fileItemId = await database.insertItem(
      MnemataItemsCompanion.insert(
        filePath: const Value('/tmp/sample.pdf'),
        type: 'file',
        createdAt: DateTime.now(),
      ),
    );
    await apiKeyStore.saveKey('test-key');

    final provider = AIProviderClient(
      executor: (_) async => <String, dynamic>{},
    );
    final service = SummaryService(
      database: database,
      apiKeyStore: apiKeyStore,
      providerClient: provider,
      settingsService: settingsService,
    );

    final fileItem = (await database.watchAllItems().first).firstWhere(
      (i) => i.id == fileItemId,
    );
    final result = await service.generateSummary(fileItem);

    expect(result.status, SummaryStatus.unsupported);
    expect(result.guidance.toLowerCase(), contains('url'));
  });

  test(
    'unchanged content hash reuses cache, changed hash regenerates',
    () async {
      await apiKeyStore.saveKey('test-key');
      var providerCalls = 0;
      final provider = AIProviderClient(
        executor: (_) async {
          providerCalls += 1;
          return <String, dynamic>{
            'tldr': 'Quick summary',
            'keyPoints': <String>['One', 'Two', 'Three'],
            'whyItMatters': 'Because context matters.',
          };
        },
      );

      final service = SummaryService(
        database: database,
        apiKeyStore: apiKeyStore,
        providerClient: provider,
        settingsService: settingsService,
      );

      var item = (await database.watchAllItems().first).firstWhere(
        (i) => i.id == itemId,
      );
      final first = await service.generateSummary(item);
      final second = await service.generateSummary(item);

      expect(first.isSuccess, isTrue);
      expect(second.fromCache, isTrue);
      expect(providerCalls, 1);

      await database.updateItemContent(
        itemId,
        'changed article content',
        item.title,
        null,
      );
      item = (await database.watchAllItems().first).firstWhere(
        (i) => i.id == itemId,
      );

      final third = await service.generateSummary(item);
      expect(third.isSuccess, isTrue);
      expect(providerCalls, 2);

      final forced = await service.generateSummary(item, forceRefresh: true);
      expect(forced.isSuccess, isTrue);
      expect(forced.fromCache, isFalse);
      expect(providerCalls, 3);
    },
  );

  test(
    'loadSavedSummary returns persisted summary without provider call',
    () async {
      await apiKeyStore.saveKey('test-key');
      var providerCalls = 0;
      final provider = AIProviderClient(
        executor: (_) async {
          providerCalls += 1;
          return <String, dynamic>{
            'tldr': 'Cached summary',
            'keyPoints': <String>['One', 'Two', 'Three'],
            'whyItMatters': 'Because this remains useful.',
          };
        },
      );

      final service = SummaryService(
        database: database,
        apiKeyStore: apiKeyStore,
        providerClient: provider,
        settingsService: settingsService,
      );

      final item = (await database.watchAllItems().first).firstWhere(
        (i) => i.id == itemId,
      );

      final generated = await service.generateSummary(item);
      expect(generated.isSuccess, isTrue);
      expect(providerCalls, 1);

      final saved = await service.loadSavedSummary(item);
      expect(saved, isA<SummaryResult>());
      expect(saved!.isSuccess, isTrue);
      expect(saved.fromCache, isTrue);
      expect(saved.tldr, 'Cached summary');
      expect(providerCalls, 1);
    },
  );

  test(
    'result always includes TLDR, key points (3-5), and why-it-matters',
    () async {
      await apiKeyStore.saveKey('test-key');
      late String prompt;
      final provider = AIProviderClient(
        executor: (request) async {
          prompt = request.prompt;
          return <String, dynamic>{
            'tldr': 'Resumen rapido',
            'keyPoints': <String>['Uno', 'Dos', 'Tres', 'Cuatro'],
            'whyItMatters': 'Porque aporta contexto.',
          };
        },
      );

      final service = SummaryService(
        database: database,
        apiKeyStore: apiKeyStore,
        providerClient: provider,
        settingsService: settingsService,
      );

      final item = (await database.watchAllItems().first).firstWhere(
        (i) => i.id == itemId,
      );
      final result = await service.generateSummary(item);

      expect(result.isSuccess, isTrue);
      expect(result.tldr, isNotEmpty);
      expect(result.keyPoints.length, inInclusiveRange(3, 5));
      expect(result.whyItMatters, isNotEmpty);
      expect(prompt.toLowerCase(), contains('castellano'));
    },
  );

  test('summary prompt strips html/css/script payloads to plain text', () async {
    await apiKeyStore.saveKey('test-key');
    await database.updateItemContent(
      itemId,
      '<style>.x{color:red}</style><script>alert(1)</script><article><h1>Titulo</h1><p>Texto util</p></article>',
      'Test article',
      null,
    );

    late String prompt;
    final provider = AIProviderClient(
      executor: (request) async {
        prompt = request.prompt;
        return <String, dynamic>{
          'tldr': 'Resumen rapido',
          'keyPoints': <String>['Uno', 'Dos', 'Tres'],
          'whyItMatters': 'Porque aporta contexto.',
        };
      },
    );

    final service = SummaryService(
      database: database,
      apiKeyStore: apiKeyStore,
      providerClient: provider,
      settingsService: settingsService,
    );

    final item = (await database.watchAllItems().first).firstWhere(
      (i) => i.id == itemId,
    );
    final result = await service.generateSummary(item, forceRefresh: true);

    expect(result.isSuccess, isTrue);
    expect(prompt, contains('Titulo Texto util'));
    expect(prompt.toLowerCase(), isNot(contains('<script')));
    expect(prompt.toLowerCase(), isNot(contains('<style')));
    expect(prompt, isNot(contains('alert(1)')));
  });
}
