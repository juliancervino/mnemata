import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:mnemata/features/ingestion/services/archive_content_processor.dart';
import 'package:mnemata/features/ingestion/services/extraction_service.dart';
import 'package:readability/article.dart' as readability;

class _NoopReadabilityWrapper extends ReadabilityWrapper {
  @override
  Future<readability.Article?> parse(String url) async => null;

  @override
  Future<readability.Article?> parseHtml(String html) async => null;
}

void main() {
  final processor = ArchiveContentProcessor(_NoopReadabilityWrapper());

  const cases = [
    'https://archive.ph/PaXo1',
    'https://archive.today/Ce37o',
    'https://archive.today/nO3gI',
    'https://archive.today/DB3QL',
    'https://archive.today/BsvJE',
    'https://archive.today/Pkmsf',
    'https://archive.today/jdYUj',
  ];

  for (final url in cases) {
    test(
      'extracts meaningful content for $url',
      () async {
        final html = await _fetchArchiveHtmlWithRetries(url);

        final result = await processor
            .extractFromCapturedHtml(sourceUrl: url, rawHtml: html)
            .timeout(const Duration(seconds: 45));

        expect(result.title.trim(), isNotEmpty,
            reason: 'Title should not be empty');

        final text = (html_parser.parse(result.content).body?.text ?? '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        expect(text.length, greaterThan(180),
            reason: 'Extracted content should be substantial');

        final lower = text.toLowerCase();
        for (final marker in const [
          '__next',
          'skip to main content',
          'what to read next',
          'join the conversation',
          'buy me a coffee',
          'download .zip',
        ]) {
          expect(lower.contains(marker), isFalse,
              reason: 'Noise marker "$marker" should be removed');
        }

        final noiseHits = processor.countNoiseKeywordHits(text);
        expect(noiseHits, lessThanOrEqualTo(1),
            reason: 'Content should have low residual noise');
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  }
}

Future<String> _fetchArchiveHtmlWithRetries(String url) async {
  final uri = Uri.parse(url);
  final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';

  final fallbackUrls = <String>{
    url,
    if (id.isNotEmpty) 'https://archive.today/$id',
    if (id.isNotEmpty) 'https://archive.ph/$id',
    if (id.isNotEmpty) 'https://archive.is/$id',
  }.toList();

  final client = http.Client();
  try {
    Object? lastError;
    for (final candidate in fallbackUrls) {
      for (var attempt = 1; attempt <= 4; attempt++) {
        try {
          final response = await client
              .get(
                Uri.parse(candidate),
                headers: const {
                  'User-Agent':
                      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                  'Accept-Language': 'en-US,en;q=0.9',
                },
              )
              .timeout(const Duration(seconds: 25));

          if (response.statusCode == 200 && response.body.isNotEmpty) {
            return response.body;
          }

          lastError =
              'HTTP ${response.statusCode} for $candidate (attempt $attempt)';
        } catch (e) {
          lastError = e;
        }

        await Future<void>.delayed(Duration(seconds: attempt * 2));
      }
    }

    throw StateError('Unable to fetch archive html for $url: $lastError');
  } finally {
    client.close();
  }
}
