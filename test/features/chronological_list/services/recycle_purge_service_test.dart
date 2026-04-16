import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/features/chronological_list/services/recycle_purge_service.dart';
import 'package:mnemata/features/settings/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/open.dart';

void main() {
  late AppDatabase database;
  late SettingsService settingsService;

  setUpAll(() {
    if (Platform.isLinux) {
      open.overrideFor(
        OperatingSystem.linux,
        () => DynamicLibrary.open('libsqlite3.so.0'),
      );
    }
  });

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    settingsService = SettingsService(prefs);
  });

  tearDown(() async {
    await database.close();
  });

  test('purgeExpired permanently deletes recycle-bin items older than cutoff',
      () async {
    final oldId = await database.insertItem(
      MnemataItemsCompanion.insert(
        title: const Value('Old'),
        type: 'url',
        createdAt: DateTime.utc(2026, 3, 1),
      ),
    );
    final freshId = await database.insertItem(
      MnemataItemsCompanion.insert(
        title: const Value('Fresh'),
        type: 'url',
        createdAt: DateTime.utc(2026, 4, 14),
      ),
    );

    await database.markItemDeletedAt(oldId, DateTime.utc(2026, 3, 10));
    await database.markItemDeletedAt(freshId, DateTime.utc(2026, 4, 15));

    await settingsService.setRecycleBinRetentionDays(7);
    final service = RecyclePurgeService(
      database: database,
      settingsService: settingsService,
      nowProvider: () => DateTime.utc(2026, 4, 16),
    );

    final purged = await service.purgeExpired();

    expect(purged, equals(1));

    final recycleItems = await database.watchRecycleBinItems().first;
    expect(recycleItems.map((item) => item.id), contains(freshId));
    expect(recycleItems.map((item) => item.id), isNot(contains(oldId)));
  });
}
