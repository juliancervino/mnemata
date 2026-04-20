import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/features/chronological_list/presentation/item_list_screen.dart';
import 'package:mnemata/features/chronological_list/presentation/search_result_tile.dart';
import 'package:mnemata/features/chronological_list/services/list_state_snapshot.dart';
import 'package:mnemata/features/ingestion/services/extraction_service.dart';
import 'package:mnemata/features/ingestion/services/pdf_extraction_service.dart';
import 'package:mnemata/features/ingestion/services/share_service.dart';
import 'package:mnemata/features/intelligence/services/api_key_store.dart';
import 'package:mnemata/features/intelligence/services/semantic_search_service.dart';
import 'package:mnemata/features/settings/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_database_factory.dart';

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

bool _hasHighlightedToken(InlineSpan span, String tokenLower) {
  if (span is TextSpan) {
    final text = (span.text ?? '').toLowerCase();
    final style = span.style;
    if (text.contains(tokenLower) && style?.fontWeight == FontWeight.w700) {
      return true;
    }

    final children = span.children ?? const <InlineSpan>[];
    for (final child in children) {
      if (_hasHighlightedToken(child, tokenLower)) {
        return true;
      }
    }
  }
  return false;
}

void main() {
  final getIt = GetIt.instance;
  late AppDatabase database;

  Future<void> _clearPendingTimers(WidgetTester tester) async {
    await tester.pumpWidget(Container());
    await tester.pump(const Duration(seconds: 1));
  }

  setUp(() async {
    await getIt.reset();
    ListStateSnapshotStore.clear();
    database = createTestDatabase();
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

    final keyStore = ApiKeyStore(secureStore: _Store());
    getIt.registerSingleton<ApiKeyStore>(keyStore);
    getIt.registerSingleton<SemanticSearchService>(
      SemanticSearchService(
        database: database,
        apiKeyStore: keyStore,
        settingsService: settingsService,
      ),
    );
  });

  tearDown(() async {
    await database.close();
    await getIt.reset();
  });

  testWidgets('search input applies query after ~300ms debounce', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 2, 1, 10);
    await database.insertItem(
      MnemataItemsCompanion.insert(
        title: const Value('Alpha item'),
        url: const Value('https://example.com/alpha'),
        type: 'url',
        createdAt: now,
      ),
    );
    await database.insertItem(
      MnemataItemsCompanion.insert(
        title: const Value('Beta item'),
        url: const Value('https://example.com/beta'),
        type: 'url',
        createdAt: now.subtract(const Duration(minutes: 1)),
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: ItemListScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Alpha');

    await tester.pump(const Duration(milliseconds: 120));
    final dynamic stateBefore = tester.state(find.byType(ItemListScreen));
    expect(stateBefore.debugSearchQueryForTests, isEmpty);
    expect(find.text('Beta item'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 220));
    await tester.pumpAndSettle();
    final dynamic stateAfter = tester.state(find.byType(ItemListScreen));
    expect(stateAfter.debugSearchQueryForTests, 'Alpha');
    expect(find.byType(SearchResultTile), findsOneWidget);
    expect(find.text('Beta item'), findsNothing);

    await _clearPendingTimers(tester);
  });

  testWidgets('search respects active label filters by default', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 2, 1, 11);
    final focusLabelId = await database.getOrCreateLabel('focus');

    final focusedItemId = await database.insertItem(
      MnemataItemsCompanion.insert(
        title: const Value('Topic focused'),
        url: const Value('https://example.com/focused'),
        type: 'url',
        createdAt: now,
      ),
    );
    await database.assignLabelToItem(focusedItemId, focusLabelId);

    await database.insertItem(
      MnemataItemsCompanion.insert(
        title: const Value('Topic broad'),
        url: const Value('https://example.com/broad'),
        type: 'url',
        createdAt: now.subtract(const Duration(minutes: 1)),
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: ItemListScreen()));
    await tester.pumpAndSettle();

    final focusChip = find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          widget.data == 'focus' &&
          widget.style?.fontSize == 12,
    );
    await tester.tap(focusChip.first);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Topic');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('Topic focused'), findsOneWidget);
    expect(find.text('Topic broad'), findsNothing);

    await _clearPendingTimers(tester);
  });

  testWidgets('search results render snippet tile with highlighted terms', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 2, 1, 12);
    await database.insertItem(
      MnemataItemsCompanion.insert(
        title: const Value('Space systems note'),
        content: const Value(
          'This text explains galaxy mapping, stellar navigation, and orbital paths for deep space search demos.',
        ),
        url: const Value('https://example.com/space'),
        type: 'url',
        createdAt: now,
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: ItemListScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'galaxy');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.byType(SearchResultTile), findsOneWidget);

    final richTextFinder = find.byWidgetPredicate((widget) {
      if (widget is! RichText) {
        return false;
      }
      return _hasHighlightedToken(widget.text, 'galaxy');
    });
    expect(richTextFinder, findsWidgets);

    await _clearPendingTimers(tester);
  });

  testWidgets('search empty state offers deterministic recovery actions', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 2, 1, 13);
    await database.insertItem(
      MnemataItemsCompanion.insert(
        title: const Value('Present item'),
        url: const Value('https://example.com/present'),
        type: 'url',
        createdAt: now,
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: ItemListScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'missingtokenzzz');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('No search results'), findsOneWidget);
    expect(find.text('Clear query'), findsOneWidget);
    expect(find.text('View all items'), findsOneWidget);

    await _clearPendingTimers(tester);
  });

  testWidgets('search error state exposes retry and back to list actions', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 2, 1, 14);
    await database.insertItem(
      MnemataItemsCompanion.insert(
        title: const Value('Error probe item'),
        url: const Value('https://example.com/error-probe'),
        type: 'url',
        createdAt: now,
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: ItemListScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '"');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('Search is temporarily unavailable.'), findsOneWidget);
    expect(find.text('Retry Search'), findsOneWidget);
    expect(find.text('Back to list'), findsOneWidget);

    await _clearPendingTimers(tester);
  });
}
