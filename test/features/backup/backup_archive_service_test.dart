import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mnemata/features/backup/services/backup_archive_service.dart';
import 'package:mnemata/features/backup/services/backup_storage_service.dart';

void main() {
  late Directory rootDir;
  late BackupStorageService storageService;

  setUp(() async {
    rootDir = await Directory.systemTemp.createTemp('backup_archive_test_');
    storageService = BackupStorageService(stagingRootDirectory: rootDir);
  });

  tearDown(() async {
    if (await rootDir.exists()) {
      await rootDir.delete(recursive: true);
    }
  });

  test('generated archive includes required backup entries', () async {
    final attachmentsDir = Directory('${rootDir.path}/attachments');
    await attachmentsDir.create(recursive: true);
    await File('${attachmentsDir.path}/note.txt').writeAsString('note');

    final service = BackupArchiveService(
      storageService: storageService,
      databaseBytesProvider: () async => utf8.encode('db-bytes'),
      settingsJsonProvider: () async => {'autoTagDomain': true, 'autoTagYear': false},
      attachmentsDirectoryPathProvider: () async => attachmentsDir.path,
      nowProvider: () => DateTime.utc(2026, 4, 4, 12),
      appVersionProvider: () async => '2.0.0-test',
    );

    final archivePath = await service.createBackupArchive();
    final bytes = await File(archivePath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final names = archive.files.map((file) => file.name).toSet();

    expect(names, contains('manifest.json'));
    expect(names, contains('database/mnemata_db.sqlite'));
    expect(names, contains('files/'));
    expect(names, contains('settings/settings.json'));

    final missing = await service.inspectArchiveRequiredEntries(archivePath);
    expect(missing, isEmpty);
  });

  test('archive inspection reports missing required entries', () async {
    final incompleteArchivePath = '${rootDir.path}/incomplete.zip';

    final archive = Archive()
      ..addFile(
        ArchiveFile(
          'settings/settings.json',
          utf8.encode('{"autoTagDomain":true}').length,
          utf8.encode('{"autoTagDomain":true}'),
        ),
      );
    final encoded = ZipEncoder().encode(archive)!;
    await File(incompleteArchivePath).writeAsBytes(encoded, flush: true);

    final service = BackupArchiveService(
      storageService: storageService,
      databaseBytesProvider: () async => utf8.encode('db-bytes'),
      settingsJsonProvider: () async => {'autoTagDomain': true},
      nowProvider: () => DateTime.utc(2026, 4, 4, 12),
      appVersionProvider: () async => '2.0.0-test',
    );

    final missing = await service.inspectArchiveRequiredEntries(incompleteArchivePath);

    expect(missing, contains('manifest.json'));
    expect(missing, contains('database/mnemata_db.sqlite'));
    expect(missing, contains('files/'));
    expect(missing, isNot(contains('settings/settings.json')));
  });
}
