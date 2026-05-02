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
    
    // Default mock behavior
    when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response('Not Found', 404));
    when(() => mockReadabilityWrapper.parse(any())).thenAnswer((_) async => null);
    when(() => mockReadabilityWrapper.parseHtml(any())).thenAnswer((_) async => null);
    when(() => mockMetadataService.extract(any())).thenReturn(
      ExtractedMetadata(title: 'Default Title', description: 'Default Desc'),
    );
  });

  group('ExtractionService (Mobile Flow)', () {
    const testUrl = 'https://example.com/article';
    late ExtractionService service;

    setUp(() {
      service = ExtractionService(
        mockReadabilityWrapper,
        mockMetadataService,
        mockHttpClient,
        false, // isWeb = false
      );
    });

    test('mobile uses native parse directly', () async {
      final mockArticle = MockArticle();
      when(() => mockArticle.title).thenReturn('Native Title');
      when(() => mockArticle.content).thenReturn('Native Content');
      
      when(() => mockReadabilityWrapper.parse(testUrl)).thenAnswer(
        (_) async => mockArticle,
      );

      final result = await service.extractContent(testUrl);

      expect(result?.title, 'Native Title');
      expect(result?.content, 'Native Content');
      
      // Verify that direct fetch was NOT called
      verifyNever(() => mockHttpClient.get(any(), headers: any(named: 'headers')));
      // Verify native parse WAS called
      verify(() => mockReadabilityWrapper.parse(testUrl)).called(1);
    });

    test('mobile does not throw on 403 (it should just return null if native parse also fails)', () async {
       // Even if we mock the client, it shouldn't be called
       when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('Forbidden', 403));
       
       when(() => mockReadabilityWrapper.parse(testUrl)).thenAnswer((_) async => null);

       final result = await service.extractContent(testUrl);
       expect(result, isNull);
       
       verifyNever(() => mockHttpClient.get(any(), headers: any(named: 'headers')));
    });
  });

  group('ExtractionService (Web Flow)', () {
    const testUrl = 'https://example.com/article';
    const testHtml = '<html><body><h1>Test Title</h1><p>Test Content</p></body></html>';
    late ExtractionService service;

    setUp(() {
      service = ExtractionService(
        mockReadabilityWrapper,
        mockMetadataService,
        mockHttpClient,
        true, // isWeb = true
      );
    });

    test('direct fetch success (processRawHtml)', () async {
      when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(testHtml, 200));
      
      when(() => mockMetadataService.extract(any())).thenReturn(
        ExtractedMetadata(title: 'Meta Title', description: 'Meta Desc'),
      );
      
      final longContent = 'A' * 300;
      final mockArticle = MockArticle();
      when(() => mockArticle.title).thenReturn('Reader Title');
      when(() => mockArticle.content).thenReturn(longContent);

      when(() => mockReadabilityWrapper.parseHtml(any())).thenAnswer(
        (_) async => mockArticle,
      );

      final result = await service.extractContent(testUrl);

      expect(result?.title, 'Meta Title');
      expect(result?.content, longContent);
      verify(() => mockReadabilityWrapper.parseHtml(testHtml)).called(1);
    });

    test('fallback to CORS proxy on 404', () async {
      when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((invocation) async {
            final uri = invocation.positionalArguments[0] as Uri;
            if (uri.toString().contains('corsproxy.io')) {
              return http.Response(testHtml, 200);
            } else {
              return http.Response('Not Found', 404);
            }
          });
      
      when(() => mockMetadataService.extract(any())).thenReturn(
        ExtractedMetadata(title: 'Proxy Title', description: 'Proxy Desc'),
      );
      
      final longContent = 'B' * 300;
      final mockArticle = MockArticle();
      when(() => mockArticle.title).thenReturn('Reader Title');
      when(() => mockArticle.content).thenReturn(longContent);

      when(() => mockReadabilityWrapper.parseHtml(any())).thenAnswer(
        (_) async => mockArticle,
      );

      final result = await service.extractContent(testUrl);

      expect(result?.title, 'Proxy Title');
      expect(result?.content, longContent);
      verify(() => mockHttpClient.get(any(that: predicate<Uri>((uri) => uri.toString().contains('corsproxy.io'))), headers: any(named: 'headers'))).called(1);
    });

    test('fallback to Jina Reader when first two proxies fail', () async {
      when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((invocation) async {
            final uri = invocation.positionalArguments[0] as Uri;
            final headers = invocation.namedArguments[#headers] as Map<String, String>?;
            
            if (uri.toString().contains('corsproxy.io')) {
              return http.Response('Not Found', 404);
            } else if (uri.toString().contains('allorigins.win')) {
              return http.Response('Not Found', 404);
            } else if (uri.toString().contains('r.jina.ai')) {
              if (headers?['Accept'] == 'text/html') {
                 return http.Response(testHtml, 200);
              }
              return http.Response('Wrong Header', 400);
            } else {
              return http.Response('Not Found', 404);
            }
          });
      
      when(() => mockMetadataService.extract(any())).thenReturn(
        ExtractedMetadata(title: 'Jina Title', description: 'Jina Desc'),
      );
      
      final mockArticle = MockArticle();
      when(() => mockArticle.title).thenReturn('Reader Title');
      when(() => mockArticle.content).thenReturn('Jina Content' * 30);

      when(() => mockReadabilityWrapper.parseHtml(any())).thenAnswer(
        (_) async => mockArticle,
      );

      final result = await service.extractContent(testUrl);

      expect(result?.title, 'Jina Title');
      expect(result?.content, contains('Jina Content'));
      verify(() => mockHttpClient.get(any(that: predicate<Uri>((uri) => uri.toString().contains('r.jina.ai'))), headers: any(named: 'headers'))).called(1);
    });
  });
}
