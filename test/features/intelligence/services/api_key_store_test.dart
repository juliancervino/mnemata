import 'package:flutter_test/flutter_test.dart';
import 'package:mnemata/features/intelligence/services/api_key_store.dart';
import 'package:mnemata/features/settings/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _InMemorySecureStore implements SecureKeyValueStore {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }

  @override
  Future<String?> read(String key) async {
    return _values[key];
  }

  @override
  Future<void> write({required String key, required String value}) async {
    _values[key] = value;
  }
}

void main() {
  group('ApiKeyStore', () {
    test('save/read/delete works using secure store only', () async {
      final secureStore = _InMemorySecureStore();
      final apiKeyStore = ApiKeyStore(secureStore: secureStore);

      await apiKeyStore.saveKey('test-key');
      expect(await apiKeyStore.readKey(), 'test-key');
      expect(await apiKeyStore.hasKey(), isTrue);

      await apiKeyStore.clearKey();
      expect(await apiKeyStore.readKey(), isNull);
      expect(await apiKeyStore.hasKey(), isFalse);
    });

    test('missing key reports unavailable summary and semantic capabilities', () async {
      final secureStore = _InMemorySecureStore();
      final apiKeyStore = ApiKeyStore(secureStore: secureStore);

      final status = await apiKeyStore.readCapabilityStatus();
      expect(status.summaryAvailable, isFalse);
      expect(status.semanticSearchAvailable, isFalse);
      expect(status.reason, IntelligenceCapabilityReason.missingApiKey);
    });
  });

  group('SettingsService intelligence defaults', () {
    test('intelligence toggles default to safe-off values', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final service = SettingsService(prefs);

      expect(service.aiSummaryEnabled, isFalse);
      expect(service.semanticSearchEnabled, isFalse);
      expect(service.aiTagSuggestionsEnabled, isFalse);
    });
  });
}
