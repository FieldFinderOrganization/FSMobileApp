import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();

  static const _keyAccessToken = 'accessToken';
  static const _keyRefreshToken = 'refreshToken';
  static const _keyUserId = 'userId';
  static const _keyRole = 'role';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String role,
  }) async {
    await Future.wait([
      _storage.write(key: _keyAccessToken, value: accessToken),
      _storage.write(key: _keyRefreshToken, value: refreshToken),
      _storage.write(key: _keyUserId, value: userId),
      _storage.write(key: _keyRole, value: role),
    ]);
  }

  Future<String?> getAccessToken() => _storage.read(key: _keyAccessToken);
  Future<String?> getRefreshToken() => _storage.read(key: _keyRefreshToken);
  Future<String?> getUserId() => _storage.read(key: _keyUserId);
  Future<String?> getRole() => _storage.read(key: _keyRole);

  Future<void> clearAll() => _storage.deleteAll();
}
