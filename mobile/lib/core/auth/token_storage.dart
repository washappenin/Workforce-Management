import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kTokenKey = 'aurelia.accessToken';

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(
    const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    ),
  );
});

class TokenStorage {
  TokenStorage(this._storage);
  final FlutterSecureStorage _storage;

  Future<String?> read() => _storage.read(key: _kTokenKey);
  Future<void> write(String token) =>
      _storage.write(key: _kTokenKey, value: token);
  Future<void> clear() => _storage.delete(key: _kTokenKey);
}
