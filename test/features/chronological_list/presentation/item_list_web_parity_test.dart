import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/core/widgets/tag_chip.dart';
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

  Future<void> _clearPendingTimers(WidgetTester tester) async {
    await tester.pumpWidget(Container());
    await tester.pump(const Duration(seconds: 1));
  }

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
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets('newest-first order is preserved for initial list rendering', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 1, 10, 8);
    await database.insertItem(
      MnemataItemsCompanion.insert(
        title: const Value('Older Item'),
        url: const Value('https://example.com/older'),
        type: 'url',
        createdAt: now.subtract(const Duration(minutes: 1)),
      ),
    );
    await database.insertItem(
      MnemataItemsCompanion.insert(
        title: const Value('Newest Item'),
        url: const Value('https://example.com/newest'),
        type: 'url',
        createdAt: now,
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: ItemListScreen()));
    await tester.pumpAndSettle();

    final newestY = tester.getTopLeft(find.text('Newest Item')).dy;
    final olderY = tester.getTopLeft(find.text('Older Item')).dy;
    expect(newestY, lessThan(olderY));

    await _clearPendingTimers(tester);
  });

  testWidgets('more filters affordance is visible and opens filter selector flow', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 1, 10, 8);
    await database.insertItem(
      MnemataItemsCompanion.insert(
        title: const Value('Item One'),
        url: const Value('https://example.com/one'),
        type: 'url',
        createdAt: now,
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: ItemListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('more filters'), findsOneWidget);
    await tester.tap(find.text('more filters'));
    await tester.pumpAndSettle();

    expect(find.text('TAGS'), findsWidgets);

    await _clearPendingTimers(tester);
  });

  testWidgets('list state snapshot restores query filter and scroll after rebuild', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 1, 10, 8);
    final focusLabelId = await database.getOrCreateLabel('focus');

    for (var i = 0; i < 80; i++) {
      final isFocus = i < 60;
      final id = await database.insertItem(
        MnemataItemsCompanion.insert(
          title: Value(
            isFocus ? 'Focus item $i' : 'Other item $i',
          ),
          url: Value('https://example.com/$i'),
          type: 'url',
          createdAt: now.subtract(Duration(minutes: i)),
        ),
      );
      if (isFocus) {
        await database.assignLabelToItem(id, focusLabelId);
      }
    }

    await tester.pumpWidget(const MaterialApp(home: ItemListScreen()));
    await tester.pumpAndSettle();

    final focusFilterChip = find.byWidgetPredicate(
      (widget) => widget is TagChip && widget.label == 'focus',
    );
    expect(focusFilterChip, findsOneWidget);
    await tester.tap(focusFilterChip);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'item');
    await tester.pumpAndSettle();

    final scrollableFinder = find.byType(Scrollable).first;
    await tester.fling(scrollableFinder, const Offset(0, -1200), 1800);
    await tester.pumpAndSettle();

    var beforeOffset = tester
      .state<ScrollableState>(scrollableFinder)
      .position
      .pixels;
    if (beforeOffset == 0) {
      await tester.drag(scrollableFinder, const Offset(0, -600));
      await tester.pumpAndSettle();
      beforeOffset = tester
        .state<ScrollableState>(scrollableFinder)
        .position
        .pixels;
    }

    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();

    await tester.pumpWidget(const MaterialApp(home: ItemListScreen()));
    await tester.pumpAndSettle();

    final restoredOffset = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .pixels;
    final restoredSearchField = tester.widget<TextField>(find.byType(TextField));

    expect(find.textContaining('Other item'), findsNothing);
    expect(restoredSearchField.controller?.text, 'item');
    expect((restoredOffset - beforeOffset).abs(), lessThan(24));

    await _clearPendingTimers(tester);
  });
}
