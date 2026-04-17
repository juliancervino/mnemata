import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mnemata/features/backup/services/backup_archive_service.dart';
import 'package:mnemata/features/backup/services/backup_restore_service.dart';
import 'package:mnemata/features/backup/services/backup_storage_service.dart';
import 'package:mnemata/features/backup/services/cloud_backup_provider.dart';

void main() {
  late Directory rootDir;
  late BackupStorageService storageService;
  late BackupArchiveService archiveService;
  late _MockCloudBackupProvider cloudProvider;

  setUp(() async {
    rootDir = await Directory.systemTemp.createTemp('cloud_to_restore_test_');
    storageService = BackupStorageService(stagingRootDirectory: rootDir);
    archiveService = BackupArchiveService(
      storageService: storageService,
      databaseBytesProvider: () async => utf8.encode('test-db-content'),
      settingsJsonProvider: () async => {'testSetting': true},
      nowProvider: () => DateTime.utc(2026, 4, 17, 12),
      appVersionProvider: () async => '1.0.0-integration',
    );
    cloudProvider = _MockCloudBackupProvider();
  });

  tearDown(() async {
    if (await rootDir.exists()) {
      await rootDir.delete(recursive: true);
    }
  });

  test('happy path: archive -> upload -> list -> download -> stage -> apply', () async {
    final liveDb = File('${rootDir.path}/live/mnemata_db.sqlite');
    await liveDb.parent.create(recursive: true);
    await liveDb.writeAsString('initial-live-db', flush: true);

    var applyCalled = false;
    final restoreService = BackupRestoreService(
      archiveService: archiveService,
      storageService: storageService,
      liveDatabasePathProvider: () async => liveDb.path,
      applyStagedRestore: (stagedPath) async {
        // In this integration test, we simulate the apply by checking staged content
        final dbFile = File('${stagedPath}/${BackupArchiveService.databaseEntry}');
        final dbContent = await dbFile.readAsString();
        expect(dbContent, 'test-db-content');
        applyCalled = true;
      },
    );

    // 1. Create Archive
    final archivePath = await archiveService.createBackupArchive();
    expect(await File(archivePath).exists(), isTrue);

    // 2. Upload to Cloud
    final uploadReceipt = await cloudProvider.uploadBackup(archivePath: archivePath);
    expect(uploadReceipt.backupId, contains('mnemata_backup_'));

    // 3. List Backups
    final backups = await cloudProvider.listBackups();
    expect(backups, hasLength(1));
    expect(backups.first.backupId, uploadReceipt.backupId);

    // 4. Download Backup
    final downloadedBytes = await cloudProvider.downloadBackup(
      backupId: backups.first.backupId,
    );
    expect(downloadedBytes, await File(archivePath).readAsBytes());

    // 5. Stage Downloaded Archive
    final stagedArchivePath = await restoreService.stageDownloadedArchive(
      downloadedBytes,
      backupId: backups.first.backupId,
    );
    expect(await File(stagedArchivePath).exists(), isTrue);

    // 6. Apply Restore
    final result = await restoreService.applyRestore(
      stagedArchivePath,
      confirmed: true,
    );

    expect(result.applied, isTrue);
    expect(applyCalled, isTrue);
  });
}

class _MockCloudBackupProvider implements CloudBackupProvider {
  final Map<String, Uint8List> _storage = {};

  @override
  Future<CloudBackupUploadReceipt> uploadBackup({required String archivePath}) async {
    final bytes = await File(archivePath).readAsBytes();
    final backupId = File(archivePath).uri.pathSegments.last.replaceAll('.zip', '');
    _storage[backupId] = bytes;

    return CloudBackupUploadReceipt(
      backupId: backupId,
      remoteId: 'remote-$backupId',
      uploadedAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<List<CloudBackupDescriptor>> listBackups() async {
    return _storage.entries.map((e) {
      return CloudBackupDescriptor(
        backupId: e.key,
        remoteId: 'remote-${e.key}',
        createdAt: DateTime.now().toUtc(),
        sizeBytes: e.value.length,
      );
    }).toList();
  }

  @override
  Future<Uint8List> downloadBackup({required String backupId}) async {
    final bytes = _storage[backupId];
    if (bytes == null) {
      throw const CloudBackupProviderException(
        code: CloudBackupProviderErrorCode.notFound,
        message: 'Backup not found',
      );
    }
    return bytes;
  }

  @override
  Future<void> deleteBackup({required String backupId}) async {
    _storage.remove(backupId);
  }
}
