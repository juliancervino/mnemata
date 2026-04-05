import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mnemata/features/backup/services/backup_scheduler_service.dart';
import 'package:mnemata/features/backup/services/cloud_backup_provider.dart';
import 'package:mnemata/features/backup/services/network_power_signal_service.dart';
import 'package:mnemata/features/settings/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('BackupSchedulerService', () {
    late SettingsService settingsService;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      settingsService = SettingsService(prefs);
      await settingsService.setAutoBackupEnabled(true);
      await settingsService.setBackupRequireWifi(true);
      await settingsService.setBackupRequireCharging(true);
    });

    test(
      'runIfDue executes daily backup when policy constraints are met',
      () async {
        final provider = _RecordingCloudBackupProvider();
        final tempDir = await Directory.systemTemp.createTemp(
          'scheduler_due_test_',
        );
        final archive = File('${tempDir.path}/backup.zip');
        await archive.writeAsBytes(const <int>[1, 2, 3], flush: true);

        final scheduler = BackupSchedulerService(
          settingsService: settingsService,
          cloudBackupProvider: provider,
          createBackupArchive: () async => archive.path,
          networkPowerSignalService: _FakeNetworkPowerSignalService(
            wifiConnected: true,
            charging: true,
          ),
          nowProvider: () => DateTime.utc(2026, 4, 4, 12),
        );

        await settingsService.setLastSuccessfulBackupAt(
          DateTime.utc(2026, 4, 2, 12),
        );

        try {
          final result = await scheduler.runIfDue();

          expect(result.executed, isTrue);
          expect(result.skipReason, isNull);
          expect(provider.uploadCalls, 1);
          expect(
            settingsService.lastSuccessfulBackupAt,
            DateTime.utc(2026, 4, 4, 12),
          );
          expect(settingsService.lastBackupFailureReason, isNull);
        } finally {
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        }
      },
    );

    test(
      'runIfDue skips and records reason when wifi or charging is unmet',
      () async {
        final provider = _RecordingCloudBackupProvider();

        final scheduler = BackupSchedulerService(
          settingsService: settingsService,
          cloudBackupProvider: provider,
          createBackupArchive: () async => '/tmp/never_used.zip',
          networkPowerSignalService: _FakeNetworkPowerSignalService(
            wifiConnected: false,
            charging: true,
          ),
          nowProvider: () => DateTime.utc(2026, 4, 4, 12),
        );

        final result = await scheduler.runIfDue();

        expect(result.executed, isFalse);
        expect(result.skipReason, BackupSkipReason.wifiRequired);
        expect(provider.uploadCalls, 0);
        expect(settingsService.lastBackupFailureReason, 'policy_wifi_required');
        expect(settingsService.lastSuccessfulBackupAt, isNull);
      },
    );
  });
}

class _RecordingCloudBackupProvider implements CloudBackupProvider {
  int uploadCalls = 0;
  int deleteCalls = 0;

  @override
  Future<Uint8List> downloadBackup({required String backupId}) {
    throw UnimplementedError();
  }

  @override
  Future<List<CloudBackupDescriptor>> listBackups() async {
    return const <CloudBackupDescriptor>[];
  }

  @override
  Future<CloudBackupUploadReceipt> uploadBackup({
    required String archivePath,
  }) async {
    uploadCalls += 1;
    return CloudBackupUploadReceipt(
      backupId: 'backup-1',
      remoteId: 'remote-1',
      uploadedAt: DateTime.utc(2026, 4, 4, 12),
    );
  }

  @override
  Future<void> deleteBackup({required String backupId}) async {
    deleteCalls += 1;
  }
}

class _FakeNetworkPowerSignalService implements NetworkPowerSignalService {
  _FakeNetworkPowerSignalService({
    required this.wifiConnected,
    required this.charging,
  });

  final bool wifiConnected;
  final bool charging;

  @override
  Future<bool> isWifiConnected() async => wifiConnected;

  @override
  Future<bool> isCharging() async => charging;
}
