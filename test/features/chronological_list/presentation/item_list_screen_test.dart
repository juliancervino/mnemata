import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/features/chronological_list/presentation/item_list_screen.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'dart:ffi';
import 'dart:io';
import 'package:sqlite3/open.dart';

void main() {
  late AppDatabase database;
  final getIt = GetIt.instance;

  setUpAll(() {
    if (Platform.isLinux) {
      open.overrideFor(OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
    }
  });

  setUp(() async {
    await getIt.reset();
    database = AppDatabase.forTesting(NativeDatabase.memory());
    getIt.registerSingleton<AppDatabase>(database);
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets('ItemListScreen displays empty state when no items', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ItemListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('No items saved yet.'), findsOneWidget);
    
    // Clear any pending timers
    await tester.pumpWidget(Container());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('ItemListScreen displays list of items and handles search', (WidgetTester tester) async {
    // Insert some test data
    final now = DateTime.now();
    await database.insertItem(MnemataItemsCompanion.insert(
      title: const Value('Apple'),
      url: const Value('https://apple.com'),
      type: 'url',
      createdAt: now,
    ));
    await database.insertItem(MnemataItemsCompanion.insert(
      title: const Value('Banana'),
      url: const Value('https://banana.com'),
      type: 'url',
      createdAt: now.subtract(const Duration(minutes: 1)),
    ));

    await tester.pumpWidget(const MaterialApp(home: ItemListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Apple'), findsOneWidget);
    expect(find.text('Banana'), findsOneWidget);

    // Toggle search
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    // Type "Apple"
    await tester.enterText(find.byType(TextField), 'Apple');
    // We need to wait for the stream to update. 
    // Drift's search might take a moment to propagate through the trigger.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Use a more specific finder to avoid matching the TextField content
    expect(find.descendant(of: find.byType(ListView), matching: find.text('Apple')), findsOneWidget);
    expect(find.text('Banana'), findsNothing);

    // Clear search
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('Apple'), findsOneWidget);
    expect(find.text('Banana'), findsOneWidget);
    
    // Clear any pending timers
    await tester.pumpWidget(Container());
    await tester.pump(const Duration(seconds: 1));
  });
}
