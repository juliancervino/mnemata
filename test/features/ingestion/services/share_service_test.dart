import 'dart:io';
import 'dart:ffi';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/features/ingestion/presentation/ingestion_failure_actions_sheet.dart';
import 'package:mnemata/features/ingestion/presentation/ingestion_summary_screen.dart';
import 'package:mnemata/features/ingestion/services/share_service.dart';
import 'package:mnemata/features/ingestion/services/extraction_service.dart';
import 'package:mnemata/features/ingestion/services/pdf_extraction_service.dart';
import 'package:sqlite3/open.dart';

class MockExtractionService extends Mock implements ExtractionService {}

class MockPdfExtractionService extends Mock implements PdfExtractionService {}

class MockNavigatorKey extends Mock implements GlobalKey<NavigatorState> {}

class MockNavigatorState extends Mock implements NavigatorState {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      'MockNavigatorState';
}

void main() {
  late AppDatabase database;
  late MockExtractionService mockExtractionService;
  late MockPdfExtractionService mockPdfExtractionService;
  late MockNavigatorKey mockNavigatorKey;
  late MockNavigatorState mockNavigatorState;

  setUpAll(() {
    if (Platform.isLinux) {
      try {
        open.overrideFor(
          OperatingSystem.linux,
          () => DynamicLibrary.open('libsqlite3.so.0'),
        );
      } catch (_) {
        // Ignore override failure; tests may still resolve sqlite dynamically.
      }
    }

    registerFallbackValue(
      MaterialPageRoute<dynamic>(builder: (context) => Container()),
    );
  });

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    mockExtractionService = MockExtractionService();
    mockPdfExtractionService = MockPdfExtractionService();
    mockNavigatorKey = MockNavigatorKey();
    mockNavigatorState = MockNavigatorState();

    when(() => mockNavigatorKey.currentState).thenReturn(mockNavigatorState);
    when(
      () => mockNavigatorState.push<dynamic>(any()),
    ).thenAnswer((_) => Future<Object?>.value(null));
    when(
      () => mockNavigatorState.push<Object?>(any()),
    ).thenAnswer((_) => Future<Object?>.value(null));
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> insertUrlItem(String url) async {
    await database.insertItem(
      MnemataItemsCompanion.insert(
        type: 'url',
        createdAt: DateTime.now(),
        url: Value(url),
      ),
    );
  }

  Future<void> insertFileItem(String filePath) async {
    await database.insertItem(
      MnemataItemsCompanion.insert(
        type: 'file',
        createdAt: DateTime.now(),
        filePath: Value(filePath),
      ),
    );
  }

  test('handleUrl triggers extraction and navigates to summary', () async {
    const url = 'https://example.com/article';
    final shareService = ShareService(
      database,
      mockExtractionService,
      mockPdfExtractionService,
      mockNavigatorKey,
    );

    when(() => mockExtractionService.extractContent(url)).thenAnswer(
      (_) async =>
          (title: 'Test Title', content: 'Test Content', thumbnailUrl: null),
    );

    await shareService.handleUrl(url);

    // Verify extraction was called
    verify(() => mockExtractionService.extractContent(url)).called(1);

    // Verify navigation was called
    verify(() => mockNavigatorState.push<dynamic>(any())).called(1);
  });

  test('duplicate decision can keep current item without extracting', () async {
    const storedUrl = 'https://example.com/page';
    const incomingUrl = 'HTTPS://EXAMPLE.COM/page';
    await insertUrlItem(storedUrl);

    final shareService = ShareService(
      database,
      mockExtractionService,
      mockPdfExtractionService,
      mockNavigatorKey,
      duplicateResolutionOverride:
          ({
            required String identifier,
            required MnemataItem existingItem,
          }) async => DuplicateResolution.keepCurrentItem,
    );

    await shareService.handleUrl(incomingUrl);

    verifyNever(() => mockExtractionService.extractContent(any()));
    verifyNever(() => mockNavigatorState.push<dynamic>(any()));
  });

  test('duplicate decision can open existing item', () async {
    const storedUrl = 'HTTPS://EXAMPLE.COM/page/';
    const incomingUrl = 'https://example.com/page';
    await insertUrlItem(storedUrl);

    final shareService = ShareService(
      database,
      mockExtractionService,
      mockPdfExtractionService,
      mockNavigatorKey,
      duplicateResolutionOverride:
          ({
            required String identifier,
            required MnemataItem existingItem,
          }) async => DuplicateResolution.openExistingItem,
    );

    await shareService.handleUrl(incomingUrl);

    verifyNever(() => mockExtractionService.extractContent(any()));
    verify(() => mockNavigatorState.push<dynamic>(any())).called(1);
  });

  test('duplicate decision can add duplicate item intentionally', () async {
    const storedUrl = 'https://example.com/page';
    const incomingUrl = 'https://example.com/page';
    await insertUrlItem(storedUrl);

    final shareService = ShareService(
      database,
      mockExtractionService,
      mockPdfExtractionService,
      mockNavigatorKey,
      duplicateResolutionOverride:
          ({
            required String identifier,
            required MnemataItem existingItem,
          }) async => DuplicateResolution.addDuplicateItem,
    );

    when(() => mockExtractionService.extractContent(incomingUrl)).thenAnswer(
      (_) async => (title: 'Dup', content: 'Content', thumbnailUrl: null),
    );

    await shareService.handleUrl(incomingUrl);

    verify(() => mockExtractionService.extractContent(incomingUrl)).called(1);
    verify(() => mockNavigatorState.push<dynamic>(any())).called(1);
  });

  test(
    'extraction failure uses guided actions instead of silent drop',
    () async {
      const url = 'https://example.com/fail';
      var prompted = false;

      final shareService = ShareService(
        database,
        mockExtractionService,
        mockPdfExtractionService,
        mockNavigatorKey,
        failureActionOverride:
            ({
              required String sourceLabel,
              required bool canOpenOriginal,
            }) async {
              prompted = true;
              return IngestionFailureAction.dismiss;
            },
      );

      when(
        () => mockExtractionService.extractContent(url),
      ).thenAnswer((_) async => null);

      await shareService.handleUrl(url);

      expect(prompted, isTrue);
      verify(() => mockExtractionService.extractContent(url)).called(1);
      verifyNever(() => mockNavigatorState.push<dynamic>(any()));
    },
  );

  test(
    'retry extraction action retries and then proceeds to summary',
    () async {
      const url = 'https://example.com/retry';
      var failurePromptCount = 0;

      final shareService = ShareService(
        database,
        mockExtractionService,
        mockPdfExtractionService,
        mockNavigatorKey,
        failureActionOverride:
            ({
              required String sourceLabel,
              required bool canOpenOriginal,
            }) async {
              failurePromptCount += 1;
              return IngestionFailureAction.retryExtraction;
            },
      );

      var extractionCallCount = 0;
      when(() => mockExtractionService.extractContent(url)).thenAnswer((
        _,
      ) async {
        extractionCallCount += 1;
        if (extractionCallCount == 1) {
          return null;
        }
        return (
          title: 'Recovered',
          content: 'Recovered content',
          thumbnailUrl: null,
        );
      });

      await shareService.handleUrl(url);

      expect(failurePromptCount, 1);
      verify(() => mockExtractionService.extractContent(url)).called(2);
      verify(() => mockNavigatorState.push<dynamic>(any())).called(1);
    },
  );

  test('sequential shares process each payload independently', () async {
    const urlA = 'https://example.com/a';
    const urlB = 'https://example.com/b';

    final shareService = ShareService(
      database,
      mockExtractionService,
      mockPdfExtractionService,
      mockNavigatorKey,
    );

    when(() => mockExtractionService.extractContent(urlA)).thenAnswer(
      (_) async => (title: 'A', content: 'Content A', thumbnailUrl: null),
    );
    when(() => mockExtractionService.extractContent(urlB)).thenAnswer(
      (_) async => (title: 'B', content: 'Content B', thumbnailUrl: null),
    );

    await shareService.handleUrl(urlA);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await shareService.handleUrl(urlB);

    verify(() => mockExtractionService.extractContent(urlA)).called(1);
    verify(() => mockExtractionService.extractContent(urlB)).called(1);
    verify(() => mockNavigatorState.push<dynamic>(any())).called(2);
  });

  test('file duplicate keep current avoids file summary navigation', () async {
    const filePath = '/tmp/sample.pdf';
    await insertFileItem(filePath);

    final shareService = ShareService(
      database,
      mockExtractionService,
      mockPdfExtractionService,
      mockNavigatorKey,
      duplicateResolutionOverride:
          ({
            required String identifier,
            required MnemataItem existingItem,
          }) async => DuplicateResolution.keepCurrentItem,
    );

    await shareService.handleWebFile(
      fileName: filePath,
      bytes: Uint8List.fromList(<int>[1, 2, 3]),
    );

    verifyNever(() => mockNavigatorState.push<dynamic>(any()));
  });

  test('keeping duplicate does not affect next shared url', () async {
    const duplicateUrl = 'https://example.com/dup';
    const nextUrl = 'https://example.com/next';
    await insertUrlItem(duplicateUrl);

    final shareService = ShareService(
      database,
      mockExtractionService,
      mockPdfExtractionService,
      mockNavigatorKey,
      duplicateResolutionOverride:
          ({
            required String identifier,
            required MnemataItem existingItem,
          }) async => DuplicateResolution.keepCurrentItem,
    );

    when(() => mockExtractionService.extractContent(nextUrl)).thenAnswer(
      (_) async => (title: 'Next', content: 'Next content', thumbnailUrl: null),
    );

    await shareService.handleUrl(duplicateUrl);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await shareService.handleUrl(nextUrl);

    verifyNever(() => mockExtractionService.extractContent(duplicateUrl));
    verify(() => mockExtractionService.extractContent(nextUrl)).called(1);
    verify(() => mockNavigatorState.push<dynamic>(any())).called(1);
  });

  test('discarded summary keeps next ingestion deterministic', () async {
    const firstUrl = 'https://example.com/first';
    const secondUrl = 'https://example.com/second';

    final shareService = ShareService(
      database,
      mockExtractionService,
      mockPdfExtractionService,
      mockNavigatorKey,
    );

    var pushCount = 0;
    when(() => mockNavigatorState.push<dynamic>(any())).thenAnswer((_) async {
      pushCount += 1;
      if (pushCount == 1) {
        return IngestionSummaryResult.discarded;
      }
      return IngestionSummaryResult.saved;
    });

    when(() => mockExtractionService.extractContent(firstUrl)).thenAnswer(
      (_) async =>
          (title: 'First', content: 'First content', thumbnailUrl: null),
    );
    when(() => mockExtractionService.extractContent(secondUrl)).thenAnswer(
      (_) async =>
          (title: 'Second', content: 'Second content', thumbnailUrl: null),
    );

    await shareService.handleUrl(firstUrl);
    await shareService.handleUrl(secondUrl);

    verify(() => mockExtractionService.extractContent(firstUrl)).called(1);
    verify(() => mockExtractionService.extractContent(secondUrl)).called(1);
    expect(pushCount, 2);
  });
}
