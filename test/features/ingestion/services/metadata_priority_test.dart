import 'package:flutter_test/flutter_test.dart';
import 'package:mnemata/features/ingestion/services/metadata_extraction_service.dart';

void main() {
  late MetadataExtractionService service;

  setUp(() {
    service = MetadataExtractionService();
  });

  group('Metadata Priority Logic', () {
    test('JSON-LD takes priority over OG', () {
      const html = '''
        <html>
          <head>
            <script type="application/ld+json">
              {
                "@context": "https://schema.org",
                "@type": "Article",
                "headline": "JSON-LD Title",
                "author": { "@type": "Person", "name": "JSON-LD Author" }
              }
            </script>
            <meta property="og:title" content="OG Title" />
            <meta property="og:article:author" content="OG Author" />
          </head>
          <body>
            <h1>H1 Title</h1>
          </body>
        </html>
      ''';

      final metadata = service.extract(html);
      expect(metadata.title, equals('JSON-LD Title'));
      expect(metadata.author, equals('JSON-LD Author'));
    });

    test('OG takes priority over DOM heuristics', () {
      const html = '''
        <html>
          <head>
            <meta property="og:title" content="OG Title" />
          </head>
          <body>
            <h1>H1 Title</h1>
          </body>
        </html>
      ''';

      final metadata = service.extract(html);
      expect(metadata.title, equals('OG Title'));
    });

    test('DOM heuristics as last resort', () {
      const html = '''
        <html>
          <head>
            <title>Page Title</title>
          </head>
          <body>
            <h1>H1 Title</h1>
          </body>
        </html>
      ''';

      final metadata = service.extract(html);
      expect(metadata.title, equals('Page Title'));
    });

    test('Twitter tags priority after OG', () {
      const html = '''
        <html>
          <head>
            <meta name="twitter:title" content="Twitter Title" />
          </head>
          <body>
            <h1>H1 Title</h1>
          </body>
        </html>
      ''';

      final metadata = service.extract(html);
      expect(metadata.title, equals('Twitter Title'));
    });
  });
}
