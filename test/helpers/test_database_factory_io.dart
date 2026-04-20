import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:sqlite3/open.dart';

AppDatabase createTestDatabase() {
  if (Platform.isLinux) {
    open.overrideFor(
      OperatingSystem.linux,
      () => DynamicLibrary.open('libsqlite3.so.0'),
    );
  }

  return AppDatabase.forTesting(NativeDatabase.memory());
}
