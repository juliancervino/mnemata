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
    ShareOption initialOption = ShareOption.item,
  }) async {
    bool includeContent = false;
    final normalizedSummary = summaryText?.trim();
    final hasSummary = normalizedSummary != null && normalizedSummary.isNotEmpty;
    ShareOption? selectedAction = initialOption;
    if (selectedAction == ShareOption.summary && !hasSummary) {
      selectedAction = ShareOption.item;
    }

    final result = await showDialog<ShareOption>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Share Item'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<ShareOption>(
                    value: ShareOption.item,
                    groupValue: selectedAction,
                    title: const Text('Share item details'),
                    onChanged: (value) {
                      setState(() {
                        selectedAction = value;
                      });
                    },
                  ),
                  RadioListTile<ShareOption>(
                    value: ShareOption.summary,
                    groupValue: selectedAction,
                    title: const Text('Share AI summary'),
                    onChanged: hasSummary
                        ? (value) {
                            setState(() {
                              selectedAction = value;
                            });
                          }
                        : null,
                  ),
                  RadioListTile<ShareOption>(
                    value: ShareOption.pdf,
                    groupValue: selectedAction,
                    title: const Text('Share as PDF'),
                    onChanged: (value) {
                      setState(() {
                        selectedAction = value;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Include downloaded content'),
                    value: includeContent,
                    onChanged: (value) {
                      setState(() {
                        includeContent = value ?? false;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: selectedAction == null
                      ? null
                      : () => Navigator.pop(context, selectedAction),
                  child: const Text('SHARE'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) {
      return;
    }

    switch (result) {
      case ShareOption.summary:
        await shareSummary(
          item: item,
          summaryText: normalizedSummary ?? '',
          shareTextAction: shareTextAction,
        );
        return;
      case ShareOption.pdf:
        await shareAsPdf(
          item,
          summaryText: normalizedSummary,
          pdfExportService: pdfExportService,
          shareFileAction: shareFileAction,
        );
        return;
      case ShareOption.item:
        await _executeShare(
          item,
          includeContent,
          shareTextAction: shareTextAction,
        );
        return;
    }
  }

  static Future<void> shareSummary({
    required MnemataItem item,
    required String summaryText,
    ShareTextAction? shareTextAction,
  }) async {
    final normalized = summaryText.trim();
    if (normalized.isEmpty) {
      return;
    }

    final title = (item.title ?? 'Article').trim();
    final url = item.url?.trim();
    final buffer = StringBuffer()
      ..writeln('*$title*')
      ..writeln('')
      ..writeln('AI summary')
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
    String? summaryText,
    PdfExportService? pdfExportService,
    ShareFileAction? shareFileAction,
  }) async {
    final generator = pdfExportService ?? const PdfExportService();
    final pdfFile = await generator.generateItemPdf(
      item,
      summaryText: summaryText?.trim(),
    );
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

enum ShareOption { item, summary, pdf }
