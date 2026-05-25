import '_helpers.dart';
import 'user.dart';
import 'venue.dart';

class SessionOrganizer {
  final String id;
  final String name;
  final String photo;
  final RatingStats? ratingStats;

  const SessionOrganizer({
    required this.id,
    required this.name,
    required this.photo,
    this.ratingStats,
  });

  factory SessionOrganizer.fromJson(dynamic raw) {
    if (raw is String) {
      return SessionOrganizer(id: raw, name: '', photo: '');
    }
    if (raw is Map<String, dynamic>) {
      return SessionOrganizer(
        id: (raw['_id'] ?? raw['id'] ?? '').toString(),
        name: stringFromJson(raw['name']),
        photo: stringFromJson(raw['photo']),
        ratingStats: raw['ratingStats'] is Map<String, dynamic>
            ? RatingStats.fromJson(raw['ratingStats'] as Map<String, dynamic>)
            : null,
      );
    }
    return const SessionOrganizer(id: '', name: '', photo: '');
  }
}

class Session {
  final String id;
  final String title;
  final String activityType;
  final Venue venue;
  final SessionOrganizer organizer;
  final DateTime? dateTime;
  final int totalSlots;
  final int minPlayers;
  final List<String> participantIds;
  final List<String> waitlistIds;
  final String status;
  final String skillLevel;
  final String description;
  final bool isPublic;
  final int? slotsRemaining;
  final double? distanceKm;
  final double? recommendationScore;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Session({
    required this.id,
    required this.title,
    required this.activityType,
    required this.venue,
    required this.organizer,
    required this.dateTime,
    required this.totalSlots,
    required this.minPlayers,
    required this.participantIds,
    required this.waitlistIds,
    required this.status,
    required this.skillLevel,
    required this.description,
    required this.isPublic,
    this.slotsRemaining,
    this.distanceKm,
    this.recommendationScore,
    this.createdAt,
    this.updatedAt,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    final participants = (json['participants'] is List)
        ? (json['participants'] as List)
            .map(extractId)
            .whereType<String>()
            .toList()
        : <String>[];
    final waitlist = (json['waitlist'] is List)
        ? (json['waitlist'] as List)
            .map((entry) {
              if (entry is Map && entry['user'] != null) {
                return extractId(entry['user']);
              }
              return extractId(entry);
            })
            .whereType<String>()
            .toList()
        : <String>[];
    return Session(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: stringFromJson(json['title']),
      activityType: stringFromJson(json['activityType']),
      venue: Venue.fromJson(json['venue'] as Map<String, dynamic>?),
      organizer: SessionOrganizer.fromJson(json['organizer']),
      dateTime: parseIsoDate(json['dateTime']),
      totalSlots: intFromJson(json['totalSlots']),
      minPlayers: intFromJson(json['minPlayers']),
      participantIds: participants,
      waitlistIds: waitlist,
      status: stringFromJson(json['status'], 'open'),
      skillLevel: stringFromJson(json['skillLevel']),
      description: stringFromJson(json['description']),
      isPublic: boolFromJson(json['isPublic'], true),
      slotsRemaining: json['slotsRemaining'] == null
          ? null
          : intFromJson(json['slotsRemaining']),
      distanceKm: json['distanceKm'] == null
          ? null
          : doubleFromJson(json['distanceKm']),
      recommendationScore: json['recommendationScore'] == null
          ? null
          : doubleFromJson(json['recommendationScore']),
      createdAt: parseIsoDate(json['createdAt']),
      updatedAt: parseIsoDate(json['updatedAt']),
    );
  }

  int get filledSlots =>
      slotsRemaining != null ? (totalSlots - slotsRemaining!).clamp(0, totalSlots) : participantIds.length;

  bool isParticipant(String userId) => participantIds.contains(userId);
  bool isWaitlisted(String userId) => waitlistIds.contains(userId);
  bool get isFull => filledSlots >= totalSlots;
}
