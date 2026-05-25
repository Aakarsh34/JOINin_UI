import '_helpers.dart';

class AppNotification {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      type: stringFromJson(json['type']),
      data: (json['data'] is Map<String, dynamic>)
          ? Map<String, dynamic>.from(json['data'] as Map<String, dynamic>)
          : const {},
      isRead: boolFromJson(json['isRead']),
      createdAt: parseIsoDate(json['createdAt']),
    );
  }

  String get title {
    final t = data['title']?.toString();
    if (t != null && t.isNotEmpty) return t;
    switch (type) {
      case 'SESSION_JOIN':
        return 'Someone joined your session';
      case 'SESSION_LEAVE':
        return 'A participant left';
      case 'SESSION_CANCELLED':
        return 'A session was cancelled';
      case 'JOIN_REQUEST':
        return 'New join request';
      case 'REQUEST_APPROVED':
        return 'Your join request was approved';
      case 'WAITLIST_PROMOTED':
        return 'You were promoted from waitlist';
      case 'SESSION_REMINDER':
        return 'Session reminder';
      case 'NEW_DM':
        return 'New message';
      case 'INCOMING_CALL':
        return 'Incoming call';
      case 'POST_SESSION_RATING':
        return 'Rate your recent session';
      default:
        return 'Notification';
    }
  }
}
