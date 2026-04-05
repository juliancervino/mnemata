import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
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
      settingsJsonProvider: () async => <String, dynamic>{
        'autoTagDomain': true,
      },
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

  tearDown(() {
    GetIt.instance.reset();
  });

  testWidgets('manual backup action creates archive then uploads to cloud', (
    tester,
  ) async {
    final settingsService = await buildSettingsService();
    final restoreService = buildRestoreService();
    final order = <String>[];
    String? uploadedPath;

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          settingsService: settingsService,
          backupRestoreService: restoreService,
          nowProvider: () => DateTime.utc(2026, 4, 5, 10, 0),
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
    await tester.pump(const Duration(seconds: 1));

    expect(order, equals(<String>['create', 'upload']));
    expect(uploadedPath, equals('/tmp/manual_backup.zip'));
    expect(
      find.textContaining('Backup uploaded to Google Drive'),
      findsOneWidget,
    );
    expect(
      settingsService.lastBackupResultStatus,
      equals('manual_upload_success'),
    );
    expect(settingsService.lastBackupRemoteId, equals('remote-manual-backup'));
    await tester.scrollUntilVisible(
      find.text('Last backup result'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(find.textContaining('Last backup result'), findsOneWidget);
    expect(find.textContaining('manual_upload_success'), findsOneWidget);
    expect(find.textContaining('remote-manual-backup'), findsWidgets);
  });

  testWidgets(
    'manual backup applies retention policy using configured maximum',
    (tester) async {
      final settingsService = await buildSettingsService();
      final restoreService = buildRestoreService();
      await settingsService.setBackupMaxCount(2);

      final provider = _FakeCloudBackupProvider(
        backups: <CloudBackupDescriptor>[
          CloudBackupDescriptor(
            backupId: 'newest',
            remoteId: 'remote-newest',
            createdAt: DateTime.utc(2026, 4, 5, 10),
          ),
          CloudBackupDescriptor(
            backupId: 'middle',
            remoteId: 'remote-middle',
            createdAt: DateTime.utc(2026, 4, 4, 10),
          ),
          CloudBackupDescriptor(
            backupId: 'oldest',
            remoteId: 'remote-oldest',
            createdAt: DateTime.utc(2026, 4, 3, 10),
          ),
        ],
        downloadedBytes: <int>[1, 2, 3],
      );
      GetIt.instance.registerSingleton<CloudBackupProvider>(provider);

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            settingsService: settingsService,
            backupRestoreService: restoreService,
            nowProvider: () => DateTime.utc(2026, 4, 5, 10, 0),
            createBackupArchiveAction: () async => '/tmp/manual_backup.zip',
          ),
        ),
      );

      await tester.tap(find.text('Upload backup to Google Drive'));
      await tester.pumpAndSettle();

      expect(provider.deletedBackupIds, equals(<String>['oldest']));
    },
  );

  testWidgets(
    'manual backup action surfaces cloud upload failure and diagnostics',
    (tester) async {
      final settingsService = await buildSettingsService();
      final restoreService = buildRestoreService();
      final archivePath = '/tmp/manual_backup_failure.zip';

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            settingsService: settingsService,
            backupRestoreService: restoreService,
            nowProvider: () => DateTime.utc(2026, 4, 5, 10, 0),
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
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('Cloud backup failed'), findsOneWidget);
      expect(find.textContaining(archivePath), findsOneWidget);
      expect(
        settingsService.lastBackupResultStatus,
        equals('manual_upload_authenticationRequired'),
      );
      expect(
        settingsService.lastBackupFailureReason,
        equals('manual_upload_authenticationRequired'),
      );
      await tester.scrollUntilVisible(
        find.text('Last backup result'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      expect(find.textContaining('Last backup result'), findsOneWidget);
      expect(
        find.textContaining('manual_upload_authenticationRequired'),
        findsWidgets,
      );
    },
  );

  testWidgets('backup diagnostics stay visible after settings screen rebuild', (
    tester,
  ) async {
    final settingsService = await buildSettingsService();
    final restoreService = buildRestoreService();

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          settingsService: settingsService,
          backupRestoreService: restoreService,
          nowProvider: () => DateTime.utc(2026, 4, 5, 10, 0),
          createBackupArchiveAction: () async => '/tmp/manual_backup.zip',
          uploadBackupAction: (_) async => CloudBackupUploadReceipt(
            backupId: 'manual_backup',
            remoteId: 'remote-sticky',
            uploadedAt: DateTime.utc(2026, 4, 5, 10, 15),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Upload backup to Google Drive'));
    await tester.pump(const Duration(seconds: 1));

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          settingsService: settingsService,
          backupRestoreService: restoreService,
          createBackupArchiveAction: () async => '/tmp/manual_backup.zip',
        ),
      ),
    );
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Last backup result'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(find.textContaining('Last backup result'), findsOneWidget);
    expect(find.textContaining('manual_upload_success'), findsOneWidget);
    expect(find.textContaining('remote-sticky'), findsWidgets);
  });

  testWidgets(
    'restore flow lists cloud backups newest-first and shows timestamp plus size',
    (tester) async {
      final settingsService = await buildSettingsService();
      final restoreService = buildRestoreService();
      final provider = _FakeCloudBackupProvider(
        backups: <CloudBackupDescriptor>[
          CloudBackupDescriptor(
            backupId: 'older',
            remoteId: 'remote-older',
            createdAt: DateTime.utc(2026, 4, 4, 10),
          ),
          CloudBackupDescriptor(
            backupId: 'newer',
            remoteId: 'remote-newer',
            createdAt: DateTime.utc(2026, 4, 5, 10),
          ),
        ],
        downloadedBytes: <int>[1, 2, 3],
      );
      GetIt.instance.registerSingleton<CloudBackupProvider>(provider);

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            settingsService: settingsService,
            backupRestoreService: restoreService,
            createBackupArchiveAction: () async => '/tmp/manual_backup.zip',
          ),
        ),
      );

      await tester.tap(find.text('Restore from backup'));
      await tester.pumpAndSettle();

      expect(find.text('Choose a backup from Google Drive'), findsOneWidget);
      final restoreTiles = tester
          .widgetList<ListTile>(find.byType(ListTile))
          .where(
            (tile) =>
                tile.leading is Icon &&
                ((tile.leading as Icon).icon == Icons.cloud_done_outlined),
          );
      final newest = restoreTiles.firstWhere(
        (tile) =>
            tile.subtitle is Text &&
            ((tile.subtitle as Text).data?.contains('ID: remote-newer') ??
                false),
      );
      expect(newest.subtitle, isNotNull);
      expect((newest.subtitle as Text).data, contains('Size:'));
    },
  );

  testWidgets(
    'restore flow downloads selected backup and opens preview without path input',
    (tester) async {
      final settingsService = await buildSettingsService();
      final restoreService = buildRestoreService();
      final provider = _FakeCloudBackupProvider(
        backups: <CloudBackupDescriptor>[
          CloudBackupDescriptor(
            backupId: 'backup-1',
            remoteId: 'remote-backup-1',
            createdAt: DateTime.utc(2026, 4, 5, 10),
          ),
        ],
        downloadedBytes: <int>[1, 2, 3],
      );
      GetIt.instance.registerSingleton<CloudBackupProvider>(provider);

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            settingsService: settingsService,
            backupRestoreService: restoreService,
            createBackupArchiveAction: () async => '/tmp/manual_backup.zip',
          ),
        ),
      );

      await tester.tap(find.text('Restore from backup'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.textContaining('ID: remote-backup-1'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.textContaining('ID: remote-backup-1'));
      await tester.pumpAndSettle();

      expect(provider.downloadedBackupIds, equals(<String>['backup-1']));
      expect(find.text('Archive path'), findsNothing);
    },
  );

  testWidgets('restore flow allows deleting backup with confirmation', (
    tester,
  ) async {
    final settingsService = await buildSettingsService();
    final restoreService = buildRestoreService();
    final provider = _FakeCloudBackupProvider(
      backups: <CloudBackupDescriptor>[
        CloudBackupDescriptor(
          backupId: 'backup-1',
          remoteId: 'remote-backup-1',
          createdAt: DateTime.utc(2026, 4, 5, 10),
        ),
      ],
      downloadedBytes: <int>[1, 2, 3],
    );
    GetIt.instance.registerSingleton<CloudBackupProvider>(provider);

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          settingsService: settingsService,
          backupRestoreService: restoreService,
          createBackupArchiveAction: () async => '/tmp/manual_backup.zip',
        ),
      ),
    );

    await tester.tap(find.text('Restore from backup'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();
    expect(find.text('Delete backup?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(provider.deletedBackupIds, equals(<String>['backup-1']));
  });

  testWidgets(
    'restore flow shows deterministic cloud-list error and blocks restore apply',
    (tester) async {
      final settingsService = await buildSettingsService();
      final restoreService = buildRestoreService();
      final provider = _FakeCloudBackupProvider(
        backups: const <CloudBackupDescriptor>[],
        downloadedBytes: <int>[1, 2, 3],
        listError: const CloudBackupProviderException(
          code: CloudBackupProviderErrorCode.networkUnavailable,
          message: 'No network',
        ),
      );
      GetIt.instance.registerSingleton<CloudBackupProvider>(provider);

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            settingsService: settingsService,
            backupRestoreService: restoreService,
            createBackupArchiveAction: () async => '/tmp/manual_backup.zip',
          ),
        ),
      );

      await tester.tap(find.text('Restore from backup'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Unable to list cloud backups'),
        findsOneWidget,
      );
      expect(provider.downloadedBackupIds, isEmpty);
      expect(find.text('Restore Preview'), findsNothing);
    },
  );
}

