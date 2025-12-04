import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalStorage {
  factory LocalStorage() => _instance;
  LocalStorage._internal();
  static final LocalStorage _instance = LocalStorage._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Write a value
  Future<void> write({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }

  // Read a value
  Future<String?> read({required String key}) async {
    return _storage.read(key: key);
  }

  // Delete a value
  Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
  }

  // Delete multiple values
  Future<void> deleteAllKeys(List<String> keys) async {
    for (final key in keys) {
      await _storage.delete(key: key);
    }
  }

  // Read all values
  Future<Map<String, String>> readAll() async {
    return _storage.readAll();
  }

  // Clear all storage
  Future<void> clear() async {
    await _storage.deleteAll();
  }
}
