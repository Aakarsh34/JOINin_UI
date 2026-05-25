import '../core/api_client.dart';
import '../core/token_storage.dart';
import '../models/user.dart';

class LoginResult {
  final String accessToken;
  final String refreshToken;
  final AppUser user;

  const LoginResult({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class AuthService {
  final ApiClient _api = ApiClient.instance;

  Future<LoginResult> loginWithPhone({
    required String phone,
    String? name,
  }) async {
    final body = <String, dynamic>{'phone': phone};
    if (name != null && name.isNotEmpty) {
      body['name'] = name;
    }
    final data = await _api.post<Map<String, dynamic>>(
      '/auth/login/phone',
      body: body,
    );
    final result = LoginResult.fromJson(data);
    await TokenStorage.instance.save(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
      userId: result.user.id,
    );
    return result;
  }

  Future<LoginResult> loginWithGoogle({required String idToken}) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/auth/login/google',
      body: {'idToken': idToken},
    );
    final result = LoginResult.fromJson(data);
    await TokenStorage.instance.save(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
      userId: result.user.id,
    );
    return result;
  }

  Future<void> logout({bool clearFcmToken = true}) async {
    final refreshToken = TokenStorage.instance.refreshToken;
    if (refreshToken != null) {
      try {
        await _api.post<Map<String, dynamic>>(
          '/auth/logout',
          body: {
            'refreshToken': refreshToken,
            'clearFcmToken': clearFcmToken,
          },
        );
      } catch (_) {}
    }
    await TokenStorage.instance.clear();
  }
}
