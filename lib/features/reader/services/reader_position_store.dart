import 'package:shared_preferences/shared_preferences.dart';

abstract class ReaderPositionStore {
  Future<int?> readBucket(int itemId);

  Future<void> writeBucket(int itemId, int bucket);
}

class SharedPrefsReaderPositionStore implements ReaderPositionStore {
  SharedPrefsReaderPositionStore({Future<SharedPreferences>? sharedPreferences})
    : _sharedPreferences = sharedPreferences ?? SharedPreferences.getInstance();

  static const String _keyPrefix = 'reader.section.bucket.';

  final Future<SharedPreferences> _sharedPreferences;

  String _keyFor(int itemId) => '$_keyPrefix$itemId';

  @override
  Future<int?> readBucket(int itemId) async {
    final prefs = await _sharedPreferences;
    return prefs.getInt(_keyFor(itemId));
  }

  @override
  Future<void> writeBucket(int itemId, int bucket) async {
    final prefs = await _sharedPreferences;
    await prefs.setInt(_keyFor(itemId), bucket);
  }
}

class InMemoryReaderPositionStore implements ReaderPositionStore {
  final Map<int, int> _buckets = <int, int>{};

  @override
  Future<int?> readBucket(int itemId) async => _buckets[itemId];

  @override
  Future<void> writeBucket(int itemId, int bucket) async {
    _buckets[itemId] = bucket;
  }
}
