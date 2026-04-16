import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/features/bookmarks/services/bookmark_export_service.dart';
import 'package:sqlite3/open.dart';

void main() {
  late AppDatabase database;
  late BookmarkExportService service;

  setUpAll(() {
    if (Platform.isLinux) {
      open.overrideFor(
        OperatingSystem.linux,
        () => DynamicLibrary.open('libsqlite3.so.0'),
      );
    }
  });

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    service = BookmarkExportService(database: database);
  });

  tearDown(() async {
    await database.close();
  });

  test('export emits Netscape header and URL bookmarks only', () async {
    await database.insertItem(
      MnemataItemsCompanion.insert(
        title: const drift.Value('Alpha URL'),
        url: const drift.Value('https://example.com/a'),
        type: 'url',
        createdAt: DateTime.utc(2026, 4, 16, 9),
      ),
    );

    await database.insertItem(
      MnemataItemsCompanion.insert(
        title: const drift.Value('Attached PDF'),
        filePath: const drift.Value('/tmp/example.pdf'),
        type: 'file',
        createdAt: DateTime.utc(2026, 4, 16, 10),
      ),
    );

    final html = await service.exportBookmarksHtml();

    expect(html, contains('<!DOCTYPE NETSCAPE-Bookmark-file-1>'));
    expect(html, contains('<H1>Bookmarks</H1>'));
    expect(html, contains('HREF="https://example.com/a"'));
    expect(html, contains('>Alpha URL</A>'));
    expect(html, isNot(contains('Attached PDF')));
    expect(html, isNot(contains('/tmp/example.pdf')));
  });
}
