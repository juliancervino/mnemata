import 'package:flutter/material.dart';
import 'package:mnemata/core/theme/app_theme.dart';

class ManualIngestDialog extends StatefulWidget {
  const ManualIngestDialog({super.key});

  @override
  State<ManualIngestDialog> createState() => _ManualIngestDialogState();
}

class _ManualIngestDialogState extends State<ManualIngestDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text('Manual Ingest', style: theme.textTheme.headlineSmall),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paste the HTML or text content of the page below.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 12,
              decoration: const InputDecoration(
                hintText: '<html>...</html> or plain text',
                alignLabelWithHint: true,
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'JetBrains Mono',
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final content = _controller.text.trim();
            if (content.isNotEmpty) {
              Navigator.pop(context, content);
            }
          },
          child: const Text('Process Content'),
        ),
      ],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MnemataRadii.lg),
      ),
    );
  }
}
