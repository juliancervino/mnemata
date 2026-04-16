import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  static const String _keyAutoTagDomain = 'autoTagDomain';
  static const String _keyAutoTagYear = 'autoTagYear';
  static const String _keyAutoBackupEnabled = 'autoBackupEnabled';
  static const String _keyBackupRequireWifi = 'backupRequireWifi';
  static const String _keyBackupRequireCharging = 'backupRequireCharging';
  static const String _keyLastSuccessfulBackupAt = 'lastSuccessfulBackupAt';
  static const String _keyLastBackupAttemptAt = 'lastBackupAttemptAt';
  static const String _keyLastBackupFailureReason = 'lastBackupFailureReason';
  static const String _keyLastBackupRemoteId = 'lastBackupRemoteId';
  static const String _keyLastBackupResultStatus = 'lastBackupResultStatus';
  static const String _keyLastBackupSizeBytes = 'lastBackupSizeBytes';
  static const String _keyBackupMaxCount = 'backupMaxCount';
  static const String _keyRecycleBinRetentionDays = 'recycleBinRetentionDays';
  static const String _keyAiSummaryEnabled = 'aiSummaryEnabled';
  static const String _keySemanticSearchEnabled = 'semanticSearchEnabled';
  static const String _keyAiTagSuggestionsEnabled = 'aiTagSuggestionsEnabled';
  static const String _keyAiProvider = 'aiProvider';

  static const int defaultBackupMaxCount = 7;
  static const int maxBackupMaxCount = 30;
  static const int defaultRecycleBinRetentionDays = 30;
  static const int minRecycleBinRetentionDays = 1;
  static const int maxRecycleBinRetentionDays = 30;

  bool get autoTagDomain => _prefs.getBool(_keyAutoTagDomain) ?? true;

  Future<void> setAutoTagDomain(bool value) async {
    await _prefs.setBool(_keyAutoTagDomain, value);
  }

  bool get autoTagYear => _prefs.getBool(_keyAutoTagYear) ?? true;

  Future<void> setAutoTagYear(bool value) async {
    await _prefs.setBool(_keyAutoTagYear, value);
  }

  bool get autoBackupEnabled => _prefs.getBool(_keyAutoBackupEnabled) ?? true;

  Future<void> setAutoBackupEnabled(bool value) async {
    await _prefs.setBool(_keyAutoBackupEnabled, value);
  }

  bool get backupRequireWifi => _prefs.getBool(_keyBackupRequireWifi) ?? true;

  Future<void> setBackupRequireWifi(bool value) async {
    await _prefs.setBool(_keyBackupRequireWifi, value);
  }

  bool get backupRequireCharging =>
      _prefs.getBool(_keyBackupRequireCharging) ?? true;

  Future<void> setBackupRequireCharging(bool value) async {
    await _prefs.setBool(_keyBackupRequireCharging, value);
  }

  DateTime? get lastSuccessfulBackupAt =>
      _readDateTime(_keyLastSuccessfulBackupAt);

  Future<void> setLastSuccessfulBackupAt(DateTime? value) async {
    await _writeDateTime(_keyLastSuccessfulBackupAt, value);
  }

  DateTime? get lastBackupAttemptAt => _readDateTime(_keyLastBackupAttemptAt);

  Future<void> setLastBackupAttemptAt(DateTime? value) async {
    await _writeDateTime(_keyLastBackupAttemptAt, value);
  }

  String? get lastBackupFailureReason =>
      _prefs.getString(_keyLastBackupFailureReason);

  Future<void> setLastBackupFailureReason(String? reason) async {
    if (reason == null || reason.trim().isEmpty) {
      await _prefs.remove(_keyLastBackupFailureReason);
      return;
    }

    await _prefs.setString(_keyLastBackupFailureReason, reason);
  }

  Future<void> clearLastBackupFailureReason() async {
    await _prefs.remove(_keyLastBackupFailureReason);
  }

  String? get lastBackupRemoteId => _prefs.getString(_keyLastBackupRemoteId);

  Future<void> setLastBackupRemoteId(String? remoteId) async {
    if (remoteId == null || remoteId.trim().isEmpty) {
      await _prefs.remove(_keyLastBackupRemoteId);
      return;
    }
    await _prefs.setString(_keyLastBackupRemoteId, remoteId);
  }

  String? get lastBackupResultStatus =>
      _prefs.getString(_keyLastBackupResultStatus);

  Future<void> setLastBackupResultStatus(String? status) async {
    if (status == null || status.trim().isEmpty) {
      await _prefs.remove(_keyLastBackupResultStatus);
      return;
    }
    await _prefs.setString(_keyLastBackupResultStatus, status);
  }

  int? get lastBackupSizeBytes {
    final value = _prefs.getInt(_keyLastBackupSizeBytes);
    if (value == null || value < 0) {
      return null;
    }
    return value;
  }

  Future<void> setLastBackupSizeBytes(int? bytes) async {
    if (bytes == null || bytes < 0) {
      await _prefs.remove(_keyLastBackupSizeBytes);
      return;
    }

    await _prefs.setInt(_keyLastBackupSizeBytes, bytes);
  }

  int get backupMaxCount {
    final value = _prefs.getInt(_keyBackupMaxCount);
    if (value == null || value < 1) {
      return defaultBackupMaxCount;
    }

    if (value > maxBackupMaxCount) {
      return maxBackupMaxCount;
    }

    return value;
  }

  Future<void> setBackupMaxCount(int value) async {
    final normalized = value.clamp(1, maxBackupMaxCount).toInt();
    await _prefs.setInt(_keyBackupMaxCount, normalized);
  }

  int get recycleBinRetentionDays {
    final value = _prefs.getInt(_keyRecycleBinRetentionDays);
    if (value == null) {
      return defaultRecycleBinRetentionDays;
    }
    return value.clamp(minRecycleBinRetentionDays, maxRecycleBinRetentionDays);
  }

  Future<void> setRecycleBinRetentionDays(int value) async {
    final normalized = value
        .clamp(minRecycleBinRetentionDays, maxRecycleBinRetentionDays)
        .toInt();
    await _prefs.setInt(_keyRecycleBinRetentionDays, normalized);
  }

  bool get aiSummaryEnabled => _prefs.getBool(_keyAiSummaryEnabled) ?? false;

  Future<void> setAiSummaryEnabled(bool value) async {
    await _prefs.setBool(_keyAiSummaryEnabled, value);
  }

  bool get semanticSearchEnabled =>
      _prefs.getBool(_keySemanticSearchEnabled) ?? false;

  Future<void> setSemanticSearchEnabled(bool value) async {
    await _prefs.setBool(_keySemanticSearchEnabled, value);
  }

  bool get aiTagSuggestionsEnabled =>
      _prefs.getBool(_keyAiTagSuggestionsEnabled) ?? false;

  Future<void> setAiTagSuggestionsEnabled(bool value) async {
    await _prefs.setBool(_keyAiTagSuggestionsEnabled, value);
  }

  String get aiProvider {
    final raw = _prefs.getString(_keyAiProvider)?.trim().toLowerCase();
    switch (raw) {
      case 'openai':
      case 'claude':
      case 'gemini':
        return raw!;
      default:
        return 'gemini';
    }
  }

  Future<void> setAiProvider(String value) async {
    final normalized = value.trim().toLowerCase();
    final safe = switch (normalized) {
      'openai' => 'openai',
      'claude' => 'claude',
      _ => 'gemini',
    };
    await _prefs.setString(_keyAiProvider, safe);
  }

  DateTime? _readDateTime(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    return DateTime.tryParse(raw)?.toUtc();
  }

  Future<void> _writeDateTime(String key, DateTime? value) async {
    if (value == null) {
      await _prefs.remove(key);
      return;
    }

    await _prefs.setString(key, value.toUtc().toIso8601String());
  }
}
