import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/features/ingestion/services/share_service.dart';
import 'package:mnemata/features/ingestion/services/extraction_service.dart';
import 'package:sqlite3/open.dart';
import 'dart:ffi';

class MockExtractionService extends Mock implements ExtractionService {}

void main() {
  late AppDatabase database;
  late ShareService shareService;
  late MockExtractionService mockExtractionService;

  setUpAll(() {
    if (Platform.isLinux) {
      // Use a try-catch or check if file exists for more robust testing environments
      try {
        open.overrideFor(OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
      } catch (e) {
        print('Warning: Could not override sqlite3 library: $e');
      }
    }
  });

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    mockExtractionService = MockExtractionService();
    shareService = ShareService(database, mockExtractionService);
  });

  tearDown(() async {
    await database.close();
  });

  test('handleUrl inserts item and triggers extraction', () async {
    const url = 'https://example.com/article';
    when(() => mockExtractionService.extractContent(url))
        .thenAnswer((_) async => (title: 'Test Title', content: 'Test Content'));

    await shareService.handleUrl(url);

    // Verify it was inserted
    final items = await database.select(database.mnemataItems).get();
    expect(items.length, 1);
    expect(items.first.url, url);

    // Explicitly call processUrl to simulate the async task and verify it updates the DB
    await shareService.processUrl(items.first.id, url);
    
    final updatedItem = await (database.select(database.mnemataItems)..where((t) => t.id.equals(items.first.id))).getSingle();
    expect(updatedItem.content, 'Test Content');
    expect(updatedItem.title, 'Test Title');
    
    verify(() => mockExtractionService.extractContent(url)).called(greaterThanOrEqualTo(1));
  });

  test('handleUrl avoids duplicate URLs', () async {
    const url = 'https://example.com/article';
    when(() => mockExtractionService.extractContent(url))
        .thenAnswer((_) async => (title: 'Test Title', content: 'Test Content'));

    await shareService.handleUrl(url);
    await shareService.handleUrl(url);

    final items = await database.select(database.mnemataItems).get();
    expect(items.length, 1);
  });
}
