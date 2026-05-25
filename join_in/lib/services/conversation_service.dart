import '../core/api_client.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/paginated.dart';

class ConversationService {
  final ApiClient _api = ApiClient.instance;

  Future<Conversation> openWith(String targetUserId) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/conversations',
      body: {'targetUserId': targetUserId},
    );
    return Conversation.fromJson(data['conversation'] as Map<String, dynamic>);
  }

  Future<List<Conversation>> list() async {
    final data = await _api.get<Map<String, dynamic>>('/conversations');
    final items = (data['data'] as List?) ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(Conversation.fromJson)
        .toList();
  }

  Future<Paginated<ChatMessage>> messages(
    String conversationId, {
    String? lastMessageId,
    int limit = 30,
  }) async {
    final data = await _api.get<Map<String, dynamic>>(
      '/conversations/$conversationId/messages',
      query: {
        'limit': limit,
        if (lastMessageId != null) 'lastMessageId': lastMessageId,
      },
    );
    return Paginated.fromJson(data, (json) => ChatMessage.fromJson(json));
  }
}
