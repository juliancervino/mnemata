import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mnemata/main.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'dart:ffi';
import 'dart:io';
import 'package:sqlite3/open.dart';

void main() {
  setUpAll(() {
    if (Platform.isLinux) {
      open.overrideFor(OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
    }
  });

  setUp(() async {
    await GetIt.instance.reset();
    // We need to register the database for the test to work
    GetIt.instance.registerSingleton<AppDatabase>(AppDatabase.forTesting(NativeDatabase.memory()));
  });

  testWidgets('Mnemata app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // We need to call setupLocator or manually register what MyApp needs.
    // main.dart has setupLocator() but it registers real database.
    // Let's just mock the essentials.
    
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify that the app title is shown.
    expect(find.text('Mnemata'), findsOneWidget);
    
    // Clear any pending timers
    await tester.pumpWidget(Container());
    await tester.pump(const Duration(seconds: 1));
  });
}
