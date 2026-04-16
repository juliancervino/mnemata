import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/features/bookmarks/services/bookmark_import_service.dart';
import 'package:sqlite3/open.dart';

void main() {
  late AppDatabase database;
  late BookmarkImportService service;

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
    service = BookmarkImportService(database: database);
  });

  tearDown(() async {
    await database.close();
  });

  test('import parser reads nested folders and keeps only http/https URLs', () {
    const html = '''
<!DOCTYPE NETSCAPE-Bookmark-file-1>
<TITLE>Bookmarks</TITLE>
<H1>Bookmarks</H1>
<DL><p>
  <DT><H3>Folder A</H3>
  <DL><p>
    <DT><A HREF="https://example.com/a">Alpha</A>
    <DT><A HREF="ftp://example.com/file.zip">FTP</A>
    <DT><A HREF="http://example.org/b">Beta</A>
  </DL><p>
</DL><p>
''';

    final urls = service.extractUrlsFromHtml(html);

    expect(urls, <String>['https://example.com/a', 'http://example.org/b']);
  });

  test('import parser skips malformed and non-url nodes safely', () {
    const html = '''
<!DOCTYPE NETSCAPE-Bookmark-file-1>
<DL><p>
  <DT><A>Missing href</A>
  <DT><A HREF="">Empty href</A>
  <DT><A HREF="javascript:alert(1)">Script</A>
  <DT><A HREF="data:text/plain;base64,SGVsbG8=">Data</A>
  <DT><A HREF="https://valid.example/path">Valid</A>
</DL><p>
''';

    final urls = service.extractUrlsFromHtml(html);

    expect(urls, <String>['https://valid.example/path']);
  });

  test('import inserts new URL items and skips existing canonical duplicates', () async {
    await service.importBookmarksHtml('''
<!DOCTYPE NETSCAPE-Bookmark-file-1>
<DL><p>
  <DT><A HREF="https://example.com/dupe">First</A>
  <DT><A HREF="https://example.com/dupe/">Second</A>
  <DT><A HREF="https://example.com/new">Third</A>
</DL><p>
''');

    final result = await service.importBookmarksHtml('''
<!DOCTYPE NETSCAPE-Bookmark-file-1>
<DL><p>
  <DT><A HREF="https://example.com/dupe">Duplicate</A>
  <DT><A HREF="https://example.com/new">Duplicate New</A>
  <DT><A HREF="https://example.com/fresh">Fresh</A>
</DL><p>
''');

    expect(result.importedCount, 1);
    expect(result.duplicateCount, 2);
    expect(result.invalidCount, 0);

    final allItems = await database.watchAllItems().first;
    final urls = allItems
        .map((item) => item.url)
        .whereType<String>()
        .toSet();

    expect(urls, contains('https://example.com/dupe'));
    expect(urls, contains('https://example.com/new'));
    expect(urls, contains('https://example.com/fresh'));
    expect(urls.length, 3);
  });
}
