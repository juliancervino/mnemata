import 'dart:io';
import 'dart:ui' show Rect;

import 'package:mnemata/core/database/app_database.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfExportService {
  const PdfExportService({this.temporaryDirectoryProvider});

  final Future<Directory> Function()? temporaryDirectoryProvider;

  Future<File> generateItemPdf(
    MnemataItem item, {
    String? summaryText,
  }) async {
    final document = PdfDocument();
    final page = document.pages.add();
    final bounds = page.getClientSize();

    final content = _buildPdfContent(item, summaryText: summaryText);
    page.graphics.drawString(
      content,
      PdfStandardFont(PdfFontFamily.helvetica, 12),
      bounds: Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      format: PdfStringFormat(lineSpacing: 4),
    );

    final bytes = await document.save();
    document.dispose();

    final directory =
        await (temporaryDirectoryProvider?.call() ?? getTemporaryDirectory());
    final safeTitle = _sanitizeFileName(item.title ?? 'item');
    final filePath = p.join(directory.path, 'mnemata_${item.id}_$safeTitle.pdf');
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  String _buildPdfContent(MnemataItem item, {String? summaryText}) {
    final buffer = StringBuffer();
    final title = item.title?.trim().isNotEmpty == true
        ? item.title!.trim()
        : 'Untitled item';

    buffer.writeln(title);
    buffer.writeln('');

    final url = item.url?.trim();
    if (url != null && url.isNotEmpty) {
      buffer.writeln('Source: $url');
      buffer.writeln('');
    }

    if (summaryText != null && summaryText.trim().isNotEmpty) {
      buffer.writeln('AI summary');
      buffer.writeln(summaryText.trim());
      buffer.writeln('');
    }

    final content = _toPlainText(item.content);
    if (content.isNotEmpty) {
      buffer.writeln('Content');
      buffer.writeln(content);
    }

    return buffer.toString().trim();
  }

  String _toPlainText(String? rawContent) {
    if (rawContent == null || rawContent.trim().isEmpty) {
      return '';
    }

    return rawContent
        .replaceAll(RegExp(r'<(br|br \/)>', caseSensitive: false), '\n')
        .replaceAll(
          RegExp(r'<\/(p|div|h[1-6])>', caseSensitive: false),
          '\n\n',
        )
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _sanitizeFileName(String value) {
    final cleaned = value
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    if (cleaned.isEmpty) {
      return 'item';
    }
    return cleaned;
  }
}
