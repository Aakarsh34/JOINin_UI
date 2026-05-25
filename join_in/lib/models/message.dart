import '_helpers.dart';

class MessageSender {
  final String id;
  final String name;
  final String photo;

  const MessageSender({required this.id, required this.name, required this.photo});

  factory MessageSender.fromJson(dynamic raw) {
    if (raw is String) return MessageSender(id: raw, name: '', photo: '');
    if (raw is Map<String, dynamic>) {
      return MessageSender(
        id: (raw['_id'] ?? raw['id'] ?? '').toString(),
        name: stringFromJson(raw['name']),
        photo: stringFromJson(raw['photo']),
      );
    }
    return const MessageSender(id: '', name: '', photo: '');
  }
}

class ChatMessage {
  final String id;
  final String? sessionId;
  final String? conversationId;
  final MessageSender sender;
  final String content;
  final String contentType;
  final DateTime? createdAt;
  final DateTime? readAt;

  const ChatMessage({
    required this.id,
    this.sessionId,
    this.conversationId,
    required this.sender,
    required this.content,
    required this.contentType,
    required this.createdAt,
    this.readAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      sessionId: json['sessionId']?.toString(),
      conversationId: json['conversationId']?.toString(),
      sender: MessageSender.fromJson(json['sender']),
      content: stringFromJson(json['content']),
      contentType: stringFromJson(json['contentType'], 'text'),
      createdAt: parseIsoDate(json['createdAt']),
      readAt: parseIsoDate(json['readAt']),
    );
  }
}
