import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mnemata/features/ingestion/presentation/web_add_item_sheet.dart';
import 'package:mnemata/features/ingestion/services/web_file_validation.dart';

void main() {
  Future<void> pumpSheet(
    WidgetTester tester, {
    WebIngestFilePicker? pickFile,
    WebIngestUrlSubmitter? onSubmitUrl,
    WebIngestFileSubmitter? onSubmitFile,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WebAddItemSheet(
            pickFile: pickFile,
            onSubmitUrl: onSubmitUrl,
            onSubmitFile: onSubmitFile,
            closeOnSubmit: false,
            enableDragAndDrop: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders unified URL and File tabs', (tester) async {
    await pumpSheet(tester);

    expect(find.widgetWithText(Tab, 'URL'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'File'), findsOneWidget);
    expect(find.text('Add from URL or file'), findsOneWidget);
  });

  testWidgets('submits URL through callback', (tester) async {
    String? submittedUrl;

    await pumpSheet(
      tester,
      onSubmitUrl: (url) async {
        submittedUrl = url;
      },
    );

    await tester.enterText(
      find.byType(TextField).first,
      'https://example.com/article',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Add Item'));
    await tester.pump();

    expect(submittedUrl, 'https://example.com/article');
  });

  testWidgets('picker rejects unsupported file types with explicit copy', (
    tester,
  ) async {
    await pumpSheet(
      tester,
      pickFile: () async => WebIngestFile(
        name: 'notes.txt',
        bytes: Uint8List.fromList(<int>[1, 2, 3]),
      ),
    );

    await tester.tap(find.text('File'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Choose File'));
    await tester.pumpAndSettle();

    expect(
      find.text(WebFileValidation.unsupportedFileTypeMessage),
      findsOneWidget,
    );
  });

  testWidgets('picker rejects oversized files with explicit copy', (tester) async {
    await pumpSheet(
      tester,
      pickFile: () async => WebIngestFile(
        name: 'large.pdf',
        bytes: Uint8List.fromList(<int>[1]),
        sizeInBytes: WebFileValidation.maxFileSizeBytes + 1,
      ),
    );

    await tester.tap(find.text('File'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Choose File'));
    await tester.pumpAndSettle();

    expect(find.text(WebFileValidation.oversizeFileMessage), findsOneWidget);
  });

  testWidgets('supported file proceeds to submission callback', (tester) async {
    String? submittedFileName;

    await pumpSheet(
      tester,
      pickFile: () async => WebIngestFile(
        name: 'paper.pdf',
        bytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
      ),
      onSubmitFile: (file) async {
        submittedFileName = file.name;
      },
    );

    await tester.tap(find.text('File'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Choose File'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Add File'));
    await tester.pumpAndSettle();

    expect(submittedFileName, 'paper.pdf');
  });
}