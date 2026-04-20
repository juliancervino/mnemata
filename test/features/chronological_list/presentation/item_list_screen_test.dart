import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/features/chronological_list/presentation/item_list_screen.dart';
import 'package:mnemata/features/chronological_list/presentation/recycle_bin_screen.dart';
import 'package:mnemata/features/ingestion/services/share_service.dart';
import 'package:mnemata/features/ingestion/services/extraction_service.dart';
import 'package:mnemata/features/ingestion/services/pdf_extraction_service.dart';
import 'package:mnemata/features/intelligence/services/api_key_store.dart';
import 'package:mnemata/features/intelligence/services/semantic_search_service.dart';
import 'package:mnemata/features/settings/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'dart:ffi';
import 'dart:io';
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
  final getIt = GetIt.instance;

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

    // Register other dependencies for completeness
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
    // Register missing services
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

  testWidgets('ItemListScreen displays empty state when no items', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ItemListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('No items found.'), findsOneWidget);

    // Clear any pending timers
    await tester.pumpWidget(Container());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('ItemListScreen displays list of items and handles search', (
    WidgetTester tester,
  ) async {
    // Insert some test data
    final now = DateTime.now();
    await database.insertItem(
      MnemataItemsCompanion.insert(
        title: const Value('Apple'),
        url: const Value('https://apple.com'),
        type: 'url',
        createdAt: now,
      ),
    );
    await database.insertItem(
      MnemataItemsCompanion.insert(
        title: const Value('Banana'),
        url: const Value('https://banana.com'),
        type: 'url',
        createdAt: now.subtract(const Duration(minutes: 1)),
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: ItemListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Apple'), findsOneWidget);
    expect(find.text('Banana'), findsOneWidget);

    // Toggle search
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    // Type "Apple"
    await tester.enterText(find.byType(TextField), 'Apple');
    // We need to wait for the stream to update.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Use a more specific finder to avoid matching the TextField content
    expect(
      find.descendant(
        of: find.byType(ReorderableListView),
        matching: find.text('Apple'),
      ),
      findsOneWidget,
    );
    expect(find.text('Banana'), findsNothing);

    // Clear search
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('Apple'), findsOneWidget);
    expect(find.text('Banana'), findsOneWidget);

    // Clear any pending timers
    await tester.pumpWidget(Container());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets(
    'ItemListScreen shows author when available and keeps subtitle fallback when absent',
    (WidgetTester tester) async {
      final now = DateTime.now();
      await database.insertItem(
        MnemataItemsCompanion.insert(
          title: const Value('Authored Item'),
          author: const Value('Jane Doe'),
          url: const Value('https://author.example.com/story'),
          type: 'url',
          createdAt: now,
        ),
      );
      await database.insertItem(
        MnemataItemsCompanion.insert(
          title: const Value('Fallback Item'),
          url: const Value('https://fallback.example.com/story'),
          type: 'url',
          createdAt: now.subtract(const Duration(minutes: 1)),
        ),
      );

      await tester.pumpWidget(const MaterialApp(home: ItemListScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.text('fallback.example.com'), findsOneWidget);

      await tester.pumpWidget(Container());
      await tester.pump(const Duration(seconds: 1));
    },
  );

  testWidgets('RecycleBinScreen lists recycled items and restores them', (
    WidgetTester tester,
  ) async {
    final now = DateTime.now();
    final itemId = await database.insertItem(
      MnemataItemsCompanion.insert(
        title: const Value('Recycle candidate'),
        type: 'url',
        createdAt: now,
      ),
    );
    await database.deleteItem(itemId);

    await tester.pumpWidget(const MaterialApp(home: RecycleBinScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Recycle candidate'), findsOneWidget);
    expect(find.byIcon(Icons.restore_from_trash), findsOneWidget);

    await tester.tap(find.byIcon(Icons.restore_from_trash));
    await tester.pumpAndSettle();

    expect(find.text('Recycle bin is empty.'), findsOneWidget);

    final activeItems = await database.watchAllItems().first;
    expect(activeItems.map((item) => item.id), contains(itemId));

    await tester.pumpWidget(Container());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets(
    'item quick actions expose read/favorite toggles and open reader',
    (WidgetTester tester) async {
      final now = DateTime.now();
      final itemId = await database.insertItem(
        MnemataItemsCompanion.insert(
          title: const Value('Quick Action Item'),
          url: const Value('https://quick.example.com'),
          type: 'url',
          createdAt: now,
        ),
      );

      await tester.pumpWidget(const MaterialApp(home: ItemListScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Item actions').first);
      await tester.pumpAndSettle();

      expect(find.text('Open Reader'), findsOneWidget);
      expect(find.text('Mark as Read'), findsOneWidget);
      expect(find.text('Favorite'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);

      await tester.tap(find.text('Mark as Read'));
      await tester.pumpAndSettle();

      final labelsAfterRead = await database.watchLabelsForItem(itemId).first;
      expect(
        labelsAfterRead.any((label) => label.name.toLowerCase() == 'read'),
        isTrue,
      );

      await tester.tap(find.byTooltip('Item actions').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Favorite'));
      await tester.pumpAndSettle();

      final labelsAfterFavorite = await database
          .watchLabelsForItem(itemId)
          .first;
      expect(
        labelsAfterFavorite.any(
          (label) => label.name.toLowerCase() == 'favorite',
        ),
        isTrue,
      );

      await tester.pumpWidget(Container());
      await tester.pump(const Duration(seconds: 1));
    },
  );

  testWidgets('delete quick action supports undo restore', (
    WidgetTester tester,
  ) async {
    final now = DateTime.now();
    final itemId = await database.insertItem(
      MnemataItemsCompanion.insert(
        title: const Value('Undo Candidate'),
        url: const Value('https://undo.example.com'),
        type: 'url',
        createdAt: now,
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: ItemListScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Item actions').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Move item to recycle bin?'), findsOneWidget);
    await tester.tap(find.text('MOVE'));
    await tester.pumpAndSettle();

    expect(find.text('Item moved to recycle bin'), findsOneWidget);
    expect(
      (await database.watchAllItems().first).map((item) => item.id),
      isNot(contains(itemId)),
    );

    await tester.tap(find.text('UNDO'));
    await tester.pumpAndSettle();

    expect(
      (await database.watchAllItems().first).map((item) => item.id),
      contains(itemId),
    );

    await tester.pumpWidget(Container());
    await tester.pump(const Duration(seconds: 1));
  });
}
