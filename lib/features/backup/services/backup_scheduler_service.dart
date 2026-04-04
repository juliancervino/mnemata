import 'package:mnemata/features/backup/services/cloud_backup_provider.dart';
import 'package:mnemata/features/settings/services/settings_service.dart';

enum BackupSkipReason {
  alreadyRunning,
  disabled,
  notDue,
  wifiRequired,
  chargingRequired,
}

class BackupPolicyEvaluation {
  const BackupPolicyEvaluation({
    required this.shouldRun,
    this.skipReason,
    this.reasonCode,
  });

  final bool shouldRun;
  final BackupSkipReason? skipReason;
  final String? reasonCode;
}

class BackupSchedulerResult {
  const BackupSchedulerResult({
    required this.executed,
    this.skipReason,
    this.failureReasonCode,
  });

  final bool executed;
  final BackupSkipReason? skipReason;
  final String? failureReasonCode;
}

class BackupSchedulerService {
  BackupSchedulerService({
    required SettingsService settingsService,
    required CloudBackupProvider cloudBackupProvider,
    required Future<String> Function() createBackupArchive,
    required Future<bool> Function() isWifiConnected,
    required Future<bool> Function() isDeviceCharging,
    DateTime Function()? nowProvider,
  })  : _settingsService = settingsService,
        _cloudBackupProvider = cloudBackupProvider,
        _createBackupArchive = createBackupArchive,
        _isWifiConnected = isWifiConnected,
        _isDeviceCharging = isDeviceCharging,
        _nowProvider = nowProvider ?? DateTime.now;

  final SettingsService _settingsService;
  final CloudBackupProvider _cloudBackupProvider;
  final Future<String> Function() _createBackupArchive;
  final Future<bool> Function() _isWifiConnected;
  final Future<bool> Function() _isDeviceCharging;
  final DateTime Function() _nowProvider;

  bool _isRunning = false;

  Future<BackupSchedulerResult> runIfDue() async {
    if (_isRunning) {
      const reason = 'policy_already_running';
      await _settingsService.setLastBackupFailureReason(reason);
      return const BackupSchedulerResult(
        executed: false,
        skipReason: BackupSkipReason.alreadyRunning,
        failureReasonCode: reason,
      );
    }

    _isRunning = true;
    final now = _nowProvider().toUtc();

    try {
      final evaluation = evaluatePolicy(
        now: now,
        lastSuccessfulBackupAt: _settingsService.lastSuccessfulBackupAt,
        autoBackupEnabled: _settingsService.autoBackupEnabled,
        requireWifi: _settingsService.backupRequireWifi,
        requireCharging: _settingsService.backupRequireCharging,
        isWifiConnected: await _isWifiConnected(),
        isCharging: await _isDeviceCharging(),
      );

      if (!evaluation.shouldRun) {
        await _settingsService.setLastBackupAttemptAt(now);
        await _settingsService.setLastBackupFailureReason(evaluation.reasonCode);
        return BackupSchedulerResult(
          executed: false,
          skipReason: evaluation.skipReason,
          failureReasonCode: evaluation.reasonCode,
        );
      }

      final archivePath = await _createBackupArchive();
      await _cloudBackupProvider.uploadBackup(archivePath: archivePath);

      await _settingsService.setLastBackupAttemptAt(now);
      await _settingsService.setLastSuccessfulBackupAt(now);
      await _settingsService.clearLastBackupFailureReason();

      return const BackupSchedulerResult(executed: true);
    } on CloudBackupProviderException catch (error) {
      await _settingsService.setLastBackupAttemptAt(now);
      await _settingsService
          .setLastBackupFailureReason('upload_${error.code.name}');
      return BackupSchedulerResult(
        executed: false,
        failureReasonCode: 'upload_${error.code.name}',
      );
    } catch (_) {
      await _settingsService.setLastBackupAttemptAt(now);
      await _settingsService.setLastBackupFailureReason('upload_unknown');
      return const BackupSchedulerResult(
        executed: false,
        failureReasonCode: 'upload_unknown',
      );
    } finally {
      _isRunning = false;
    }
  }

  BackupPolicyEvaluation evaluatePolicy({
    required DateTime now,
    required DateTime? lastSuccessfulBackupAt,
    required bool autoBackupEnabled,
    required bool requireWifi,
    required bool requireCharging,
    required bool isWifiConnected,
    required bool isCharging,
  }) {
    if (!autoBackupEnabled) {
      return const BackupPolicyEvaluation(
        shouldRun: false,
        skipReason: BackupSkipReason.disabled,
        reasonCode: 'policy_disabled',
      );
    }

    if (requireWifi && !isWifiConnected) {
      return const BackupPolicyEvaluation(
        shouldRun: false,
        skipReason: BackupSkipReason.wifiRequired,
        reasonCode: 'policy_wifi_required',
      );
    }

    if (requireCharging && !isCharging) {
      return const BackupPolicyEvaluation(
        shouldRun: false,
        skipReason: BackupSkipReason.chargingRequired,
        reasonCode: 'policy_charging_required',
      );
    }

    if (lastSuccessfulBackupAt != null) {
      final elapsed = now.toUtc().difference(lastSuccessfulBackupAt.toUtc());
      if (elapsed.inHours < 24) {
        return const BackupPolicyEvaluation(
          shouldRun: false,
          skipReason: BackupSkipReason.notDue,
          reasonCode: 'policy_not_due',
        );
      }
    }

    return const BackupPolicyEvaluation(shouldRun: true);
  }
}
