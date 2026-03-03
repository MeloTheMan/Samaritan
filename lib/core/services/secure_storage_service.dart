import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService(this._storage);

  Future<void> saveEncrypted(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> readEncrypted(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> deleteEncrypted(String key) async {
    await _storage.delete(key: key);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
