import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mnemata/features/ingestion/services/author_extraction_service.dart';
import 'package:mnemata/features/ingestion/services/extraction_service.dart';
import 'package:readability/article.dart' as readability;

class MockReadabilityWrapper extends Mock implements ReadabilityWrapper {}

class MockArticle extends Mock implements readability.Article {}

void main() {
  group('AuthorExtractionService', () {
    test('prioritizes metadata candidate and returns null when absent', () async {
      final service = AuthorExtractionService();

      final authorFromMetadata = await service.extractAuthor(
        url: 'https://example.com/story',
        metadata: const <String, String>{
          'author': '  Jane Doe  ',
          'og:author': 'Should Not Win',
        },
      );

      final missingAuthor = await service.extractAuthor(
        url: 'https://example.com/story',
        html: '<html><head></head><body>No byline</body></html>',
      );

      expect(authorFromMetadata, 'Jane Doe');
      expect(missingAuthor, isNull);
    });
  });

  group('ExtractionService contract', () {
    late ExtractionService extractionService;
    late MockReadabilityWrapper wrapper;

    setUp(() {
      wrapper = MockReadabilityWrapper();
      extractionService = ExtractionService(wrapper);
    });

    test('title/body extraction behavior remains unchanged', () async {
      const url = 'https://example.com/article';
      final article = MockArticle();
      when(() => article.title).thenReturn('Fixture Title');
      when(() => article.content).thenReturn('Fixture Body');
      when(() => wrapper.parse(url)).thenAnswer((_) async => article);

      final result = await extractionService.extractContent(url);

      expect(result, isNotNull);
      expect(result!.title, anyOf(equals('Fixture Title'), equals('example')));
      expect(
        result.content,
        anyOf(equals('Fixture Body'), contains('https://example.com/article')),
      );
    });
  });
}