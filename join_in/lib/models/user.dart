import '_helpers.dart';

class UserStats {
  final int hostedCount;
  final int joinedCount;
  final int completedCount;

  const UserStats({
    this.hostedCount = 0,
    this.joinedCount = 0,
    this.completedCount = 0,
  });

  factory UserStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const UserStats();
    return UserStats(
      hostedCount: intFromJson(json['hostedCount']),
      joinedCount: intFromJson(json['joinedCount']),
      completedCount: intFromJson(json['completedCount']),
    );
  }
}

class RatingStats {
  final double avgRating;
  final int totalRatings;

  const RatingStats({this.avgRating = 0, this.totalRatings = 0});

  factory RatingStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RatingStats();
    return RatingStats(
      avgRating: doubleFromJson(json['avgRating']),
      totalRatings: intFromJson(json['totalRatings']),
    );
  }
}

class AppUser {
  final String id;
  final String? phone;
  final String? email;
  final String? googleId;
  final String authProvider;
  final String name;
  final String photo;
  final String bio;
  final List<String> activities;
  final Map<String, String> skillLevels;
  final String privacySetting;
  final UserStats stats;
  final RatingStats ratingStats;
  final bool isAdmin;
  final bool isActive;
  final bool canCreateSessions;

  const AppUser({
    required this.id,
    this.phone,
    this.email,
    this.googleId,
    this.authProvider = 'phone',
    this.name = '',
    this.photo = '',
    this.bio = '',
    this.activities = const [],
    this.skillLevels = const {},
    this.privacySetting = 'public',
    this.stats = const UserStats(),
    this.ratingStats = const RatingStats(),
    this.isAdmin = false,
    this.isActive = true,
    this.canCreateSessions = true,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      googleId: json['googleId']?.toString(),
      authProvider: stringFromJson(json['authProvider'], 'phone'),
      name: stringFromJson(json['name']),
      photo: stringFromJson(json['photo']),
      bio: stringFromJson(json['bio']),
      activities: stringListFromJson(json['activities']),
      skillLevels: (json['skillLevels'] is Map)
          ? (json['skillLevels'] as Map)
              .map((k, v) => MapEntry(k.toString(), v.toString()))
          : const {},
      privacySetting: stringFromJson(json['privacySetting'], 'public'),
      stats: UserStats.fromJson(json['stats'] as Map<String, dynamic>?),
      ratingStats:
          RatingStats.fromJson(json['ratingStats'] as Map<String, dynamic>?),
      isAdmin: boolFromJson(json['isAdmin']),
      isActive: boolFromJson(json['isActive'], true),
      canCreateSessions: boolFromJson(json['canCreateSessions'], true),
    );
  }

  String get displayName {
    if (name.isNotEmpty) return name;
    if (email != null && email!.isNotEmpty) return email!;
    if (phone != null && phone!.isNotEmpty) return phone!;
    return 'User';
  }
}
