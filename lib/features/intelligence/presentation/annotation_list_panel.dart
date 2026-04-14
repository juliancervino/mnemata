import 'package:flutter/material.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/features/intelligence/services/annotation_service.dart';

class AnnotationListPanel extends StatelessWidget {
  const AnnotationListPanel({
    super.key,
    required this.itemId,
    required this.service,
    this.onNavigate,
  });

  final int itemId;
  final AnnotationService service;
  final ValueChanged<AnnotationRecord>? onNavigate;

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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: records
              .map(
                (record) => ListTile(
                  dense: true,
                  title: Text(record.quoteText, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: record.note == null || record.note!.isEmpty
                      ? const Text('Highlight only')
                      : Text(record.note!),
                  onTap: () => onNavigate?.call(record),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await service.deleteAnnotation(record.id);
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
}
