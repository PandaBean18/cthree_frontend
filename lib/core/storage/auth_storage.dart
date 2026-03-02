import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  static const _storage = FlutterSecureStorage();

  // Keys
  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyJti = 'jti';

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String jti
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
    await _storage.write(key: _keyJti, value: jti);
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  static Future<String?> getJti() async {
    return await _storage.read(key: _keyJti);
  }

  static Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}