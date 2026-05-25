import '_helpers.dart';
import 'message.dart';

class ConversationParticipant {
  final String id;
  final String name;
  final String photo;

  const ConversationParticipant({required this.id, required this.name, required this.photo});

  factory ConversationParticipant.fromJson(dynamic raw) {
    if (raw is String) return ConversationParticipant(id: raw, name: '', photo: '');
    if (raw is Map<String, dynamic>) {
      return ConversationParticipant(
        id: (raw['_id'] ?? raw['id'] ?? '').toString(),
        name: stringFromJson(raw['name']),
        photo: stringFromJson(raw['photo']),
      );
    }
    return const ConversationParticipant(id: '', name: '', photo: '');
  }
}

class Conversation {
  final String id;
  final List<ConversationParticipant> participants;
  final ChatMessage? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  const Conversation({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final participants = (json['participants'] is List)
        ? (json['participants'] as List)
            .map(ConversationParticipant.fromJson)
            .toList()
        : <ConversationParticipant>[];
    return Conversation(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      participants: participants,
      lastMessage: json['lastMessage'] is Map<String, dynamic>
          ? ChatMessage.fromJson(json['lastMessage'] as Map<String, dynamic>)
          : null,
      lastMessageAt: parseIsoDate(json['lastMessageAt']),
      unreadCount: intFromJson(json['unreadCount']),
    );
  }

  ConversationParticipant otherParticipant(String currentUserId) {
    return participants.firstWhere(
      (p) => p.id != currentUserId,
      orElse: () => participants.isNotEmpty
          ? participants.first
          : const ConversationParticipant(id: '', name: '', photo: ''),
    );
  }
}
