import '_helpers.dart';

class SessionRating {
  final String id;
  final int organizerScore;
  final int venueScore;
  final String review;
  final DateTime? createdAt;
  final String raterId;
  final String raterName;
  final String raterPhoto;

  const SessionRating({
    required this.id,
    required this.organizerScore,
    required this.venueScore,
    required this.review,
    required this.createdAt,
    required this.raterId,
    required this.raterName,
    required this.raterPhoto,
  });

  factory SessionRating.fromJson(Map<String, dynamic> json) {
    final rater = json['rater'];
    return SessionRating(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      organizerScore: intFromJson(json['organizerScore']),
      venueScore: intFromJson(json['venueScore']),
      review: stringFromJson(json['review']),
      createdAt: parseIsoDate(json['createdAt']),
      raterId: rater is Map ? (rater['_id'] ?? rater['id'] ?? '').toString() : '',
      raterName: rater is Map ? stringFromJson(rater['name']) : '',
      raterPhoto: rater is Map ? stringFromJson(rater['photo']) : '',
    );
  }
}

class RatingAggregate {
  final double avgOrganizerScore;
  final double avgVenueScore;
  final int totalRatings;

  const RatingAggregate({
    this.avgOrganizerScore = 0,
    this.avgVenueScore = 0,
    this.totalRatings = 0,
  });

  factory RatingAggregate.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RatingAggregate();
    return RatingAggregate(
      avgOrganizerScore: doubleFromJson(json['avgOrganizerScore']),
      avgVenueScore: doubleFromJson(json['avgVenueScore']),
      totalRatings: intFromJson(json['totalRatings']),
    );
  }
}
