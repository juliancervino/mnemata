import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mnemata/features/ingestion/presentation/manual_ingest_dialog.dart';

void main() {
  group('ManualIngestDialog', () {
    testWidgets('Verify dialog shows required widgets', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ManualIngestDialog(),
          ),
        ),
      );

      expect(find.text('Manual Ingest'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Process Content'), findsOneWidget);
    });

    testWidgets('Verify content submission returns text', (WidgetTester tester) async {
      String? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showDialog<String>(
                    context: context,
                    builder: (_) => const ManualIngestDialog(),
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      const testContent = 'Pasted HTML content';
      await tester.enterText(find.byType(TextField), testContent);
      await tester.tap(find.text('Process Content'));
      await tester.pumpAndSettle();

      expect(result, testContent);
    });
  });
}
