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

  Future<readability.Article?> parseWithBrowser(String url) =>
      readability.parseWithBrowser(url);

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
  final ReadabilityWrapper? _wrapper;
  final MetadataExtractionService _metadataService;
  final http.Client _client;
  final bool _isWeb;
  static const String _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  ExtractionService([
    ReadabilityWrapper? wrapper,
    MetadataExtractionService? metadataService,
    http.Client? client,
    bool? isWeb,
  ]) : _wrapper = wrapper,
       _metadataService = metadataService ?? MetadataExtractionService(),
       _client = client ?? http.Client(),
       _isWeb = isWeb ?? kIsWeb;

  ReadabilityWrapper get _effectiveWrapper => _wrapper ?? ReadabilityWrapper();

  Future<({String title, String content, String? thumbnailUrl, String? author, List<String> initialHighlights})?>
  extractContent(String url) async {
    try {
      if (_isWeb) {
        String? html;

        // 1. Try direct fetch
        try {
          final response = await _client
              .get(Uri.parse(url), headers: {
                if (!_isWeb) 'User-Agent': _userAgent,
              })
              .timeout(const Duration(seconds: 10));

          _checkFailureHeuristics(response.statusCode, response.body);

          if (response.statusCode == 200) {
            html = response.body;
          }
        } catch (e) {
          if (e is ExtractionBlockedException) rethrow;
          debugPrint('Direct fetch failed for $url: $e');
        }

        // 2. Web/CORS Fallback & processing: Tiered proxies
        if (html == null) {
          html = await _fetchViaCorsProxy(url);
          html ??= await _fetchViaAllOrigins(url);
        }

        if (html != null) {
          return await processRawHtml(html, url: url);
        }

        return null;
      } else {
        // Mobile Flow: Use native parse directly as it used to be
        // Fast check for blocks before native parsing
        String? html;
        try {
          final response = await _client
              .get(Uri.parse(url), headers: {
                if (!_isWeb) 'User-Agent': _userAgent,
              })
              .timeout(const Duration(seconds: 10));
          _checkFailureHeuristics(response.statusCode, response.body);
          if (response.statusCode == 200) {
            html = response.body;
          }
        } on ExtractionBlockedException {
          rethrow;
        } catch (e) {
          // Generic network errors don't block mobile flow
          debugPrint('Mobile direct fetch check failed: $e');
        }

        final result = await _effectiveWrapper.parse(url);
        if (result != null) {
          final metadata = html != null ? _metadataService.extract(html) : null;
          
          // Attempt to find a thumbnail for mobile
          String? thumbnailUrl = metadata?.image;
          if (thumbnailUrl == null) {
            try {
              final icon = await fav.FaviconFinder.getBest(url);
              thumbnailUrl = icon?.url;
            } catch (_) {}
          }

          return (
            title: result.title ?? metadata?.title ?? '',
            content: result.content ?? '',
            thumbnailUrl: thumbnailUrl,
            author: metadata?.author,
            initialHighlights: <String>[],
          );
        }
        return null;
      }
    } catch (e) {
      if (e is ExtractionBlockedException) rethrow;
      debugPrint('Extraction error for $url: $e');
      return null;
    }
  }

  Future<({String title, String content, String? thumbnailUrl, String? author, List<String> initialHighlights})?>
  processRawHtml(
    String html, {
    String? url,
  }) async {
    // Detect if this is actually Markdown with YAML frontmatter (Obsidian style)
    final trimmed = html.trim();
    if (trimmed.startsWith('---') && (trimmed.contains('\n---\n') || trimmed.contains('\n--- '))) {
      final mdResult = await _processMarkdownWithFrontmatter(trimmed);
      if (mdResult != null) return mdResult;
    }
    return _processHtml(html, url);
  }

  Future<({String title, String content, String? thumbnailUrl, String? author, List<String> initialHighlights})?>
  _processMarkdownWithFrontmatter(String raw) async {
    // RegEx to find YAML frontmatter (between --- and --- at start of string)
    final frontmatterRegex = RegExp(r'^---\s*\n([\s\S]*?)\n---\s*\n', multiLine: true);
    final match = frontmatterRegex.firstMatch(raw);
    
    if (match == null) return null;

    final frontmatter = match.group(1) ?? '';
    String content = raw.substring(match.end).trim();

    // Extract highlights ==text== and remove the marks
    final highlightRegex = RegExp(r'==(.+?)==');
    final initialHighlights = <String>[];
    
    final highlightMatches = highlightRegex.allMatches(content);
    for (final m in highlightMatches) {
      final text = m.group(1);
      if (text != null && text.isNotEmpty) {
        initialHighlights.add(text);
      }
    }

    // Clean up == markers
    content = content.replaceAll('==', '');

    // Parse frontmatter
    String title = '';
    String? author;

    final titleMatch = RegExp(r'^title:\s*\"?(.+?)\"?$', multiLine: true).firstMatch(frontmatter);
    if (titleMatch != null) {
      title = titleMatch.group(1) ?? '';
    }

    final authorMatch = RegExp(r'^author:\s*\"?(.+?)\"?$', multiLine: true).firstMatch(frontmatter);
    if (authorMatch != null) {
      author = authorMatch.group(1) ?? '';
      // Clean up author (Obsidian links [[]] and quotes)
      author = author
          .replaceAll('[[', '')
          .replaceAll(']]', '')
          .replaceAll('"', '')
          .replaceAll("'", '')
          .trim();
    }

    return (
      title: title.isNotEmpty ? title : 'Untitled Clipping',
      content: content,
      thumbnailUrl: null,
      author: author,
      initialHighlights: initialHighlights,
    );
  }

  Future<String?> _fetchViaCorsProxy(String url) async {
    try {
      final proxyUrl =
          'https://corsproxy.io/?${Uri.encodeComponent(url)}';
      final response = await _client
          .get(Uri.parse(proxyUrl))
          .timeout(const Duration(seconds: 15));

      _checkFailureHeuristics(response.statusCode, response.body);

      if (response.statusCode == 200) {
        return response.body;
      }
    } on ExtractionBlockedException {
      rethrow;
    } catch (e) {
      debugPrint('corsproxy.io failed for $url: $e');
    }
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
    } on ExtractionBlockedException {
      rethrow;
    } catch (e) {
      debugPrint('allorigins.win failed for $url: $e');
    }
    return null;
  }

  Future<({String title, String content, String? thumbnailUrl, String? author, List<String> initialHighlights})?> _processHtml(
    String html,
    String? originalUrl,
  ) async {
    final metadata = _metadataService.extract(html);
    final article = await _effectiveWrapper.parseHtml(html);

    String? thumbnailUrl = metadata.image;
    if (thumbnailUrl == null && originalUrl != null) {
      try {
        final icon = await fav.FaviconFinder.getBest(originalUrl);
        thumbnailUrl = icon?.url;
      } catch (_) {}
    }

    // Tiered content selection: prefer the most complete version
    String content = article?.content ?? '';
    final jsonLdContent = metadata.articleBody ?? '';

    // If JSON-LD has more content than readability (often happens with paywalls/stubs), use it
    if (jsonLdContent.length > content.length) {
      content = jsonLdContent;
    }

    // Fallback to description if everything else is empty or suspiciously short
    // (e.g. less than 200 chars while description is longer)
    final description = metadata.description ?? '';
    final isPaywalled = html.toLowerCase().contains('paywall') ||
        html.toLowerCase().contains('suscríbete') ||
        html.toLowerCase().contains('este contenido es exclusivo para suscriptores');

    if ((content.length < 250 || isPaywalled) &&
        description.length > content.length) {
      content = description;
    }

    return (
      title: metadata.title ?? article?.title ?? 'Untitled Clipping',
      content: content,
      thumbnailUrl: thumbnailUrl,
      author: metadata.author,
      initialHighlights: <String>[],
    );
  }

  void _checkFailureHeuristics(int statusCode, String body) {
    final lowerBody = body.toLowerCase();
    
    // Check for explicit blocks
    if (statusCode == 403 || statusCode == 429) {
      throw ExtractionBlockedException(statusCode: statusCode);
    }

    // Check for Cloudflare / WAF challenges
    if (lowerBody.contains('cloudflare') && 
        (lowerBody.contains('ray id') || lowerBody.contains('checking your browser'))) {
      throw ExtractionBlockedException(message: 'Cloudflare/WAF block detected');
    }

    if (lowerBody.contains('access denied') || lowerBody.contains('permission denied')) {
      if (statusCode >= 400) {
        throw ExtractionBlockedException(statusCode: statusCode, message: 'Access Denied');
      }
    }
  }
}
