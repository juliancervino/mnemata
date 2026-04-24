import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfExtractionService {
  Future<String?> extractText(Uint8List bytes) async {
    try {
      if (bytes.isEmpty) return null;

      final document = PdfDocument(inputBytes: bytes);
      
      final extractor = PdfTextExtractor(document);
      final text = extractor.extractText();
      
      document.dispose();
      return text;
    } catch (e) {
      debugPrint('PDF Extraction error: $e');
      return null;
    }
  }
}
