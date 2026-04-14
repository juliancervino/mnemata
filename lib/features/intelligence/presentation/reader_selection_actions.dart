import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mnemata/features/intelligence/services/annotation_service.dart';

class ReaderSelectionActions {
  ReaderSelectionActions._();

  static Future<void> promptAddAnnotationFromSelection(
    BuildContext context, {
    required AnnotationService service,
    required int itemId,
    required String selectedText,
    required int selectionStart,
    required int selectionEnd,
  }) async {
    final noteController = TextEditingController();
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add note to highlight (optional)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.yellowAccent.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                selectedText,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );

    if (shouldSave != true) {
      return;
    }

    final quote = selectedText.trim();
    if (quote.isEmpty || selectionEnd <= selectionStart) {
      return;
    }

    await service.createAnnotation(
      itemId: itemId,
      quoteText: quote,
      anchorJson: jsonEncode(<String, dynamic>{
        'start': selectionStart,
        'end': selectionEnd,
      }),
      note: noteController.text.trim().isEmpty
          ? null
          : noteController.text.trim(),
    );

    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Annotation saved.')));
  }
}
