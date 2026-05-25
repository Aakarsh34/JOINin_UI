import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../models/user.dart';

class UserService {
  final ApiClient _api = ApiClient.instance;

  Future<AppUser> getMe() async {
    final data = await _api.get<Map<String, dynamic>>('/users/me');
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<AppUser> updateMe({
    String? name,
    String? bio,
    List<String>? activities,
    Map<String, String>? skillLevels,
    String? privacySetting,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (bio != null) body['bio'] = bio;
    if (activities != null) body['activities'] = activities;
    if (skillLevels != null) body['skillLevels'] = skillLevels;
    if (privacySetting != null) body['privacySetting'] = privacySetting;
    final data = await _api.patch<Map<String, dynamic>>('/users/me', body: body);
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<AppUser> uploadPhoto({required String filePath, String? filename}) async {
    final form = FormData.fromMap({
      'photo': await MultipartFile.fromFile(filePath, filename: filename),
    });
    final data = await _api.postMultipart<Map<String, dynamic>>('/users/me/photo', form);
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<AppUser> updateFcmToken(String fcmToken) async {
    final data = await _api.patch<Map<String, dynamic>>(
      '/users/me/fcm-token',
      body: {'fcmToken': fcmToken},
    );
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getNotificationPreferences() async {
    final data = await _api.get<Map<String, dynamic>>('/users/me/notification-preferences');
    return Map<String, dynamic>.from(
        data['notificationPreferences'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> updateNotificationPreferences(
      Map<String, dynamic> partial) async {
    final data = await _api.patch<Map<String, dynamic>>(
      '/users/me/notification-preferences',
      body: partial,
    );
    return Map<String, dynamic>.from(
        data['notificationPreferences'] as Map<String, dynamic>);
  }

  Future<void> deactivate() async {
    await _api.post<Map<String, dynamic>>('/users/me/deactivate', body: {});
  }

  Future<Map<String, dynamic>> getMyStats() async {
    return _api.get<Map<String, dynamic>>('/users/me/stats');
  }

  Future<AppUser> getUser(String userId) async {
    final data = await _api.get<Map<String, dynamic>>('/users/$userId');
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<bool> getPresence(String userId) async {
    final data = await _api.get<Map<String, dynamic>>('/users/$userId/presence');
    return data['online'] == true;
  }

  Future<Map<String, dynamic>> getUserRatings(String userId) async {
    return _api.get<Map<String, dynamic>>('/users/$userId/ratings');
  }

  Future<Map<String, dynamic>> getUserStats(String userId) async {
    return _api.get<Map<String, dynamic>>('/users/$userId/stats');
  }
}
