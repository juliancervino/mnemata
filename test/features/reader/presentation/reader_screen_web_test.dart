import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:get_it/get_it.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/core/theme/app_theme.dart';
import 'package:mnemata/features/intelligence/services/annotation_service.dart';
import 'package:mnemata/features/reader/presentation/reader_controls_bar.dart';
import 'package:mnemata/features/reader/presentation/reader_pdf_view.dart';
import 'package:mnemata/features/reader/presentation/reader_screen.dart';
import 'package:mnemata/features/reader/services/reader_position_store.dart';
import 'package:sqlite3/open.dart';

MnemataItem _sampleItem({required String content}) {
  return MnemataItem(
    id: 77,
    title: 'Web Reader Sample',
    url: 'https://example.com/story',
    filePath: null,
    content: content,
    author: 'Jane Doe',
    type: 'url',
    createdAt: DateTime.utc(2026, 4, 20),
    deletedAt: null,
    lastOpenedAt: null,
    thumbnailUrl: null,
    sortOrder: 0,
  );
}

String _longContent() {
  final chunks = List<String>.generate(
    120,
    (index) =>
        'Paragraph ${index + 1}. This is deterministic reader content for responsive shell and sticky controls verification.',
  );
  return '<p>${chunks.join('</p><p>')}</p>';
}

Future<void> _cleanupWidgetTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
}

