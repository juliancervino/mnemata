import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/core/utils/share_utils.dart';
import 'package:mnemata/features/intelligence/presentation/summary_panel.dart';
import 'package:mnemata/features/intelligence/services/ai_provider_client.dart';
import 'package:mnemata/features/intelligence/services/api_key_store.dart';
import 'package:mnemata/features/intelligence/services/summary_service.dart';
import 'package:mnemata/features/settings/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/open.dart';

class _InMemoryStore implements SecureKeyValueStore {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }

  @override
  Future<String?> read(String key) async {
    return _values[key];
  }

  @override
  Future<void> write({required String key, required String value}) async {
    _values[key] = value;
  }
}

MnemataItem _sampleItem() {
  return MnemataItem(
    id: 1,
    title: 'Example Article',
    url: 'https://example.com/story',
    filePath: null,
    content: '<p>Hello world</p>',
    author: null,
    type: 'url',
    createdAt: DateTime.utc(2026, 4, 1),
    deletedAt: null,
    lastOpenedAt: null,
    thumbnailUrl: null,
    sortOrder: 0,
  );
}

Future<SummaryService> _buildSummaryService() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final prefs = await SharedPreferences.getInstance();
  final settings = SettingsService(prefs);

  return SummaryService(
    database: AppDatabase.forTesting(NativeDatabase.memory()),
    apiKeyStore: ApiKeyStore(secureStore: _InMemoryStore()),
    providerClient: AIProviderClient(
      executor: (_) async => <String, dynamic>{
        'tldr': 'Resumen',
        'keyPoints': <String>['A', 'B', 'C'],
        'whyItMatters': 'Importa por X',
      },
    ),
    settingsService: settings,
  );
}

void main() {
  setUpAll(() {
    if (Platform.isLinux) {
      open.overrideFor(
        OperatingSystem.linux,
        () => DynamicLibrary.open('libsqlite3.so.0'),
      );
    }
  });

  testWidgets('item share dialog shows summary option disabled when unavailable', (
    tester,
  ) async {
    final item = _sampleItem();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  ShareUtils.shareItem(
                    context,
                    item,
                    summaryText: null,
                    shareTextAction: (text, {subject}) async {},
                    shareFileAction: (files, {subject, text}) async {},
                  );
                },
                child: const Text('Open Share'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Share'));
    await tester.pumpAndSettle();

    final summaryOption = find.byWidgetPredicate(
      (widget) =>
          widget is RadioListTile &&
          widget.title is Text &&
          (widget.title as Text).data == 'Share AI summary',
    );
    expect(summaryOption, findsOneWidget);

    final tile = tester.widget<RadioListTile<dynamic>>(summaryOption);
    expect(tile.onChanged, isNull);
  });

  testWidgets('item and summary panel share expose summary action when available', (
    tester,
  ) async {
    final item = _sampleItem();
    final sharedPayloads = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  ShareUtils.shareItem(
                    context,
                    item,
                    summaryText: 'TLDR from cache',
                    shareTextAction: (text, {subject}) async {
                      sharedPayloads.add(text);
                    },
                    shareFileAction: (files, {subject, text}) async {},
                  );
                },
                child: const Text('Open Share'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Share'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Share AI summary'));
    await tester.pump();
    await tester.tap(find.text('SHARE'));
    await tester.pumpAndSettle();

    expect(sharedPayloads, hasLength(1));
    expect(sharedPayloads.first, contains('TLDR from cache'));

    final summaryService = await _buildSummaryService();
    String? panelSharedText;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SummaryPanel(
            item: item,
            summaryService: summaryService,
            loadSavedSummaryAction: (_) async => null,
            generateSummaryAction: (_, {forceRefresh = false}) async =>
                const SummaryResult(
                  status: SummaryStatus.success,
                  tldr: 'Panel TLDR',
                  keyPoints: <String>['One', 'Two', 'Three'],
                  whyItMatters: 'Panel reason',
                ),
            shareSummaryAction: (text) async {
              panelSharedText = text;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final shareButton = find.widgetWithText(OutlinedButton, 'Share summary');
    expect(shareButton, findsOneWidget);

    final shareWidget = tester.widget<OutlinedButton>(shareButton);
    expect(shareWidget.onPressed, isNotNull);

    await tester.tap(shareButton);
    await tester.pumpAndSettle();

    expect(panelSharedText, contains('Panel TLDR'));
  });
}
