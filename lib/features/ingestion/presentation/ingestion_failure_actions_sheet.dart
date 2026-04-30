import 'package:flutter/material.dart';
import 'package:mnemata/core/theme/app_theme.dart';

enum IngestionFailureAction {
  retryExtraction,
  manualIngest,
  openOriginal,
  reportIssue,
  dismiss,
}

class IngestionFailureActionsSheet extends StatelessWidget {
  const IngestionFailureActionsSheet({
    super.key,
    required this.sourceLabel,
    required this.canOpenOriginal,
  });

  final String sourceLabel;
  final bool canOpenOriginal;

  static Future<IngestionFailureAction> show(
    BuildContext context, {
    required String sourceLabel,
    bool canOpenOriginal = true,
  }) async {
    final cs = Theme.of(context).colorScheme;
    final result = await showModalBottomSheet<IngestionFailureAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(MnemataRadii.xl),
        ),
      ),
      builder: (context) => IngestionFailureActionsSheet(
        sourceLabel: sourceLabel,
        canOpenOriginal: canOpenOriginal,
      ),
    );

    return result ?? IngestionFailureAction.dismiss;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(MnemataRadii.full),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'INGESTION ISSUE',
              style: theme.textTheme.tracked(cs.secondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Could not load readable content.',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              sourceLabel,
              style: theme.textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => Navigator.pop(
                context,
                IngestionFailureAction.retryExtraction,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Extraction'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(
                context,
                IngestionFailureAction.manualIngest,
              ),
              icon: const Icon(Icons.paste),
              label: const Text('Manual Ingest (Paste HTML/Text)'),
            ),
            const SizedBox(height: 10),
            if (canOpenOriginal) ...[
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(
                  context,
                  IngestionFailureAction.openOriginal,
                ),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open Original'),
              ),
              const SizedBox(height: 10),
            ],
            TextButton.icon(
              onPressed: () => Navigator.pop(
                context,
                IngestionFailureAction.reportIssue,
              ),
              icon: const Icon(Icons.bug_report_outlined),
              label: const Text('Report Issue'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(
                context,
                IngestionFailureAction.dismiss,
              ),
              child: const Text('Keep Current Item'),
            ),
          ],
        ),
      ),
    );
  }
}