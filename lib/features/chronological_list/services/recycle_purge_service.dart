import 'package:flutter/foundation.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/features/settings/services/settings_service.dart';

class RecyclePurgeService {
  RecyclePurgeService({
    required this.database,
    required this.settingsService,
    DateTime Function()? nowProvider,
  }) : _nowProvider = nowProvider ?? DateTime.now;

  final AppDatabase database;
  final SettingsService settingsService;
  final DateTime Function() _nowProvider;

  Future<int> purgeExpired({int batchSize = 200, int maxBatches = 10}) async {
    final retentionDays = settingsService.recycleBinRetentionDays;
    final now = _nowProvider().toUtc();
    final cutoff = now.subtract(Duration(days: retentionDays));

    var totalPurged = 0;
    for (var i = 0; i < maxBatches; i++) {
      final purgedInBatch = await database.purgeRecycleBinBefore(
        cutoff,
        batchSize: batchSize,
      );
      totalPurged += purgedInBatch;
      if (purgedInBatch < batchSize) {
        break;
      }
    }

    debugPrint(
      'recycle_purge.completed retentionDays=$retentionDays cutoff=$cutoff purged=$totalPurged',
    );
    return totalPurged;
  }
}
