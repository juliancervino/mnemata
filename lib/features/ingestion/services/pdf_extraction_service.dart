import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfExtractionService {
  Future<String?> extractText(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      
      final extractor = PdfTextExtractor(document);
      final text = extractor.extractText();
      
      document.dispose();
      return text;
    } catch (e) {
      debugPrint('PDF Extraction error for $filePath: $e');
      return null;
    }
  }
}
