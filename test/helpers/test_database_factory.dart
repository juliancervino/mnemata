import 'package:mnemata/core/database/app_database.dart';

import 'test_database_factory_web.dart'
    if (dart.library.io) 'test_database_factory_io.dart'
    as impl;

AppDatabase createTestDatabase() => impl.createTestDatabase();
