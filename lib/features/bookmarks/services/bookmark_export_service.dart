import 'dart:convert';
import 'dart:io';

import 'package:mnemata/core/database/app_database.dart';

class BookmarkExportService {
  BookmarkExportService({
    required AppDatabase database,
    DateTime Function()? nowProvider,
  }) : _database = database,
       _nowProvider = nowProvider ?? DateTime.now;

  final AppDatabase _database;
  final DateTime Function() _nowProvider;

  Future<String> exportBookmarksHtml() async {
    final items = await _database.getActiveUrlItems();
    final entries = <_BookmarkEntry>[];

    for (final item in items) {
      final rawUrl = item.url?.trim();
      if (rawUrl == null || rawUrl.isEmpty) {
        continue;
      }

      final uri = Uri.tryParse(rawUrl);
      if (uri == null) {
        continue;
      }

      final scheme = uri.scheme.toLowerCase();
      if (scheme != 'http' && scheme != 'https') {
        continue;
      }

      final title = (item.title ?? '').trim();
      entries.add(
        _BookmarkEntry(
          url: uri.toString(),
          title: title.isEmpty ? uri.toString() : title,
          addDateSeconds: item.createdAt.toUtc().millisecondsSinceEpoch ~/ 1000,
        ),
      );
    }

    entries.sort((a, b) => a.url.toLowerCase().compareTo(b.url.toLowerCase()));

    final escape = const HtmlEscape(HtmlEscapeMode.element);
    final buffer = StringBuffer()
      ..writeln('<!DOCTYPE NETSCAPE-Bookmark-file-1>')
      ..writeln('<!-- This is an automatically generated file. -->')
      ..writeln('<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">')
      ..writeln('<TITLE>Bookmarks</TITLE>')
      ..writeln('<H1>Bookmarks</H1>')
      ..writeln('<DL><p>');

    for (final entry in entries) {
      final escapedUrl = escape.convert(entry.url);
      final escapedTitle = escape.convert(entry.title);
      buffer.writeln(
        '    <DT><A HREF="$escapedUrl" ADD_DATE="${entry.addDateSeconds}">$escapedTitle</A>',
      );
    }

    buffer.writeln('</DL><p>');
    return buffer.toString();
  }

  Future<File> exportBookmarksFile({Directory? outputDirectory}) async {
    final html = await exportBookmarksHtml();
    final directory = outputDirectory ?? await Directory.systemTemp.createTemp('mnemata_bookmarks_');
    final timestamp = _nowProvider().toUtc().toIso8601String().replaceAll(':', '-');
    final file = File('${directory.path}/mnemata-bookmarks-$timestamp.html');
    await file.writeAsString(html);
    return file;
  }
}

class _BookmarkEntry {
  const _BookmarkEntry({
    required this.url,
    required this.title,
    required this.addDateSeconds,
  });

  final String url;
  final String title;
  final int addDateSeconds;
}
