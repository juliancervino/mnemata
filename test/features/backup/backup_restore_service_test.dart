import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mnemata/features/backup/domain/backup_manifest.dart';
import 'package:mnemata/features/backup/services/backup_archive_service.dart';
import 'package:mnemata/features/backup/services/backup_restore_service.dart';
import 'package:mnemata/features/backup/services/backup_storage_service.dart';

void main() {
  late Directory rootDir;
  late BackupStorageService storageService;
  late BackupArchiveService archiveService;

  setUp(() async {
    rootDir = await Directory.systemTemp.createTemp('backup_restore_test_');
    storageService = BackupStorageService(stagingRootDirectory: rootDir);
    archiveService = BackupArchiveService(
      storageService: storageService,
      databaseBytesProvider: () async => utf8.encode('unused-db-bytes'),
      settingsJsonProvider: () async => {'autoTagDomain': true},
      nowProvider: () => DateTime.utc(2026, 4, 4, 12),
      appVersionProvider: () async => '2.0.0-test',
    );
  });

  tearDown(() async {
    if (await rootDir.exists()) {
      await rootDir.delete(recursive: true);
    }
  });

  test('previewBackup returns metadata and does not mutate live data', () async {
    final liveDb = File('${rootDir.path}/live/mnemata_db.sqlite');
    await liveDb.parent.create(recursive: true);
    await liveDb.writeAsString('live-db-before', flush: true);

    final archivePath = await _createArchiveWithManifest(
      rootDir: rootDir,
      databaseBytes: utf8.encode('backup-db'),
      filesByPath: {'note.txt': utf8.encode('note')},
      settingsJson: {'autoTagDomain': true, 'autoTagYear': false},
      createdAtIso: '2026-04-04T12:00:00.000Z',
    );

    var applyCalled = false;
    final restoreService = BackupRestoreService(
      archiveService: archiveService,
      storageService: storageService,
      liveDatabasePathProvider: () async => liveDb.path,
      applyStagedRestore: (_) async {
        applyCalled = true;
      },
    );

    final preview = await restoreService.previewBackup(archivePath);

    expect(preview.createdAtIso, '2026-04-04T12:00:00.000Z');
    expect(preview.missingRequiredEntries, isEmpty);
    expect(preview.validationPassed, isTrue);
    expect(preview.fileCount, 1);
    expect(preview.archiveSizeBytes, greaterThan(0));
    expect(await liveDb.readAsString(), 'live-db-before');
    expect(applyCalled, isFalse);
  });

  test('applyRestore aborts when checksum validation fails', () async {
    final liveDb = File('${rootDir.path}/live/mnemata_db.sqlite');
    await liveDb.parent.create(recursive: true);
    await liveDb.writeAsString('live-db-before', flush: true);

    final archivePath = await _createArchiveWithManifest(
      rootDir: rootDir,
      databaseBytes: utf8.encode('backup-db'),
      filesByPath: {'note.txt': utf8.encode('note')},
      settingsJson: {'autoTagDomain': true, 'autoTagYear': false},
      createdAtIso: '2026-04-04T12:00:00.000Z',
      overrideDbChecksum: BackupManifest.computeSha256Hex(utf8.encode('tampered')),
    );

    var applyCalled = false;
    final restoreService = BackupRestoreService(
      archiveService: archiveService,
      storageService: storageService,
      liveDatabasePathProvider: () async => liveDb.path,
      applyStagedRestore: (_) async {
        applyCalled = true;
      },
    );

    final result = await restoreService.applyRestore(
      archivePath,
      confirmed: true,
    );

    expect(result.applied, isFalse);
    expect(result.errorCode, RestoreErrorCode.checksumMismatch);
    expect(result.checksumMismatches, contains(BackupArchiveService.databaseEntry));
    expect(applyCalled, isFalse);
    expect(await liveDb.readAsString(), 'live-db-before');
  });

  test('stageDownloadedArchive creates temp archive file from cloud bytes', () async {
    final restoreService = BackupRestoreService(
      archiveService: archiveService,
      storageService: storageService,
      liveDatabasePathProvider: () async => '${rootDir.path}/live/mnemata_db.sqlite',
    );

    final archiveBytes = utf8.encode('cloud-archive-content');
    final stagedPath = await restoreService.stageDownloadedArchive(
      archiveBytes,
      backupId: 'backup-123',
    );

    final stagedFile = File(stagedPath);
    expect(await stagedFile.exists(), isTrue);
    expect(await stagedFile.readAsBytes(), archiveBytes);
    expect(stagedPath, contains('backup-123'));
  });

  test('applyRestore aborts when archive is missing required entries', () async {
    final liveDb = File('${rootDir.path}/live/mnemata_db.sqlite');
    await liveDb.parent.create(recursive: true);
    await liveDb.writeAsString('live-db-before', flush: true);

    // Create archive missing the database entry
    final archive = Archive()
      ..addFile(
        ArchiveFile(
          BackupArchiveService.settingsEntry,
          utf8.encode('{}').length,
          utf8.encode('{}'),
        ),
      );
    final encoded = ZipEncoder().encode(archive);
    final incompleteArchivePath = '${rootDir.path}/incomplete.zip';
    await File(incompleteArchivePath).writeAsBytes(encoded, flush: true);

    var applyCalled = false;
    final restoreService = BackupRestoreService(
      archiveService: archiveService,
      storageService: storageService,
      liveDatabasePathProvider: () async => liveDb.path,
      applyStagedRestore: (_) async {
        applyCalled = true;
      },
    );

    final result = await restoreService.applyRestore(
      incompleteArchivePath,
      confirmed: true,
    );

    expect(result.applied, isFalse);
    expect(result.errorCode, RestoreErrorCode.missingRequiredEntries);
    expect(result.missingRequiredEntries, contains(BackupArchiveService.databaseEntry));
    expect(applyCalled, isFalse);
    expect(await liveDb.readAsString(), 'live-db-before');
  });
}

