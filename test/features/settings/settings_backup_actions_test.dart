import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mnemata/features/backup/services/backup_archive_service.dart';
import 'package:mnemata/features/backup/services/backup_restore_service.dart';
import 'package:mnemata/features/backup/services/backup_storage_service.dart';
import 'package:mnemata/features/backup/services/cloud_backup_provider.dart';
import 'package:mnemata/features/settings/presentation/settings_screen.dart';
import 'package:mnemata/features/settings/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<SettingsService> buildSettingsService() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    return SettingsService(prefs);
  }

  BackupRestoreService buildRestoreService() {
    final storageService = BackupStorageService();
    final archiveService = BackupArchiveService(
      storageService: storageService,
      databaseBytesProvider: () async => const <int>[1],
      settingsJsonProvider: () async => <String, dynamic>{'autoTagDomain': true},
      attachmentsDirectoryPathProvider: () async => null,
      appVersionProvider: () async => '2.0.0-test',
      nowProvider: () => DateTime.utc(2026, 4, 5, 10),
    );

    return BackupRestoreService(
      archiveService: archiveService,
      storageService: storageService,
      liveDatabasePathProvider: () async => '/tmp/mnemata_db.sqlite',
      liveAttachmentsDirectoryPathProvider: () async => '/tmp/mnemata_files',
      settingsImporter: (_) async {},
    );
  }

  testWidgets('manual backup action creates archive then uploads to cloud', (tester) async {
    final settingsService = await buildSettingsService();
    final restoreService = buildRestoreService();
    final order = <String>[];
    String? uploadedPath;

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          settingsService: settingsService,
          backupRestoreService: restoreService,
          createBackupArchiveAction: () async {
            order.add('create');
            return '/tmp/manual_backup.zip';
          },
          uploadBackupAction: (archivePath) async {
            order.add('upload');
            uploadedPath = archivePath;
            return CloudBackupUploadReceipt(
              backupId: 'manual_backup',
              remoteId: 'remote-manual-backup',
              uploadedAt: DateTime.utc(2026, 4, 5, 10, 15),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Upload backup to Google Drive'));
    await tester.pumpAndSettle();

    expect(order, equals(<String>['create', 'upload']));
    expect(uploadedPath, equals('/tmp/manual_backup.zip'));
    expect(find.textContaining('Backup uploaded to Google Drive'), findsOneWidget);
  });

  testWidgets('manual backup action surfaces cloud upload failure and diagnostics', (tester) async {
    final settingsService = await buildSettingsService();
    final restoreService = buildRestoreService();
    final archivePath = '/tmp/manual_backup_failure.zip';

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          settingsService: settingsService,
          backupRestoreService: restoreService,
          createBackupArchiveAction: () async => archivePath,
          uploadBackupAction: (_) async {
            throw const CloudBackupProviderException(
              code: CloudBackupProviderErrorCode.authenticationRequired,
              message: 'Sign in required.',
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Upload backup to Google Drive'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Cloud backup failed'), findsOneWidget);
    expect(find.textContaining(archivePath), findsOneWidget);
  });
}
