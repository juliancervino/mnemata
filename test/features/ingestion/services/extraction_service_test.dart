import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:mnemata/features/ingestion/services/extraction_service.dart';
import 'package:mnemata/features/ingestion/services/metadata_extraction_service.dart';
import 'package:mnemata/features/ingestion/services/readability_platform.dart' as readability;

class MockReadabilityWrapper extends Mock implements ReadabilityWrapper {}
class MockMetadataExtractionService extends Mock implements MetadataExtractionService {}
class MockHttpClient extends Mock implements http.Client {}
class MockArticle extends Mock implements readability.Article {}

void main() {
  late ExtractionService extractionService;
  late MockReadabilityWrapper mockReadabilityWrapper;
  late MockMetadataExtractionService mockMetadataService;
  late MockHttpClient mockHttpClient;

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  setUp(() {
    mockReadabilityWrapper = MockReadabilityWrapper();
    mockMetadataService = MockMetadataExtractionService();
    mockHttpClient = MockHttpClient();
    extractionService = ExtractionService(
      mockReadabilityWrapper,
      mockMetadataService,
      mockHttpClient,
    );
  });

  group('ExtractionService', () {
    const testUrl = 'https://example.com/article';
    const testHtml = '<html><body><h1>Test Title</h1><p>Test Content</p></body></html>';

    test('direct fetch success', () async {
      when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(testHtml, 200));
      
      when(() => mockMetadataService.extract(any())).thenReturn(
        ExtractedMetadata(title: 'Meta Title', description: 'Meta Desc'),
      );
      
      final mockArticle = MockArticle();
      when(() => mockArticle.title).thenReturn('Reader Title');
      when(() => mockArticle.content).thenReturn('Reader Content');

      when(() => mockReadabilityWrapper.parseHtml(any())).thenAnswer(
        (_) async => mockArticle,
      );

      final result = await extractionService.extractContent(testUrl);

      expect(result?.title, 'Meta Title');
      expect(result?.content, 'Reader Content');
      verify(() => mockHttpClient.get(Uri.parse(testUrl), headers: any(named: 'headers'))).called(1);
    });

    test('failure heuristics - throws ExtractionBlockedException on 403', () async {
       when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('Forbidden', 403));

       expect(
         () => extractionService.extractContent(testUrl),
         throwsA(isA<ExtractionBlockedException>()),
       );
    });

    test('failure heuristics - throws ExtractionBlockedException on Cloudflare', () async {
       when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('Just a moment... Cloudflare', 200));

       expect(
         () => extractionService.extractContent(testUrl),
         throwsA(isA<ExtractionBlockedException>()),
       );
    });
  });
}
