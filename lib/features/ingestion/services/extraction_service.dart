import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:favicon/favicon.dart' as fav;
import 'package:http/http.dart' as http;
import 'package:mnemata/features/ingestion/services/metadata_extraction_service.dart';
import 'package:mnemata/features/ingestion/services/readability_platform.dart'
    as readability;

class ExtractionBlockedException implements Exception {
  final int? statusCode;
  final String? message;

  ExtractionBlockedException({this.statusCode, this.message});

  @override
  String toString() =>
      'ExtractionBlockedException: ${message ?? 'Blocked (status: $statusCode)'}';
}

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
  final MetadataExtractionService _metadataService;
  final http.Client _client;
  static const String _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  ExtractionService([
    ReadabilityWrapper? wrapper,
    MetadataExtractionService? metadataService,
    http.Client? client,
  ]) : _wrapper = wrapper ?? ReadabilityWrapper(),
       _metadataService = metadataService ?? MetadataExtractionService(),
       _client = client ?? http.Client();

  Future<({String title, String content, String? thumbnailUrl})?>
  extractContent(String url) async {
    try {
      String? html;

      // 1. Try direct fetch
      try {
        final response = await _client
            .get(Uri.parse(url), headers: {'User-Agent': _userAgent})
            .timeout(const Duration(seconds: 10));

        _checkFailureHeuristics(response.statusCode, response.body);

        if (response.statusCode == 200) {
          html = response.body;
        }
      } catch (e) {
        if (e is ExtractionBlockedException) rethrow;
        debugPrint('Direct fetch failed for $url: $e');
      }

      // 2. Web/CORS Fallback: Tiered proxies
      if (html == null && kIsWeb) {
        html = await _fetchViaCorsProxy(url);
        if (html == null) {
          html = await _fetchViaAllOrigins(url);
        }
      }

      if (html != null) {
        return await _processHtml(html, url);
      }

      // 3. Last ditch: try the platform's native parse (might work on mobile/desktop)
      final result = await _wrapper.parse(url);
      if (result != null) {
        return (
          title: result.title ?? '',
          content: result.content ?? '',
          thumbnailUrl: null,
        );
      }

      return null;
    } catch (e) {
      if (e is ExtractionBlockedException) rethrow;
      debugPrint('Extraction error for $url: $e');
      return null;
    }
  }

  Future<String?> _fetchViaCorsProxy(String url) async {
    try {
      final proxyUrl = 'https://corsproxy.io/?${Uri.encodeComponent(url)}';
      final response = await _client
          .get(Uri.parse(proxyUrl))
          .timeout(const Duration(seconds: 15));

      _checkFailureHeuristics(response.statusCode, response.body);

      if (response.statusCode == 200) {
        return response.body;
      }
    } catch (_) {}
    return null;
  }

  Future<String?> _fetchViaAllOrigins(String url) async {
    try {
      final proxyUrl =
          'https://api.allorigins.win/get?url=${Uri.encodeComponent(url)}';
      final response = await _client
          .get(Uri.parse(proxyUrl))
          .timeout(const Duration(seconds: 15));

      _checkFailureHeuristics(response.statusCode, response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['contents'] as String?;
      }
    } catch (_) {}
    return null;
  }

  Future<({String title, String content, String? thumbnailUrl})?> _processHtml(
    String html,
    String? originalUrl,
  ) async {
    final metadata = _metadataService.extract(html);
    final article = await _wrapper.parseHtml(html);

    String? thumbnailUrl = metadata.image;
    if (thumbnailUrl == null && originalUrl != null) {
      try {
        final icon = await fav.FaviconFinder.getBest(originalUrl);
        thumbnailUrl = icon?.url;
      } catch (_) {}
    }

    return (
      title: metadata.title ?? article?.title ?? '',
      content: article?.content ?? metadata.description ?? '',
      thumbnailUrl: thumbnailUrl,
    );
  }

  void _checkFailureHeuristics(int statusCode, String body) {
    if (statusCode == 403 || statusCode == 429) {
      throw ExtractionBlockedException(statusCode: statusCode);
    }
    if (body.contains('Cloudflare') || body.contains('Access Denied')) {
      throw ExtractionBlockedException(message: 'Blocked by anti-bot protection');
    }
  }

  @Deprecated('Use _fetchViaCorsProxy or _fetchViaAllOrigins')
  Future<({String title, String content})?> _extractFromReadableProxy(
    String originalUrl,
  ) async {
    return null;
  }
}
