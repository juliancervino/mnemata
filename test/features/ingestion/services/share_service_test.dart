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
    when(() => mockNavigatorState.push<dynamic>(any()))
      .thenAnswer((_) => Future<Object?>.value(null));
    when(() => mockNavigatorState.push<Object?>(any()))
      .thenAnswer((_) => Future<Object?>.value(null));

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

  test('sequential shares process each payload independently', () async {
    const urlA = 'https://example.com/a';
    const urlB = 'https://example.com/b';

    when(() => mockExtractionService.extractContent(urlA))
        .thenAnswer((_) async => (title: 'A', content: 'Content A', thumbnailUrl: null));
    when(() => mockExtractionService.extractContent(urlB))
        .thenAnswer((_) async => (title: 'B', content: 'Content B', thumbnailUrl: null));

    await shareService.handleUrl(urlA);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await shareService.handleUrl(urlB);

    verify(() => mockExtractionService.extractContent(urlA)).called(1);
    verify(() => mockExtractionService.extractContent(urlB)).called(1);
    verify(() => mockNavigatorState.push<dynamic>(any())).called(2);
  });

  test('discarding duplicate does not affect next shared url', () async {
    const duplicateUrl = 'https://example.com/dup';
    const nextUrl = 'https://example.com/next';
    await insertUrlItem(duplicateUrl);

    final duplicateDiscardService = ShareService(
      database,
      mockExtractionService,
      mockPdfExtractionService,
      mockNavigatorKey,
      duplicatePromptOverride: (_) async => false,
    );

    when(() => mockExtractionService.extractContent(nextUrl))
        .thenAnswer((_) async => (title: 'Next', content: 'Next content', thumbnailUrl: null));

    await duplicateDiscardService.handleUrl(duplicateUrl);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await duplicateDiscardService.handleUrl(nextUrl);

    verifyNever(() => mockExtractionService.extractContent(duplicateUrl));
    verify(() => mockExtractionService.extractContent(nextUrl)).called(1);
    verify(() => mockNavigatorState.push<dynamic>(any())).called(1);
  });
}
