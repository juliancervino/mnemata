import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/features/chronological_list/presentation/item_list_screen.dart';
import 'package:mnemata/features/ingestion/services/extraction_service.dart';
import 'package:mnemata/features/ingestion/services/pdf_extraction_service.dart';
import 'package:mnemata/features/ingestion/services/share_service.dart';
import 'package:mnemata/features/intelligence/services/api_key_store.dart';
import 'package:mnemata/features/intelligence/services/semantic_search_service.dart';
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
  final getIt = GetIt.instance;
  late AppDatabase database;

  setUpAll(() {
    if (Platform.isLinux) {
      open.overrideFor(
        OperatingSystem.linux,
        () => DynamicLibrary.open('libsqlite3.so.0'),
      );
    }
  });

  setUp(() async {
    await getIt.reset();
    database = AppDatabase.forTesting(NativeDatabase.memory());
    getIt.registerSingleton<AppDatabase>(database);

    final extractionService = ExtractionService();
    final pdfExtractionService = PdfExtractionService();
    final navigatorKey = GlobalKey<NavigatorState>();

    getIt.registerSingleton<ExtractionService>(extractionService);
    getIt.registerSingleton<PdfExtractionService>(pdfExtractionService);
    getIt.registerSingleton<GlobalKey<NavigatorState>>(navigatorKey);
    getIt.registerSingleton<ShareService>(
      ShareService(
        database,
        extractionService,
        pdfExtractionService,
        navigatorKey,
      ),
    );

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final settingsService = SettingsService(prefs);
    await settingsService.setSemanticSearchEnabled(true);
    getIt.registerSingleton<SettingsService>(settingsService);
    getIt.registerSingleton<ApiKeyStore>(ApiKeyStore(secureStore: _Store()));
    getIt.registerSingleton<SemanticSearchService>(
      SemanticSearchService(
        database: database,
        apiKeyStore: getIt<ApiKeyStore>(),
        settingsService: settingsService,
      ),
    );

    final now = DateTime.utc(2026, 1, 10, 8);
    for (var i = 0; i < 40; i++) {
      await database.insertItem(
        MnemataItemsCompanion.insert(
          title: Value('Scrollable Item $i'),
          url: Value('https://example.com/$i'),
          type: 'url',
          createdAt: now.subtract(Duration(minutes: i)),
        ),
      );
    }
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets('multi-select preserves list scroll offset while selecting', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ItemListScreen()));
    await tester.pumpAndSettle();

    final listFinder = find.byType(ReorderableListView);
    expect(listFinder, findsOneWidget);
    final scrollableFinder = find.byType(Scrollable).first;

    await tester.drag(listFinder, const Offset(0, -900));
    await tester.pumpAndSettle();

    final beforeOffset =
        tester.state<ScrollableState>(find.byType(Scrollable).first).position.pixels;

    final visibleTitles = find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          widget.data != null &&
          widget.data!.startsWith('Scrollable Item '),
    );
    expect(visibleTitles, findsWidgets);

    await tester.longPress(visibleTitles.first);
    await tester.pump();

    final afterLongPressOffset =
        tester.state<ScrollableState>(find.byType(Scrollable).first).position.pixels;
    expect((afterLongPressOffset - beforeOffset).abs(), lessThan(2));

    await tester.tap(visibleTitles.at(1));
    await tester.pump();

    final afterToggleOffset =
        tester.state<ScrollableState>(find.byType(Scrollable).first).position.pixels;
    expect((afterToggleOffset - beforeOffset).abs(), lessThan(2));

    await tester.pumpWidget(Container());
    await tester.pump(const Duration(seconds: 1));
  });
}
