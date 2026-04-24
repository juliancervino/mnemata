import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mnemata/features/ingestion/services/extraction_service.dart';

class MockReadabilityWrapper extends Mock implements ReadabilityWrapper {}

void main() {
  late ExtractionService extractionService;
  late MockReadabilityWrapper mockReadabilityWrapper;

  setUp(() {
    mockReadabilityWrapper = MockReadabilityWrapper();
    extractionService = ExtractionService(mockReadabilityWrapper);
  });

  group('ExtractionService', () {
    test('TODO: Implement extraction tests', () {
      // Basic scaffold test
      expect(extractionService, isNotNull);
    });

    test('TODO: Verify web fallback proxy logic', () {
      // This will be implemented in a later task
    });
  });
}
