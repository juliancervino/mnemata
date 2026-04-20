import 'package:flutter/material.dart';
import 'package:mnemata/core/theme/app_theme.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class ReaderPdfView extends StatefulWidget {
  const ReaderPdfView({
    super.key,
    required this.sourceUri,
    required this.onOpenOriginal,
    required this.onRetryExtraction,
    required this.onReportIssue,
  });

  final Uri? sourceUri;
  final VoidCallback onOpenOriginal;
  final VoidCallback onRetryExtraction;
  final VoidCallback onReportIssue;

  @override
  State<ReaderPdfView> createState() => _ReaderPdfViewState();
}

class _ReaderPdfViewState extends State<ReaderPdfView> {
  String? _errorMessage;
  bool _loaded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (widget.sourceUri == null) {
      return _PdfErrorPanel(
        message:
            'The PDF source is unavailable for embedded viewing on this device.',
        onRetryExtraction: widget.onRetryExtraction,
        onOpenOriginal: widget.onOpenOriginal,
        onReportIssue: widget.onReportIssue,
      );
    }

    return Container(
      key: const Key('reader-pdf-view'),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(MnemataRadii.lg),
        border: Border.all(color: cs.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          SfPdfViewer.network(
            widget.sourceUri.toString(),
            onDocumentLoaded: (_) {
              if (!mounted) {
                return;
              }
              setState(() {
                _loaded = true;
                _errorMessage = null;
              });
            },
            onDocumentLoadFailed: (details) {
              if (!mounted) {
                return;
              }
              setState(() {
                _errorMessage = details.error;
              });
            },
          ),
          if (!_loaded && _errorMessage == null)
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                key: const Key('reader-pdf-progress'),
                width: 280,
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(MnemataRadii.md),
                  border: Border.all(color: cs.outline),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Loading PDF preview...',
                      style: theme.textTheme.mono(
                        size: 10,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const LinearProgressIndicator(),
                  ],
                ),
              ),
            ),
          if (_errorMessage != null)
            _PdfErrorPanel(
              message: _errorMessage!,
              onRetryExtraction: widget.onRetryExtraction,
              onOpenOriginal: widget.onOpenOriginal,
              onReportIssue: widget.onReportIssue,
            ),
        ],
      ),
    );
  }
}

class _PdfErrorPanel extends StatelessWidget {
  const _PdfErrorPanel({
    required this.message,
    required this.onRetryExtraction,
    required this.onOpenOriginal,
    required this.onReportIssue,
  });

  final String message;
  final VoidCallback onRetryExtraction;
  final VoidCallback onOpenOriginal;
  final VoidCallback onReportIssue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      key: const Key('reader-pdf-error-panel'),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: cs.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('PDF preview unavailable', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(message, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton(
                onPressed: onRetryExtraction,
                child: const Text('Retry Extraction'),
              ),
              OutlinedButton(
                onPressed: onOpenOriginal,
                child: const Text('Open Original'),
              ),
              TextButton(
                onPressed: onReportIssue,
                child: const Text('Report Issue'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
