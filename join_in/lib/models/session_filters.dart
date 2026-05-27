import 'package:flutter/foundation.dart';

/// Immutable bag of filters applied to `GET /sessions` from the home feed.
///
/// The activity chip row above the feed is captured by [activityType]; the
/// "Filters" bottom sheet edits everything else. Keeping these in a single
/// value class makes it trivial to count the number of active filters and to
/// reset them with a single call to [empty].
@immutable
class SessionFilters {
  const SessionFilters({
    this.activityType,
    this.dateFrom,
    this.dateTo,
    this.skillLevel,
    this.slotsAvailable,
    this.sort = SessionSort.upcoming,
  });

  /// Lowercase activity tag (`football`, `cricket`, ...) or `null` for "All".
  final String? activityType;

  final DateTime? dateFrom;
  final DateTime? dateTo;

  /// `Beginner | Intermediate | Advanced` or null for any.
  final String? skillLevel;

  /// When true, only show sessions that still have free slots.
  final bool? slotsAvailable;

  /// How to sort the result locally (the backend already sorts upcoming first).
  final SessionSort sort;

  static const SessionFilters empty = SessionFilters();

  /// Counts only the "advanced" filters — the activity chips and sort are
  /// surfaced separately in the UI so they don't bump this badge.
  int get advancedCount {
    var count = 0;
    if (dateFrom != null || dateTo != null) count++;
    if (skillLevel != null) count++;
    if (slotsAvailable == true) count++;
    return count;
  }

  bool get hasAnyAdvanced => advancedCount > 0;

  SessionFilters copyWith({
    Object? activityType = _sentinel,
    Object? dateFrom = _sentinel,
    Object? dateTo = _sentinel,
    Object? skillLevel = _sentinel,
    Object? slotsAvailable = _sentinel,
    SessionSort? sort,
  }) {
    return SessionFilters(
      activityType: identical(activityType, _sentinel)
          ? this.activityType
          : activityType as String?,
      dateFrom:
          identical(dateFrom, _sentinel) ? this.dateFrom : dateFrom as DateTime?,
      dateTo: identical(dateTo, _sentinel) ? this.dateTo : dateTo as DateTime?,
      skillLevel: identical(skillLevel, _sentinel)
          ? this.skillLevel
          : skillLevel as String?,
      slotsAvailable: identical(slotsAvailable, _sentinel)
          ? this.slotsAvailable
          : slotsAvailable as bool?,
      sort: sort ?? this.sort,
    );
  }

  static const _sentinel = Object();
}

enum SessionSort {
  /// Soonest start time first (default, matches backend ordering).
  upcoming,

  /// Latest created first, useful to see brand-new sessions.
  newest,

  /// Most slots remaining first.
  mostSlots,
}

extension SessionSortX on SessionSort {
  String get label {
    switch (this) {
      case SessionSort.upcoming:
        return 'Upcoming first';
      case SessionSort.newest:
        return 'Newest first';
      case SessionSort.mostSlots:
        return 'Most slots open';
    }
  }
}
