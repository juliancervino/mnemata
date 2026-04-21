import 'package:flutter/foundation.dart';
import 'package:favicon/favicon.dart' as fav;
import 'package:http/http.dart' as http;
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:mnemata/features/ingestion/services/readability_platform.dart'
    as readability;

class ReadabilityWrapper {
  Future<readability.Article?> parse(String url) => readability.parseAsync(url);

  Future<readability.Article?> parseHtml(String html) async {
    final normalizedHtml = _ensureHtmlDocument(html);
    return readability.parseHtmlDocument(normalizedHtml);
  }

  String _ensureHtmlDocument(String html) {
    final trimmed = html.trim();
    if (trimmed.contains(RegExp(r'<html[\s>]?', caseSensitive: false))) {
      return trimmed;
    }
    return '<!doctype html><html><body>$trimmed</body></html>';
  }
}

class ExtractionService {
  final ReadabilityWrapper _wrapper;
  static const String _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  ExtractionService([ReadabilityWrapper? wrapper])
    : _wrapper = wrapper ?? ReadabilityWrapper();

  Future<({String title, String content, String? thumbnailUrl})?>
  extractContent(String url) async {
    try {
      // 1. Extract metadata (Title and Open Graph Image) using the library's internal fetch
      // We still try to fetch HTML manually for the manual fallback if needed
      final metadata = await _safeExtractMetadata(url);
      String? title = metadata?.title;
      String? thumbnailUrl = metadata?.image;
      String? description = metadata?.description;

      // Filter out common useless titles like "www"
      if (title != null &&
          (title.toLowerCase() == 'www' || title.toLowerCase() == 'www.')) {
        title = null;
      }

      // 2. If no title, try a manual fetch with User-Agent for robustness
      if (title == null || title.isEmpty) {
        try {
          final response = await http
              .get(Uri.parse(url), headers: {'User-Agent': _userAgent})
              .timeout(const Duration(seconds: 10));

          if (response.statusCode == 200) {
            title = _extractTitleManually(response.body);
          }
        } catch (_) {
          // Keep extraction non-fatal when fallback fetch is unavailable.
        }
      }

      // 3. If no OG image, try fetching a high-res favicon
      if (thumbnailUrl == null || thumbnailUrl.isEmpty) {
        try {
          final icon = await fav.FaviconFinder.getBest(url);
          thumbnailUrl = icon?.url;
        } catch (_) {
          // Keep extraction non-fatal when favicon lookup fails.
        }
      }

      // 4. Extract main content using readability
      final result = await _wrapper.parse(url);

      // Web fallback: use a readable proxy when browser CORS blocks direct fetches.
      ({String title, String content})? webFallback;
      if (kIsWeb && result == null) {
        webFallback = await _extractFromReadableProxy(url);
      }

      if (result == null && title == null && webFallback == null) return null;

      String? finalContent = result?.content;
      if (finalContent == null || finalContent.isEmpty) {
        finalContent = webFallback?.content ?? description;
      }

      return (
        title: title ?? result?.title ?? webFallback?.title ?? '',
        content: finalContent ?? '',
        thumbnailUrl: thumbnailUrl,
      );
    } catch (e) {
      debugPrint('Extraction error for $url: $e');
      return null;
    }
  }

  Future<({String title, String content})?> _extractFromReadableProxy(
    String originalUrl,
  ) async {
    try {
      final proxyUri = Uri.parse('https://r.jina.ai/$originalUrl');
      final response = await http
          .get(proxyUri, headers: {'User-Agent': _userAgent})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return null;
      }

      final body = response.body.trim();
      if (body.isEmpty) {
        return null;
      }

      String title = '';
      for (final line in body.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.toLowerCase().startsWith('title:')) {
          title = trimmed.substring('title:'.length).trim();
          break;
        }
        if (trimmed.startsWith('# ')) {
          title = trimmed.substring(2).trim();
          break;
        }
      }

      return (title: title, content: body);
    } catch (_) {
      return null;
    }
  }

  Future<Metadata?> _safeExtractMetadata(String url) async {
    try {
      return await MetadataFetch.extract(url);
    } catch (_) {
      return null;
    }
  }

  String? _extractTitleManually(String html) {
    try {
      final regExp = RegExp(
        r'<title[^>]*>(.*?)</title>',
        caseSensitive: false,
        dotAll: true,
      );
      final match = regExp.firstMatch(html);
      if (match != null && match.groupCount >= 1) {
        return match.group(1)?.trim();
      }
    } catch (e) {
      debugPrint('Manual title extraction error: $e');
    }
    return null;
  }
}
