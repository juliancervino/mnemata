import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/features/intelligence/domain/intelligence_errors.dart';
import 'package:mnemata/features/intelligence/services/ai_provider_client.dart';
import 'package:mnemata/features/intelligence/services/api_key_store.dart';
import 'package:mnemata/features/intelligence/services/tag_suggestion_service.dart';
import 'package:mnemata/features/settings/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  late SettingsService settingsService;
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
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    settingsService = SettingsService(prefs);
    await settingsService.setAiProvider('gemini');

    await database.insertLabel(
      LabelsCompanion.insert(name: 'science', isFolder: const Value(false)),
    );
    await database.insertLabel(
      LabelsCompanion.insert(name: 'history', isFolder: const Value(false)),
    );

    final itemId = await database.insertItem(
      MnemataItemsCompanion.insert(
        title: const Value('A history of electric cars'),
        url: const Value('https://example.com/cars'),
        content: const Value(
          'Automobile batteries and electric vehicle trends.',
        ),
        type: 'url',
        createdAt: DateTime.now(),
      ),
    );

    item = (await database.watchAllItems().first).firstWhere(
      (i) => i.id == itemId,
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('prompt uses extracted content + title + existing tags list', () async {
    await keyStore.saveKey('key');
    late String prompt;
    final client = AIProviderClient(
      executor: (request) async {
        prompt = request.prompt;
        return <String, dynamic>{
          'tagNames': <String>['science'],
        };
      },
    );

    final service = TagSuggestionService(
      database: database,
      apiKeyStore: keyStore,
      providerClient: client,
      settingsService: settingsService,
    );

    await service.suggestForItem(item);

    expect(prompt, contains('A history of electric cars'));
    expect(prompt, contains('Automobile batteries'));
    expect(prompt, contains('science'));
    expect(prompt, contains('history'));
  });

  test('returned suggestions are filtered to existing tags only', () async {
    await keyStore.saveKey('key');
    final client = AIProviderClient(
      executor: (_) async => <String, dynamic>{
        'tagNames': <String>['science', 'new-tag', 'history', 'new-tag'],
      },
    );

    final service = TagSuggestionService(
      database: database,
      apiKeyStore: keyStore,
      providerClient: client,
      settingsService: settingsService,
    );

    final result = await service.suggestForItem(item);

    expect(result.isSuccess, isTrue);
    final names = result.suggestedLabels.map((label) => label.name).toList();
    expect(names, <String>['science', 'history']);
  });

  test('missing key maps to explicit missingApiKey feedback', () async {
    final client = AIProviderClient(
      executor: (_) async => <String, dynamic>{'tagNames': <String>[]},
    );

    final service = TagSuggestionService(
      database: database,
      apiKeyStore: keyStore,
      providerClient: client,
      settingsService: settingsService,
    );

    final result = await service.suggestForItem(item);

    expect(result.status, TagSuggestionStatus.error);
    expect(result.errorCode, IntelligenceErrorCode.missingApiKey);
  });
}
