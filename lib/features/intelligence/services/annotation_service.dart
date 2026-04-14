import 'dart:convert';

import 'package:mnemata/core/database/app_database.dart';

class AnnotationService {
  AnnotationService({required AppDatabase database}) : _database = database;

  final AppDatabase _database;

  Future<int> createAnnotation({
    required int itemId,
    required String quoteText,
    required String anchorJson,
    String? note,
  }) async {
    _validateAnchor(anchorJson);
    return _database.insertAnnotation(
      itemId: itemId,
      quoteText: quoteText.trim(),
      anchorJson: anchorJson,
      note: note?.trim().isEmpty == true ? null : note?.trim(),
    );
  }

  Future<List<AnnotationRecord>> listForItem(int itemId) {
    return _database.listAnnotationsForItem(itemId);
  }

  Future<void> updateAnnotation({
    required int annotationId,
    required String quoteText,
    required String anchorJson,
    String? note,
  }) async {
    _validateAnchor(anchorJson);
    await _database.updateAnnotation(
      annotationId: annotationId,
      quoteText: quoteText.trim(),
      anchorJson: anchorJson,
      note: note?.trim().isEmpty == true ? null : note?.trim(),
    );
  }

  Future<void> deleteAnnotation(int annotationId) {
    return _database.deleteAnnotation(annotationId);
  }

  void _validateAnchor(String anchorJson) {
    final decoded = jsonDecode(anchorJson);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Anchor payload must be a JSON object.');
    }
    if (!decoded.containsKey('start') || !decoded.containsKey('end')) {
      throw const FormatException('Anchor JSON must include start and end.');
    }
  }
}
