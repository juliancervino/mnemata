import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/features/ingestion/services/share_service.dart';
import 'package:mnemata/features/ingestion/services/extraction_service.dart';
import 'package:mnemata/features/ingestion/services/pdf_extraction_service.dart';
import 'package:sqlite3/open.dart';
import 'dart:ffi';

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
      } catch (e) {
        print('Warning: Could not override sqlite3 library: $e');
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
}
