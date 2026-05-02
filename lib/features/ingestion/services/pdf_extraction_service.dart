import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfExtractionService {
  Future<String?> extractText(Uint8List bytes) async {
    if (kIsWeb) {
      debugPrint('PdfExtractionService: extractText received bytes=${bytes.lengthInBytes}');
    }
    if (bytes.isEmpty) return null;
    PdfDocument? document;
    try {
      document = PdfDocument(inputBytes: bytes);
      final extractor = PdfTextExtractor(document);
      final text = extractor.extractText();
      return text;
    } catch (e, stack) {
      if (kIsWeb) {
        debugPrint('PdfExtractionService: web extraction failure: $e');
        debugPrint('PdfExtractionService: stack trace: $stack');
      } else {
        debugPrint('PDF Extraction error: $e');
      }
      return null;
    } finally {
      document?.dispose();
    }
  }
}
