import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mnemata/features/ingestion/services/extraction_service.dart';
import 'package:readability/readability.dart' as readability;
import 'package:readability/article.dart' as readability;

class MockReadabilityWrapper extends Mock implements ReadabilityWrapper {}

// Need to mock the Article class if it's not a simple data class
class MockArticle extends Mock implements readability.Article {}

void main() {
  late ExtractionService service;
  late MockReadabilityWrapper mockWrapper;

  setUp(() {
    mockWrapper = MockReadabilityWrapper();
    service = ExtractionService(mockWrapper);
  });

  test('extractContent returns title and content on success', () async {
    const url = 'https://example.com/article';
    final mockArticle = MockArticle();
    when(() => mockArticle.title).thenReturn('Test Title');
    when(() => mockArticle.content).thenReturn('Test Content');
    
    when(() => mockWrapper.parse(url)).thenAnswer((_) async => mockArticle);

    final result = await service.extractContent(url);

    expect(result, isNotNull);
    expect(result!.title, 'Test Title');
    expect(result.content, 'Test Content');
  });

  test('extractContent returns null on failure', () async {
    const url = 'https://example.com/article';
    when(() => mockWrapper.parse(url)).thenAnswer((_) async => null);

    final result = await service.extractContent(url);

    expect(result, isNull);
  });
}
