import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum IntelligenceCapabilityReason { available, missingApiKey }

class IntelligenceCapabilityStatus {
  const IntelligenceCapabilityStatus({
    required this.summaryAvailable,
    required this.semanticSearchAvailable,
    required this.tagSuggestionAvailable,
    required this.reason,
  });

  final bool summaryAvailable;
  final bool semanticSearchAvailable;
  final bool tagSuggestionAvailable;
  final IntelligenceCapabilityReason reason;
}

abstract class SecureKeyValueStore {
  Future<void> write({required String key, required String value});
  Future<String?> read(String key);
  Future<void> delete(String key);
}

class FlutterSecureKeyValueStore implements SecureKeyValueStore {
  FlutterSecureKeyValueStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<void> write({required String key, required String value}) {
    return _storage.write(key: key, value: value);
  }

  @override
  Future<String?> read(String key) {
    return _storage.read(key: key);
  }

  @override
  Future<void> delete(String key) {
    return _storage.delete(key: key);
  }
}

class ApiKeyStore {
  ApiKeyStore({SecureKeyValueStore? secureStore})
    : _secureStore = secureStore ?? FlutterSecureKeyValueStore();

  static const String intelligenceApiKeyStorageKey =
      'mnemata.intelligence.apiKey';
  static const String _intelligenceApiKeyByProviderPrefix =
      'mnemata.intelligence.apiKey.';

  final SecureKeyValueStore _secureStore;

  Future<void> saveKey(String apiKey) async {
    await saveKeyForProvider(provider: 'gemini', apiKey: apiKey);
  }

  Future<void> saveKeyForProvider({
    required String provider,
    required String apiKey,
  }) async {
    final normalized = apiKey.trim();
    if (normalized.isEmpty) {
      await clearKeyForProvider(provider: provider);
      return;
    }

    final key = _providerStorageKey(provider);
    await _secureStore.write(key: key, value: normalized);

    if (provider.trim().toLowerCase() == 'gemini') {
      await _secureStore.write(
        key: intelligenceApiKeyStorageKey,
        value: normalized,
      );
    }
  }

  Future<String?> readKey() async {
    return readKeyForProvider('gemini');
  }

  Future<String?> readKeyForProvider(String provider) async {
    final key = _providerStorageKey(provider);
    String? value = await _secureStore.read(key);
    if ((value == null || value.trim().isEmpty) &&
        provider.trim().toLowerCase() == 'gemini') {
      value = await _secureStore.read(intelligenceApiKeyStorageKey);
    }
    if (value == null) {
      return null;
    }
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  Future<void> clearKey() {
    return clearKeyForProvider(provider: 'gemini');
  }

  Future<void> clearKeyForProvider({required String provider}) async {
    final key = _providerStorageKey(provider);
    await _secureStore.delete(key);
    if (provider.trim().toLowerCase() == 'gemini') {
      await _secureStore.delete(intelligenceApiKeyStorageKey);
    }
  }

  Future<bool> hasKey() async {
    return hasKeyForProvider('gemini');
  }

  Future<bool> hasKeyForProvider(String provider) async {
    return (await readKeyForProvider(provider)) != null;
  }

  Future<IntelligenceCapabilityStatus> readCapabilityStatus() async {
    final configured = await hasKey();
    if (!configured) {
      return const IntelligenceCapabilityStatus(
        summaryAvailable: false,
        semanticSearchAvailable: false,
        tagSuggestionAvailable: false,
        reason: IntelligenceCapabilityReason.missingApiKey,
      );
    }

    return const IntelligenceCapabilityStatus(
      summaryAvailable: true,
      semanticSearchAvailable: true,
      tagSuggestionAvailable: true,
      reason: IntelligenceCapabilityReason.available,
    );
  }

  String _providerStorageKey(String provider) {
    final normalized = provider.trim().toLowerCase();
    if (normalized.isEmpty) {
      return '${_intelligenceApiKeyByProviderPrefix}gemini';
    }
    return '$_intelligenceApiKeyByProviderPrefix$normalized';
  }
}
