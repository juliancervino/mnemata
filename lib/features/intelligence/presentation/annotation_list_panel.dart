import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/features/intelligence/services/annotation_service.dart';

class AnnotationListPanel extends StatelessWidget {
  const AnnotationListPanel({
    super.key,
    required this.itemId,
    required this.service,
    this.onNavigate,
    this.onChanged,
  });

  final int itemId;
  final AnnotationService service;
  final ValueChanged<AnnotationRecord>? onNavigate;
  final VoidCallback? onChanged;

  @override
    Widget build(BuildContext context) {
      return FutureBuilder<List<AnnotationRecord>>(
        future: service.listForItem(itemId),
        builder: (context, snapshot) {
          final records = snapshot.data ?? const <AnnotationRecord>[];
          if (records.isEmpty) {
            return const ListTile(
              title: Text('No annotations yet'),
              subtitle: Text('Use Add highlight/note to save one.'),
            );
          }

          // Sort records by position in text
          final sortedRecords = List<AnnotationRecord>.from(records);
          sortedRecords.sort((a, b) {
            final posA = _getStartIndex(a.anchorJson);
            final posB = _getStartIndex(b.anchorJson);
            return posA.compareTo(posB);
          });

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: sortedRecords
                .map(
                  (record) => ListTile(
                    dense: true,
                    title: Text(
                      record.quoteText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: record.note == null || record.note!.isEmpty
                        ? const Text('Highlight only')
                        : Text(record.note!),
                    onTap: () => onNavigate?.call(record),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await service.deleteAnnotation(record.id);
                        onChanged?.call();
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Annotation deleted.')),
                        );
                        (context as Element).markNeedsBuild();
                      },
                    ),
                  ),
                )
                .toList(growable: false),
          );
        },
      );
    }

    int _getStartIndex(String anchorJson) {
      try {
        final decoded = jsonDecode(anchorJson);
        if (decoded is Map<String, dynamic>) {
          return (decoded['start'] as num?)?.toInt() ?? 0;
        }
      } catch (_) {}
      return 0;
    }
}
