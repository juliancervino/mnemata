import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mnemata/features/intelligence/services/annotation_service.dart';

class ReaderSelectionActions {
  ReaderSelectionActions._();

  static Future<void> promptAddAnnotation(
    BuildContext context, {
    required AnnotationService service,
    required int itemId,
  }) async {
    final quoteController = TextEditingController();
    final noteController = TextEditingController();
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add highlight or note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: quoteController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Quoted text',
                hintText: 'Paste selected text from the article',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
              ),
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

    final quote = quoteController.text.trim();
    if (quote.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quoted text is required.')),
        );
      }
      return;
    }

    await service.createAnnotation(
      itemId: itemId,
      quoteText: quote,
      anchorJson: jsonEncode(<String, dynamic>{
        'start': 0,
        'end': quote.length,
      }),
      note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
    );

    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Annotation saved.')),
    );
  }
}