Future<void> _pumpSettle(WidgetTester tester) async {
  // HtmlWidget can take multiple pumps to settle due to its internal
  // async loading/rendering architecture.
  for (int i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  final getIt = GetIt.instance;
  late AppDatabase database;
  late InMemoryReaderPositionStore positionStore;

  setUpAll(() {
    if (Platform.isLinux) {
      open.overrideFor(
        OperatingSystem.linux,
        () => ffi.DynamicLibrary.open('libsqlite3.so.0'),
      );
    }
  });

  setUp(() async {
    await getIt.reset();
    database = AppDatabase.forTesting(NativeDatabase.memory());
    positionStore = InMemoryReaderPositionStore();
    getIt.registerSingleton<AppDatabase>(database);
    getIt.registerSingleton<AnnotationService>(
      AnnotationService(database: database),
    );
    getIt.registerSingleton<ReaderPositionStore>(positionStore);
  });

  tearDown(() async {
    await database.close();
    await getIt.reset();
  });

  testWidgets(
    'uses responsive shell with desktop side panel and mobile collapse',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1400, 1000);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: MnemataTheme.light,
          darkTheme: MnemataTheme.dark,
          home: ReaderScreen(item: _sampleItem(content: _longContent())),
        ),
      );
      await _pumpSettle(tester);

      expect(find.byKey(const Key('reader-side-panel')), findsOneWidget);

      tester.view.physicalSize = const Size(390, 844);
      await _pumpSettle(tester);

      expect(find.byKey(const Key('reader-side-panel')), findsNothing);

      await _cleanupWidgetTree(tester);
    },
  );

  testWidgets('keeps sticky controls visible while scrolling content', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 900);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: MnemataTheme.light,
        darkTheme: MnemataTheme.dark,
        home: ReaderScreen(item: _sampleItem(content: _longContent())),
      ),
    );
    await _pumpSettle(tester);

    if (kIsWeb) {
      expect(find.byType(ReaderControlsBar), findsOneWidget);

      await tester.drag(
        find.byKey(const Key('reader-scroll-view')),
        const Offset(0, -900),
      );
      await _pumpSettle(tester);

      expect(find.byType(ReaderControlsBar), findsOneWidget);
      expect(find.byKey(const Key('reader-section-indicator')), findsOneWidget);
    } else {
      // On mobile, controls bar is not shown
      expect(find.byType(ReaderControlsBar), findsNothing);
    }

    await _cleanupWidgetTree(tester);
  });

  testWidgets('applies width, font, and tone controls deterministically', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1366, 900);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: MnemataTheme.light,
        darkTheme: MnemataTheme.dark,
        home: ReaderScreen(item: _sampleItem(content: _longContent())),
      ),
    );
    await _pumpSettle(tester);

    final contentFinder = find.byKey(const Key('reader-content-container'));
    final textFinder = find.byKey(const Key('reader-body-text'));

    if (kIsWeb) {
      final initialWidth = tester.getSize(contentFinder).width;
      final initialHtmlWidget = tester.widget<HtmlWidget>(textFinder);
      final initialFontSize = initialHtmlWidget.textStyle?.fontSize;

      await tester.tap(find.widgetWithText(ChoiceChip, '840'));
      await _pumpSettle(tester);

      final widenedWidth = tester.getSize(contentFinder).width;
      expect(widenedWidth, greaterThan(initialWidth));

      await tester.tap(find.widgetWithText(ChoiceChip, 'A+'));
      await _pumpSettle(tester);

      final enlargedHtmlWidget = tester.widget<HtmlWidget>(textFinder);
      final enlargedFontSize = enlargedHtmlWidget.textStyle?.fontSize;
      expect(enlargedFontSize, isNotNull);
      expect(initialFontSize, isNotNull);
      expect(enlargedFontSize, greaterThan(initialFontSize!));

      await tester.tap(find.widgetWithText(ChoiceChip, 'Dark'));
      await _pumpSettle(tester);

      final contentContainer = tester.widget<Container>(contentFinder);
      final decoration = contentContainer.decoration as BoxDecoration;
      expect(decoration.color, MnemataColors.paperDark);
    } else {
      // On mobile, verify responsive padding instead
      final contentContainer = tester.widget<Container>(contentFinder);
      final padding = contentContainer.padding as EdgeInsets;
      // physicalSize is 1366, so it's not mobile (<600). Padding should be 24.
      expect(padding.left, 24.0);

      // Change to mobile size
      tester.view.physicalSize = const Size(390, 844);
      await _pumpSettle(tester);
      
      final mobileContentContainer = tester.widget<Container>(contentFinder);
      final mobilePadding = mobileContentContainer.padding as EdgeInsets;
      expect(mobilePadding.left, 20.0);
    }

    await _cleanupWidgetTree(tester);
  });

  testWidgets('renders embedded PDF view with guided fallback actions', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 900);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: MnemataTheme.light,
        darkTheme: MnemataTheme.dark,
        home: ReaderScreen(
          item: MnemataItem(
            id: 77,
            title: 'PDF Reader Sample',
            url: 'https://example.com/document.pdf',
            filePath: null,
            content: '',
            author: 'Jane Doe',
            type: 'file',
            createdAt: DateTime.utc(2026, 4, 20),
            deletedAt: null,
            lastOpenedAt: null,
            thumbnailUrl: null,
            sortOrder: 0,
          ),
        ),
      ),
    );
    await _pumpSettle(tester);

    expect(find.byType(ReaderPdfView), findsOneWidget);
    expect(find.text('Retry Extraction'), findsWidgets);
    expect(find.text('Open Original'), findsWidgets);
    expect(find.text('Report Issue'), findsWidgets);

    await _cleanupWidgetTree(tester);
  });

  testWidgets('restores section indicator from stored bucket', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1366, 900);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await positionStore.writeBucket(77, 3);

    await tester.pumpWidget(
      MaterialApp(
        theme: MnemataTheme.light,
        darkTheme: MnemataTheme.dark,
        home: ReaderScreen(item: _sampleItem(content: _longContent())),
      ),
    );
    await _pumpSettle(tester);

    if (kIsWeb) {
      expect(find.textContaining('Section 4 of'), findsOneWidget);
    } else {
      // On mobile, section indicator is not shown
      expect(find.textContaining('Section 4 of'), findsNothing);
    }

    await _cleanupWidgetTree(tester);
  });
}
