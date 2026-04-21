import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();

  static const _keyAccessToken = 'accessToken';
  static const _keyRefreshToken = 'refreshToken';
  static const _keyUserId = 'userId';
  static const _keyRole = 'role';

  // In-memory cache
  String? _accessToken;
  String? _refreshToken;
  String? _userId;
  String? _role;

  Future<void>? _initFuture;

  Future<void> _init() {
    _initFuture ??= () async {
      // Đọc tuần tự từng key thay vì Future.wait để tránh
      // deadlock của Android Keystore khi đọc đồng thời quá nhiều.
      _accessToken = await _storage.read(key: _keyAccessToken);
      _refreshToken = await _storage.read(key: _keyRefreshToken);
      _userId = await _storage.read(key: _keyUserId);
      _role = await _storage.read(key: _keyRole);
    }();
    return _initFuture!;
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String role,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _userId = userId;
    _role = role;

    await Future.wait([
      _storage.write(key: _keyAccessToken, value: accessToken),
      _storage.write(key: _keyRefreshToken, value: refreshToken),
      _storage.write(key: _keyUserId, value: userId),
      _storage.write(key: _keyRole, value: role),
    ]);
  }

  Future<String?> getAccessToken() async {
    await _init();
    return _accessToken;
  }

  Future<String?> getRefreshToken() async {
    await _init();
    return _refreshToken;
  }

  Future<String?> getUserId() async {
    await _init();
    return _userId;
  }

  Future<String?> getRole() async {
    await _init();
    return _role;
  }

  Future<void> clearAll() async {
    _accessToken = null;
    _refreshToken = null;
    _userId = null;
    _role = null;
    await _storage.deleteAll();
  }
}

