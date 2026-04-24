import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mnemata/features/ingestion/services/pdf_extraction_service.dart';

void main() {
  late PdfExtractionService pdfExtractionService;

  setUp(() {
    pdfExtractionService = PdfExtractionService();
  });

  group('PdfExtractionService', () {
    test('returns null for empty bytes', () async {
      final result = await pdfExtractionService.extractText(Uint8List(0));
      expect(result, isNull);
    });

    test('handles invalid PDF bytes gracefully', () async {
      // Just some random bytes that are not a valid PDF
      final result = await pdfExtractionService.extractText(Uint8List.fromList([1, 2, 3, 4, 5]));
      expect(result, isNull);
    });
  });
}
