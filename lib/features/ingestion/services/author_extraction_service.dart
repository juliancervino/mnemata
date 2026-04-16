import 'package:http/http.dart' as http;

class AuthorExtractionService {
  AuthorExtractionService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  Future<String?> extractAuthor({
    required String url,
    Map<String, String>? metadata,
    String? html,
  }) async {
    final metadataCandidate = _extractFromMetadata(metadata ?? const <String, String>{});
    if (metadataCandidate != null) {
      return metadataCandidate;
    }

    final htmlSource = html ?? await _fetchHtml(url);
    if (htmlSource == null || htmlSource.isEmpty) {
      return null;
    }

    return _extractFromHtml(htmlSource);
  }

  Future<String?> _fetchHtml(String url) async {
    try {
      final response = await _client.get(
        Uri.parse(url),
        headers: const <String, String>{'User-Agent': _userAgent},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body;
      }
    } catch (_) {}

    return null;
  }

  String? _extractFromMetadata(Map<String, String> metadata) {
    const keysByPriority = <String>[
      'author',
      'article:author',
      'og:author',
      'twitter:creator',
      'byline',
    ];

    for (final key in keysByPriority) {
      final candidate = metadata[key];
      final sanitized = _sanitizeCandidate(candidate);
      if (sanitized != null) {
        return sanitized;
      }
    }

    return null;
  }

  String? _extractFromHtml(String html) {
    final metaTagMatch = RegExp(
      "<meta[^>]+(?:name|property|itemprop)=[\"'](?:author|article:author|og:author|twitter:creator)[\"'][^>]*content=[\"']([^\"']+)[\"']",
      caseSensitive: false,
    ).firstMatch(html);
    final fromMetaTag = _sanitizeCandidate(metaTagMatch?.group(1));
    if (fromMetaTag != null) {
      return fromMetaTag;
    }

    final relAuthorMatch = RegExp(
      "<a[^>]+rel=[\"']author[\"'][^>]*>([^<]+)</a>",
      caseSensitive: false,
    ).firstMatch(html);
    final fromRelAuthor = _sanitizeCandidate(relAuthorMatch?.group(1));
    if (fromRelAuthor != null) {
      return fromRelAuthor;
    }

    final bylineBlockMatch = RegExp(
      "<(?:span|p|div)[^>]+(?:class|id)=[\"'][^\"']*(?:author|byline)[^\"']*[\"'][^>]*>([^<]{2,120})</(?:span|p|div)>",
      caseSensitive: false,
    ).firstMatch(html);
    return _sanitizeCandidate(bylineBlockMatch?.group(1));
  }

  String? _sanitizeCandidate(String? raw) {
    if (raw == null) {
      return null;
    }

    var normalized = raw.trim();
    if (normalized.isEmpty) {
      return null;
    }

    normalized = normalized.replaceFirst(RegExp(r'^by\s+', caseSensitive: false), '');
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (normalized.isEmpty) {
      return null;
    }

    final lower = normalized.toLowerCase();
    final looksUnsafe = lower.contains('<script') ||
        lower.contains('</script') ||
        lower.contains('javascript:') ||
        normalized.contains('<') ||
        normalized.contains('>');
    if (looksUnsafe) {
      return null;
    }

    if (normalized.length > 120) {
      normalized = normalized.substring(0, 120).trimRight();
    }

    return normalized.isEmpty ? null : normalized;
  }
}