import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Offset, Rect;

import 'package:flutter/services.dart' show rootBundle;
import 'package:mnemata/core/database/app_database.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfExportService {
  const PdfExportService({this.temporaryDirectoryProvider});

  final Future<Directory> Function()? temporaryDirectoryProvider;

  Future<File> generateItemPdf(MnemataItem item) async {
    final document = PdfDocument();
    final firstPage = document.pages.add();
    final pageSize = firstPage.getClientSize();
    const margin = 32.0;
    const headerHeight = 46.0;
    const bodyTopSpacing = 12.0;
    const footerHeight = 30.0;

    final headerFont = PdfStandardFont(
      PdfFontFamily.helvetica,
      13,
      style: PdfFontStyle.bold,
    );
    final bodyFont = PdfStandardFont(PdfFontFamily.helvetica, 11);
    final footerFont = PdfStandardFont(
      PdfFontFamily.helvetica,
      12,
      style: PdfFontStyle.bold,
    );
    final lightGrayPen = PdfPen(PdfColor(210, 210, 210), width: 0.7);
    final title = item.title?.trim().isNotEmpty == true
        ? item.title!.trim()
        : 'Untitled item';

    final logoBytes = await _loadLogoBytes();
    final logo = logoBytes == null ? null : PdfBitmap(logoBytes);

    final headerTemplateHeight = margin + headerHeight + bodyTopSpacing;
    final footerTemplateHeight = margin + footerHeight;

    document.template.top = _buildHeaderTemplate(
      width: pageSize.width,
      height: headerTemplateHeight,
      title: title,
      headerFont: headerFont,
      separatorPen: lightGrayPen,
      margin: margin,
      headerHeight: headerHeight,
      logo: logo,
    );
    document.template.bottom = _buildFooterTemplate(
      width: pageSize.width,
      height: footerTemplateHeight,
      footerFont: footerFont,
      separatorPen: lightGrayPen,
      margin: margin,
    );

    final bodyBuffer = StringBuffer();
    final source = item.url?.trim();
    if (source != null && source.isNotEmpty) {
      bodyBuffer
        ..writeln('Source: $source')
        ..writeln('');
    }

    final content = _toPlainText(item.content);
    if (content.isNotEmpty) {
      bodyBuffer
        ..writeln('Content')
        ..writeln(content);
    } else {
      bodyBuffer.writeln('No extracted content available.');
    }

    final layouter = PdfTextElement(
      text: bodyBuffer.toString().trim(),
      font: bodyFont,
      format: PdfStringFormat(lineSpacing: 4),
    );

    layouter.draw(
      page: firstPage,
      bounds: Rect.fromLTWH(
        margin,
        0,
        pageSize.width - (margin * 2),
        pageSize.height,
      ),
      format: PdfLayoutFormat(layoutType: PdfLayoutType.paginate),
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

  PdfPageTemplateElement _buildHeaderTemplate({
    required double width,
    required double height,
    required String title,
    required PdfFont headerFont,
    required PdfPen separatorPen,
    required double margin,
    required double headerHeight,
    required PdfBitmap? logo,
  }) {
    final template =
        PdfPageTemplateElement(Rect.fromLTWH(0, 0, width, height));
    final logoSize = 22.0;
    final maxTitleWidth =
        width - (margin * 2) - (logo != null ? (logoSize + 12) : 0);

    template.graphics.drawString(
      title,
      headerFont,
      bounds: Rect.fromLTWH(margin, margin, maxTitleWidth, headerHeight),
      format: PdfStringFormat(lineAlignment: PdfVerticalAlignment.middle),
    );

    if (logo != null) {
      template.graphics.drawImage(
        logo,
        Rect.fromLTWH(
          width - margin - logoSize,
          margin + ((headerHeight - logoSize) / 2),
          logoSize,
          logoSize,
        ),
      );
    }

    template.graphics.drawLine(
      separatorPen,
      Offset(margin, margin + headerHeight),
      Offset(width - margin, margin + headerHeight),
    );

    return template;
  }

  PdfPageTemplateElement _buildFooterTemplate({
    required double width,
    required double height,
    required PdfFont footerFont,
    required PdfPen separatorPen,
    required double margin,
  }) {
    final template =
        PdfPageTemplateElement(Rect.fromLTWH(0, 0, width, height));
    final footerTop = margin;

    template.graphics.drawLine(
      separatorPen,
      Offset(margin, footerTop),
      Offset(width - margin, footerTop),
    );

    final pageNumber = PdfPageNumberField(
      font: footerFont,
      brush: PdfSolidBrush(PdfColor(70, 70, 70)),
    );
    final pageCount = PdfPageCountField(
      font: footerFont,
      brush: PdfSolidBrush(PdfColor(70, 70, 70)),
    );
    final compositeField = PdfCompositeField(
      font: footerFont,
      brush: PdfSolidBrush(PdfColor(70, 70, 70)),
      text: '{0}/{1}',
      fields: <PdfAutomaticField>[pageNumber, pageCount],
    );
    compositeField.draw(
      template.graphics,
      Offset(width - margin - 48, footerTop + 8),
    );

    return template;
  }

  Future<Uint8List?> _loadLogoBytes() async {
    try {
      final data = await rootBundle.load('assets/mnemata.jpg');
      return data.buffer.asUint8List();
    } catch (_) {
      return null;
    }
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
