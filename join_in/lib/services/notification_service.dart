import '../core/api_client.dart';
import '../models/notification.dart';
import '../models/paginated.dart';

class NotificationService {
  final ApiClient _api = ApiClient.instance;

  Future<Paginated<AppNotification>> list({
    bool unreadOnly = false,
    int page = 1,
    int limit = 20,
  }) async {
    final data = await _api.get<Map<String, dynamic>>(
      '/notifications',
      query: {'unreadOnly': unreadOnly, 'page': page, 'limit': limit},
    );
    return Paginated.fromJson(data, (json) => AppNotification.fromJson(json));
  }

  Future<AppNotification> markRead(String notificationId) async {
    final data = await _api.patch<Map<String, dynamic>>(
      '/notifications/$notificationId/read',
    );
    return AppNotification.fromJson(data['notification'] as Map<String, dynamic>);
  }

  Future<int> markAllRead() async {
    final data = await _api.patch<Map<String, dynamic>>('/notifications/read-all');
    return (data['modifiedCount'] ?? 0) as int;
  }

  Future<int> unreadCount() async {
    final data = await _api.get<Map<String, dynamic>>('/notifications/unread-count');
    return (data['count'] ?? 0) as int;
  }
}
