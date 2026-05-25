import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage._();
  static final TokenStorage instance = TokenStorage._();

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _userIdKey = 'user_id';

  // flutter_secure_storage 10.x stores values with custom AES ciphers on
  // Android by default (Jetpack Security's EncryptedSharedPreferences was
  // deprecated upstream), so we only customise the iOS Keychain options.
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  String? _accessTokenCache;
  String? _refreshTokenCache;

  String? get accessToken => _accessTokenCache;
  String? get refreshToken => _refreshTokenCache;

  Future<void> hydrate() async {
    _accessTokenCache = await _storage.read(key: _accessKey);
    _refreshTokenCache = await _storage.read(key: _refreshKey);
  }

  Future<void> save({
    required String accessToken,
    required String refreshToken,
    String? userId,
  }) async {
    _accessTokenCache = accessToken;
    _refreshTokenCache = refreshToken;
    await Future.wait([
      _storage.write(key: _accessKey, value: accessToken),
      _storage.write(key: _refreshKey, value: refreshToken),
      if (userId != null) _storage.write(key: _userIdKey, value: userId),
    ]);
  }

  Future<void> clear() async {
    _accessTokenCache = null;
    _refreshTokenCache = null;
    await Future.wait([
      _storage.delete(key: _accessKey),
      _storage.delete(key: _refreshKey),
      _storage.delete(key: _userIdKey),
    ]);
  }

  Future<String?> readUserId() => _storage.read(key: _userIdKey);
}