class _FakeCloudBackupProvider implements CloudBackupProvider {
  _FakeCloudBackupProvider({
    required this.backups,
    required this.downloadedBytes,
    this.listError,
  });

  final List<CloudBackupDescriptor> backups;
  final List<int> downloadedBytes;
  final CloudBackupProviderException? listError;
  final List<String> downloadedBackupIds = <String>[];
  final List<String> deletedBackupIds = <String>[];

  @override
  Future<List<CloudBackupDescriptor>> listBackups() async {
    if (listError != null) {
      throw listError!;
    }
    return backups;
  }

  @override
  Future<Uint8List> downloadBackup({required String backupId}) async {
    downloadedBackupIds.add(backupId);
    return Uint8List.fromList(downloadedBytes);
  }

  @override
  Future<CloudBackupUploadReceipt> uploadBackup({required String archivePath}) {
    return Future<CloudBackupUploadReceipt>.value(
      CloudBackupUploadReceipt(
        backupId: 'manual_backup',
        remoteId: 'remote-manual-backup',
        uploadedAt: DateTime.utc(2026, 4, 5, 10, 15),
      ),
    );
  }

  @override
  Future<void> deleteBackup({required String backupId}) async {
    deletedBackupIds.add(backupId);
    backups.removeWhere((entry) => entry.backupId == backupId);
  }
}
