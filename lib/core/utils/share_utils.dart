import 'package:flutter/material.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/core/utils/pdf_export_service.dart';
import 'package:share_plus/share_plus.dart';

typedef ShareTextAction = Future<void> Function(
  String text, {
  String? subject,
});
typedef ShareFileAction = Future<void> Function(
  List<XFile> files, {
  String? subject,
  String? text,
});

class ShareUtils {
  static Future<void> shareItem(
    BuildContext context,
    MnemataItem item, {
    String? summaryText,
    PdfExportService? pdfExportService,
    ShareTextAction? shareTextAction,
    ShareFileAction? shareFileAction,
  }) async {
    final normalizedSummary = summaryText?.trim();
    final hasSummary = normalizedSummary != null && normalizedSummary.isNotEmpty;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Share Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _executeShare(
                    item,
                    false,
                    shareTextAction: shareTextAction,
                  );
                },
                child: const Text('Share item details'),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _executeShare(
                    item,
                    true,
                    shareTextAction: shareTextAction,
                  );
                },
                child: const Text('Share content'),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: hasSummary
                    ? () async {
                        Navigator.pop(context);
                        await shareSummary(
                          item: item,
                          summaryText: normalizedSummary,
                          shareTextAction: shareTextAction,
                        );
                      }
                    : null,
                child: const Text('Share AI summary'),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await shareAsPdf(
                    item,
                    pdfExportService: pdfExportService,
                    shareFileAction: shareFileAction,
                  );
                },
                child: const Text('Share as PDF'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> shareSummary({
    required MnemataItem item,
    required String? summaryText,
    ShareTextAction? shareTextAction,
  }) async {
    final normalized = (summaryText ?? '').trim();
    if (normalized.isEmpty) {
      return;
    }

    final title = (item.title ?? 'Article').trim();
    final url = item.url?.trim();
    final buffer = StringBuffer()
      ..writeln('*$title*')
      ..writeln('')
      ..writeln('_AI Summary_')
      ..writeln('')
      ..writeln(normalized);
    if (url != null && url.isNotEmpty) {
      buffer
        ..writeln('')
        ..writeln('Source: $url');
    }

    await (shareTextAction ?? _defaultShareTextAction)(
      buffer.toString().trim(),
      subject: item.title,
    );
  }

  static Future<void> shareAsPdf(
    MnemataItem item, {
    PdfExportService? pdfExportService,
    ShareFileAction? shareFileAction,
  }) async {
    final generator = pdfExportService ?? const PdfExportService();
    final pdfFile = await generator.generateItemPdf(item);
    await (shareFileAction ?? _defaultShareFileAction)(
      <XFile>[XFile(pdfFile.path)],
      subject: item.title,
      text: 'PDF exported from Mnemata.',
    );
  }

  static Future<void> _executeShare(
    MnemataItem item,
    bool includeContent, {
    ShareTextAction? shareTextAction,
  }) async {
    final String title = item.title ?? 'Article';
    String host = '';
    
    if (item.url != null) {
      try {
        final uri = Uri.parse(item.url!);
        host = uri.host.replaceFirst('www.', '');
        
        // Archive logic
        if (host.startsWith('archive.') || host == 'archive.today' || host == 'archive.ph' || host == 'archive.is' || host == 'archive.li' || host == 'archive.vn') {
          final segments = uri.pathSegments;
          for (final segment in segments.reversed) {
            if (segment.contains('.')) {
              try {
                final potentialUri = Uri.parse(segment.startsWith('http') ? segment : 'https://$segment');
                if (potentialUri.host.isNotEmpty) {
                  host = potentialUri.host.replaceFirst('www.', '');
                  break;
                }
              } catch (_) {}
            }
          }
        }
      } catch (_) {}
    }

    String shareText = '*$title*';
    if (host.isNotEmpty) shareText += '\n_${host}_';
    if (item.url != null) shareText += '\n\nSource: ${item.url}';
    
    if (includeContent && item.content != null && item.content!.isNotEmpty) {
      // Convert HTML to WhatsApp-compatible markdown
      String plainText = item.content!
          .replaceAll(RegExp(r'<(strong|b)>'), '*')
          .replaceAll(RegExp(r'<\/(strong|b)>'), '*')
          .replaceAll(RegExp(r'<(em|i)>'), '_')
          .replaceAll(RegExp(r'<\/(em|i)>'), '_')
          .replaceAll(RegExp(r'<(br|br \/)>'), '\n')
          .replaceAll(RegExp(r'<\/(p|div|h[1-6])>'), '\n\n')
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll('&nbsp;', ' ')
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&quot;', '"')
          .replaceAll('&#39;', "'")
          .replaceAll(RegExp(r'[ \t]+'), ' ')
          .replaceAll(RegExp(r'\n{3,}'), '\n\n')
          .trim();
      
      // Removed truncation as requested
      shareText += '\n\n---\n\n$plainText';
    }
    
    await (shareTextAction ?? _defaultShareTextAction)(
      shareText,
      subject: item.title,
    );
  }

  static Future<void> _defaultShareTextAction(
    String text, {
    String? subject,
  }) {
    return Share.share(text, subject: subject);
  }

  static Future<void> _defaultShareFileAction(
    List<XFile> files, {
    String? subject,
    String? text,
  }) {
    return Share.shareXFiles(files, subject: subject, text: text);
  }
}