Future<String> _createArchiveWithManifest({
  required Directory rootDir,
  required List<int> databaseBytes,
  required Map<String, List<int>> filesByPath,
  required Map<String, dynamic> settingsJson,
  required String createdAtIso,
  String? overrideDbChecksum,
}) async {
  final archive = Archive();

  archive.addFile(
    ArchiveFile(
      BackupArchiveService.databaseEntry,
      databaseBytes.length,
      databaseBytes,
    ),
  );

  archive.addFile(ArchiveFile.directory(BackupArchiveService.filesEntry));
  for (final entry in filesByPath.entries) {
    final relative = 'files/${entry.key}'.replaceAll('\\', '/');
    archive.addFile(ArchiveFile(relative, entry.value.length, entry.value));
  }

  final settingsBytes = utf8.encode(jsonEncode(settingsJson));
  archive.addFile(
    ArchiveFile(
      BackupArchiveService.settingsEntry,
      settingsBytes.length,
      settingsBytes,
    ),
  );

  final fileRows = filesByPath.entries
      .map((entry) => '${entry.key}:${BackupManifest.computeSha256Hex(entry.value)}')
      .toList()
    ..sort();

  final manifest = BackupManifest(
    schemaVersion: 1,
    appVersion: '2.0.0-test',
    createdAtIso: createdAtIso,
    entries: [
      BackupManifestEntry(
        id: BackupArchiveService.databaseEntry,
        relativePath: BackupArchiveService.databaseEntry,
        sha256: overrideDbChecksum ?? BackupManifest.computeSha256Hex(databaseBytes),
      ),
      BackupManifestEntry(
        id: BackupArchiveService.filesEntry,
        relativePath: BackupArchiveService.filesEntry,
        sha256: BackupManifest.computeSha256Hex(utf8.encode(fileRows.join('\n'))),
      ),
      BackupManifestEntry(
        id: BackupArchiveService.settingsEntry,
        relativePath: BackupArchiveService.settingsEntry,
        sha256: BackupManifest.computeSha256Hex(settingsBytes),
      ),
    ],
  );
  final manifestBytes = utf8.encode(jsonEncode(manifest.toJson()));
  archive.addFile(ArchiveFile(BackupArchiveService.manifestEntry, manifestBytes.length, manifestBytes));

  final encoded = ZipEncoder().encode(archive);
  final archiveFile = File('${rootDir.path}/restore_input.zip');
  await archiveFile.writeAsBytes(encoded, flush: true);
  return archiveFile.path;
}