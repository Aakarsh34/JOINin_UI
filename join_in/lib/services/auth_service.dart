import '../core/api_client.dart';
import '../core/token_storage.dart';
import '../models/user.dart';

class VerifyOtpResult {
  final String accessToken;
  final String refreshToken;
  final AppUser user;

  const VerifyOtpResult({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });
}

class AuthService {
  final ApiClient _api = ApiClient.instance;

  Future<int> sendOtp(String phone) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/auth/send-otp',
      body: {'phone': phone},
    );
    return (data['expiresin'] ?? data['expiresIn'] ?? 300) as int;
  }

  Future<VerifyOtpResult> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/auth/verify-otp',
      body: {'phone': phone, 'otp': otp},
    );
    final result = VerifyOtpResult(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      user: AppUser.fromJson(data['user'] as Map<String, dynamic>),
    );
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
