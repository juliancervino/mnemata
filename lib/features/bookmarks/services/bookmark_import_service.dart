import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:mnemata/core/database/app_database.dart';

class BookmarkImportService {
  BookmarkImportService({
    required AppDatabase database,
    DateTime Function()? nowProvider,
    int maxImportBytes = defaultMaxImportBytes,
  }) : _database = database,
       _nowProvider = nowProvider ?? DateTime.now,
       _maxImportBytes = maxImportBytes;

  static const int defaultMaxImportBytes = 5 * 1024 * 1024;

  final AppDatabase _database;
  final DateTime Function() _nowProvider;
  final int _maxImportBytes;

  List<String> extractUrlsFromHtml(String html) {
    _enforceImportSizeLimit(utf8.encode(html).length);

    final document = html_parser.parse(html);
    final seen = <String>{};
    final urls = <String>[];

    for (final anchor in document.querySelectorAll('a[href]')) {
      final href = anchor.attributes['href'];
      final normalized = _normalizeAndValidateHttpUrl(href);
      if (normalized == null) {
        continue;
      }

      if (!seen.add(normalized)) {
        continue;
      }

      urls.add(normalized);
    }

    return urls;
  }

  Future<BookmarkImportResult> importBookmarksFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw BookmarkImportException('Bookmark file does not exist.');
    }

    final fileSize = await file.length();
    _enforceImportSizeLimit(fileSize);

    final html = await file.readAsString();
    return importBookmarksHtml(html);
  }

  Future<BookmarkImportResult> importBookmarksHtml(String html) async {
    _enforceImportSizeLimit(utf8.encode(html).length);

    final document = html_parser.parse(html);
    final seenInImport = <String>{};

    var imported = 0;
    var duplicates = 0;
    var invalid = 0;

    for (final anchor in document.querySelectorAll('a')) {
      final href = anchor.attributes['href'];
      final normalized = _normalizeAndValidateHttpUrl(href);
      if (normalized == null) {
        invalid += 1;
        continue;
      }

      if (!seenInImport.add(normalized)) {
        duplicates += 1;
        continue;
      }

      final existing = await _database.getItemByCanonicalUrl(normalized);
      if (existing != null) {
        duplicates += 1;
        continue;
      }

      final title = anchor.text.trim();
      await _database.insertItem(
        MnemataItemsCompanion.insert(
          title: Value(title.isEmpty ? normalized : title),
          url: Value(normalized),
          type: 'url',
          createdAt: _nowProvider().toUtc(),
        ),
      );
      imported += 1;
    }

    return BookmarkImportResult(
      importedCount: imported,
      duplicateCount: duplicates,
      invalidCount: invalid,
    );
  }

  void _enforceImportSizeLimit(int sizeBytes) {
    if (sizeBytes > _maxImportBytes) {
      throw BookmarkImportException(
        'Bookmark file is too large. Maximum supported size is $_maxImportBytes bytes.',
      );
    }
  }

  String? _normalizeAndValidateHttpUrl(String? rawHref) {
    if (rawHref == null) {
      return null;
    }

    final trimmed = rawHref.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final parsed = Uri.tryParse(trimmed);
    if (parsed == null) {
      return null;
    }

    final scheme = parsed.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') {
      return null;
    }

    if (parsed.host.trim().isEmpty) {
      return null;
    }

    var normalized = parsed.normalizePath().replace(
      scheme: scheme,
      host: parsed.host.toLowerCase(),
      fragment: null,
    );

    if ((scheme == 'http' && normalized.hasPort && normalized.port == 80) ||
        (scheme == 'https' && normalized.hasPort && normalized.port == 443)) {
      normalized = normalized.replace(port: null);
    }

    if (normalized.path == '/' && !normalized.hasQuery) {
      normalized = normalized.replace(path: '');
    } else if (normalized.path.endsWith('/') && !normalized.hasQuery) {
      normalized = normalized.replace(
        path: normalized.path.substring(0, normalized.path.length - 1),
      );
    }

    return normalized.toString();
  }
}

class BookmarkImportResult {
  const BookmarkImportResult({
    required this.importedCount,
    required this.duplicateCount,
    required this.invalidCount,
  });

  final int importedCount;
  final int duplicateCount;
  final int invalidCount;
}

class BookmarkImportException implements Exception {
  const BookmarkImportException(this.message);

  final String message;

  @override
  String toString() => 'BookmarkImportException: $message';
}
