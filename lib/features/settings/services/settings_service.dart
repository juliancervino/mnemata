import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  static const String _keyAutoTagDomain = 'autoTagDomain';
  static const String _keyAutoTagYear = 'autoTagYear';

  bool get autoTagDomain => _prefs.getBool(_keyAutoTagDomain) ?? true;

  Future<void> setAutoTagDomain(bool value) async {
    await _prefs.setBool(_keyAutoTagDomain, value);
  }

  bool get autoTagYear => _prefs.getBool(_keyAutoTagYear) ?? true;

  Future<void> setAutoTagYear(bool value) async {
    await _prefs.setBool(_keyAutoTagYear, value);
  }
}
