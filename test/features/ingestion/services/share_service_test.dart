import 'dart:async';
import 'dart:io';
import 'dart:ffi';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/features/ingestion/services/share_service.dart';
import 'package:mnemata/features/ingestion/services/extraction_service.dart';
import 'package:mnemata/features/ingestion/services/pdf_extraction_service.dart';
import 'package:sqlite3/open.dart';

class MockExtractionService extends Mock implements ExtractionService {}
class MockPdfExtractionService extends Mock implements PdfExtractionService {}
class MockNavigatorKey extends Mock implements GlobalKey<NavigatorState> {}
class MockNavigatorState extends Mock implements NavigatorState {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) => 'MockNavigatorState';
}

void main() {
  late AppDatabase database;
  late ShareService shareService;
  late MockExtractionService mockExtractionService;
  late MockPdfExtractionService mockPdfExtractionService;
  late MockNavigatorKey mockNavigatorKey;
  late MockNavigatorState mockNavigatorState;

  setUpAll(() {
    if (Platform.isLinux) {
      try {
        open.overrideFor(OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
      } catch (_) {
        // Ignore override failure; tests may still resolve sqlite dynamically.
      }
    }

    registerFallbackValue(MaterialPageRoute<dynamic>(builder: (context) => Container()));
  });

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    mockExtractionService = MockExtractionService();
    mockPdfExtractionService = MockPdfExtractionService();
    mockNavigatorKey = MockNavigatorKey();
    mockNavigatorState = MockNavigatorState();

    when(() => mockNavigatorKey.currentState).thenReturn(mockNavigatorState);
    when(() => mockNavigatorState.push<dynamic>(any())).thenAnswer((_) async => null);

    shareService = ShareService(
      database, 
      mockExtractionService, 
      mockPdfExtractionService, 
      mockNavigatorKey
    );
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

  test('handleUrl triggers extraction and navigates to summary', () async {
    const url = 'https://example.com/article';
    when(() => mockExtractionService.extractContent(url))
        .thenAnswer((_) async => (title: 'Test Title', content: 'Test Content', thumbnailUrl: null));

    await shareService.handleUrl(url);

    // Verify extraction was called
    verify(() => mockExtractionService.extractContent(url)).called(1);
    
    // Verify navigation was called
    verify(() => mockNavigatorState.push<dynamic>(any())).called(1);
  });

  test('duplicate lookup uses normalized URL key', () async {
    const storedUrl = 'https://example.com/page';
    const incomingUrl = 'HTTPS://EXAMPLE.COM/page';
    await insertUrlItem(storedUrl);

    final duplicateShareService = ShareService(
      database,
      mockExtractionService,
      mockPdfExtractionService,
      mockNavigatorKey,
      duplicatePromptOverride: (_) async => false,
    );

    await duplicateShareService.handleUrl(incomingUrl);

    verifyNever(() => mockExtractionService.extractContent(any()));
    verifyNever(() => mockNavigatorState.push<dynamic>(any()));
  });

  test('duplicate lookup finds legacy URL variant with trailing slash', () async {
    const storedUrl = 'HTTPS://EXAMPLE.COM/page/';
    const incomingUrl = 'https://example.com/page';
    await insertUrlItem(storedUrl);

    final duplicateShareService = ShareService(
      database,
      mockExtractionService,
      mockPdfExtractionService,
      mockNavigatorKey,
      duplicatePromptOverride: (_) async => false,
    );

    await duplicateShareService.handleUrl(incomingUrl);

    verifyNever(() => mockExtractionService.extractContent(any()));
    verifyNever(() => mockNavigatorState.push<dynamic>(any()));
  });

  test('stale request does not navigate when newer request arrives', () async {
    const slowUrl = 'https://example.com/slow';
    const fastUrl = 'https://example.com/fast';

    final slowExtraction = Completer<({String title, String content, String? thumbnailUrl})?>();

    when(() => mockExtractionService.extractContent(slowUrl))
        .thenAnswer((_) => slowExtraction.future);
    when(() => mockExtractionService.extractContent(fastUrl))
        .thenAnswer((_) async => (title: 'Fast', content: 'Fast content', thumbnailUrl: null));

    final pendingSlow = shareService.handleUrl(slowUrl);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    await shareService.handleUrl(fastUrl);

    slowExtraction.complete((title: 'Slow', content: 'Slow content', thumbnailUrl: null));
    await pendingSlow;

    verify(() => mockExtractionService.extractContent(slowUrl)).called(1);
    verify(() => mockExtractionService.extractContent(fastUrl)).called(1);
    verify(() => mockNavigatorState.push<dynamic>(any())).called(1);
  });

  test('stale request after duplicate confirmation is aborted', () async {
    const duplicateUrl = 'https://example.com/dup';
    const newerUrl = 'https://example.com/newer';
    await insertUrlItem(duplicateUrl);

    final serviceWithDelayedDialog = ShareService(
      database,
      mockExtractionService,
      mockPdfExtractionService,
      mockNavigatorKey,
      duplicatePromptOverride: (_) async {
        await Future<void>.delayed(const Duration(milliseconds: 60));
        return true;
      },
    );

    when(() => mockExtractionService.extractContent(newerUrl))
        .thenAnswer((_) async => (title: 'New', content: 'New content', thumbnailUrl: null));

    final pendingDuplicate = serviceWithDelayedDialog.handleUrl(duplicateUrl);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await serviceWithDelayedDialog.handleUrl(newerUrl);
    await pendingDuplicate;

    verifyNever(() => mockExtractionService.extractContent(duplicateUrl));
    verify(() => mockExtractionService.extractContent(newerUrl)).called(1);
    verify(() => mockNavigatorState.push<dynamic>(any())).called(1);
  });
}
