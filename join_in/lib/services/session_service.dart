import '../core/api_client.dart';
import '../models/message.dart';
import '../models/paginated.dart';
import '../models/rating.dart';
import '../models/session.dart';

class SessionService {
  final ApiClient _api = ApiClient.instance;

  Future<Paginated<Session>> list({
    double? lat,
    double? lng,
    double? radiusKm,
    String? activityType,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? skillLevel,
    bool? slotsAvailable,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (radiusKm != null) 'radiusKm': radiusKm,
      if (activityType != null && activityType.isNotEmpty) 'activityType': activityType,
      if (dateFrom != null) 'dateFrom': dateFrom.toUtc().toIso8601String(),
      if (dateTo != null) 'dateTo': dateTo.toUtc().toIso8601String(),
      if (skillLevel != null) 'skillLevel': skillLevel,
      if (slotsAvailable != null) 'slotsAvailable': slotsAvailable,
      if (status != null) 'status': status,
    };
    final data = await _api.get<Map<String, dynamic>>('/sessions', query: query);
    return Paginated.fromJson(data, (json) => Session.fromJson(json));
  }

  Future<List<Session>> mine() async {
    final data = await _api.get<Map<String, dynamic>>('/sessions/mine');
    final sessions = (data['sessions'] as List?) ?? const [];
    return sessions
        .whereType<Map<String, dynamic>>()
        .map((j) => Session.fromJson(j))
        .toList();
  }

  Future<Paginated<Session>> recommended({double? lat, double? lng, int page = 1, int limit = 20}) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
    };
    final data = await _api.get<Map<String, dynamic>>('/sessions/recommended', query: query);
    return Paginated.fromJson(data, (json) => Session.fromJson(json));
  }

  Future<Session> create(Map<String, dynamic> body) async {
    final data = await _api.post<Map<String, dynamic>>('/sessions', body: body);
    return Session.fromJson(data['session'] as Map<String, dynamic>);
  }

  Future<Session> get(String sessionId) async {
    final data = await _api.get<Map<String, dynamic>>('/sessions/$sessionId');
    return Session.fromJson(data['session'] as Map<String, dynamic>);
  }

  Future<Session> update(String sessionId, Map<String, dynamic> body) async {
    final data = await _api.patch<Map<String, dynamic>>('/sessions/$sessionId', body: body);
    return Session.fromJson(data['session'] as Map<String, dynamic>);
  }

  Future<Session> cancel(String sessionId) async {
    final data = await _api.delete<Map<String, dynamic>>('/sessions/$sessionId');
    return Session.fromJson(data['session'] as Map<String, dynamic>);
  }

  Future<Session> join(String sessionId) async {
    final data = await _api.post<Map<String, dynamic>>('/sessions/$sessionId/join', body: {});
    return Session.fromJson(data['session'] as Map<String, dynamic>);
  }

  Future<Session> leave(String sessionId) async {
    final data = await _api.post<Map<String, dynamic>>('/sessions/$sessionId/leave', body: {});
    return Session.fromJson(data['session'] as Map<String, dynamic>);
  }

  Future<void> attend(String sessionId) async {
    await _api.post<Map<String, dynamic>>('/sessions/$sessionId/attend', body: {});
  }

  Future<SessionRating> rate(String sessionId, {
    required int organizerScore,
    required int venueScore,
    String review = '',
  }) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/sessions/$sessionId/rate',
      body: {
        'organizerScore': organizerScore,
        'venueScore': venueScore,
        if (review.isNotEmpty) 'review': review,
      },
    );
    return SessionRating.fromJson(data['rating'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> ratings(String sessionId) async {
    return _api.get<Map<String, dynamic>>('/sessions/$sessionId/ratings');
  }

  Future<List<Map<String, dynamic>>> waitlist(String sessionId) async {
    final data = await _api.get<Map<String, dynamic>>('/sessions/$sessionId/waitlist');
    return ((data['waitlist'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Future<Paginated<ChatMessage>> messages(String sessionId, {String? lastMessageId, int limit = 30}) async {
    final data = await _api.get<Map<String, dynamic>>(
      '/sessions/$sessionId/messages',
      query: {
        'limit': limit,
        if (lastMessageId != null) 'lastMessageId': lastMessageId,
      },
    );
    return Paginated.fromJson(data, (json) => ChatMessage.fromJson(json));
  }

  Future<List<Map<String, dynamic>>> participants(String sessionId) async {
    final data = await _api.get<Map<String, dynamic>>('/sessions/$sessionId/participants');
    return ((data['participants'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
  }
}
