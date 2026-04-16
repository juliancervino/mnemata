import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/core/utils/pdf_export_service.dart';
import 'package:mnemata/core/utils/share_utils.dart';
import 'package:share_plus/share_plus.dart';

class _FakePdfExportService extends PdfExportService {
  _FakePdfExportService(this.generatedPath);

  final String generatedPath;
  int invocationCount = 0;

  @override
  Future<File> generateItemPdf(MnemataItem item) async {
    invocationCount += 1;
    final file = File(generatedPath);
    await file.parent.create(recursive: true);
    await file.writeAsString('pdf-bytes');
    return file;
  }
}

MnemataItem _sampleItem() {
  return MnemataItem(
    id: 9,
    title: 'PDF Candidate',
    url: 'https://example.com/pdf',
    filePath: null,
    content: '<p>Body</p>',
    author: null,
    type: 'url',
    createdAt: DateTime.utc(2026, 4, 3),
    deletedAt: null,
    lastOpenedAt: null,
    thumbnailUrl: null,
    sortOrder: 0,
  );
}

void main() {
  test('shareAsPdf generates attachment and forwards it to share callback', () async {
    final item = _sampleItem();
    final filePath = '${Directory.systemTemp.path}/mnemata_test_share.pdf';
    final fakePdf = _FakePdfExportService(filePath);
    final sharedFiles = <List<XFile>>[];

    await ShareUtils.shareAsPdf(
      item,
      pdfExportService: fakePdf,
      shareFileAction: (files, {subject, text}) async {
        sharedFiles.add(files);
      },
    );

    expect(fakePdf.invocationCount, equals(1));
    expect(sharedFiles, hasLength(1));
    expect(sharedFiles.first.single.path, equals(filePath));
  });
}
