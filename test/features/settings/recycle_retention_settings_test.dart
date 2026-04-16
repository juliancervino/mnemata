import 'package:flutter_test/flutter_test.dart';
import 'package:mnemata/features/settings/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<SettingsService> buildService({Map<String, Object>? initialValues}) async {
    SharedPreferences.setMockInitialValues(initialValues ?? <String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    return SettingsService(prefs);
  }

  test('recycle retention defaults to 30 days', () async {
    final service = await buildService();

    expect(service.recycleBinRetentionDays, equals(30));
  });

  test('recycle retention clamps persisted values to 1..30', () async {
    final service = await buildService();

    await service.setRecycleBinRetentionDays(0);
    expect(service.recycleBinRetentionDays, equals(1));

    await service.setRecycleBinRetentionDays(45);
    expect(service.recycleBinRetentionDays, equals(30));

    await service.setRecycleBinRetentionDays(14);
    expect(service.recycleBinRetentionDays, equals(14));
  });

  test('recycle retention normalizes invalid stored values', () async {
    final serviceLow = await buildService(
      initialValues: <String, Object>{'recycleBinRetentionDays': -4},
    );
    expect(serviceLow.recycleBinRetentionDays, equals(1));

    final serviceHigh = await buildService(
      initialValues: <String, Object>{'recycleBinRetentionDays': 200},
    );
    expect(serviceHigh.recycleBinRetentionDays, equals(30));
  });
}
