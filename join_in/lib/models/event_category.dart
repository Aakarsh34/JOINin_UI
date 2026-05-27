import 'package:flutter/material.dart';

/// A curated catalog of event categories that the app supports.
///
/// `activityType` on the backend is a free-form string (length-validated only).
/// Surfacing a small, opinionated catalog here gives the UI consistent icons,
/// colors and emoji across the home feed, search, create flow and session
/// detail without forcing the backend schema to change. Any future category
/// can be added in one place and will appear everywhere.
@immutable
class EventCategory {
  const EventCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.emoji,
  });

  /// Lowercase tag stored on the session (`activityType`).
  final String id;

  /// Title-cased label for chips, badges and dropdowns.
  final String label;

  /// Outlined icon used in chips and cards.
  final IconData icon;

  /// Accent color used on the card's left rail and category badge.
  final Color color;

  /// Emoji rendered next to the label for a light, friendly touch.
  final String emoji;

  /// "All" is a synthetic chip used by the home feed and filter strip to
  /// represent "no category selected"; it is not a real backend value.
  static const EventCategory all = EventCategory(
    id: 'all',
    label: 'All',
    icon: Icons.apps_outlined,
    color: Color(0xFF9CA3AF),
    emoji: '✨',
  );

  /// Generic fallback used when an event's `activityType` is not in the
  /// curated catalog (e.g. user-typed custom categories).
  static const EventCategory other = EventCategory(
    id: 'other',
    label: 'Other',
    icon: Icons.event_outlined,
    color: Color(0xFF94A3B8),
    emoji: '🎈',
  );

  /// The catalog the UI surfaces. Order matters — chips render in this order.
  static const List<EventCategory> catalog = <EventCategory>[
    EventCategory(
      id: 'sports',
      label: 'Sports',
      icon: Icons.sports_soccer_outlined,
      color: Color(0xFF34D399),
      emoji: '⚽',
    ),
    EventCategory(
      id: 'music',
      label: 'Music',
      icon: Icons.music_note_outlined,
      color: Color(0xFFF472B6),
      emoji: '🎵',
    ),
    EventCategory(
      id: 'outdoors',
      label: 'Outdoors',
      icon: Icons.terrain_outlined,
      color: Color(0xFF60A5FA),
      emoji: '🏞️',
    ),
    EventCategory(
      id: 'food',
      label: 'Food & Drink',
      icon: Icons.restaurant_outlined,
      color: Color(0xFFFB923C),
      emoji: '🍽️',
    ),
    EventCategory(
      id: 'tech',
      label: 'Tech',
      icon: Icons.memory_outlined,
      color: Color(0xFFA78BFA),
      emoji: '💻',
    ),
    EventCategory(
      id: 'gaming',
      label: 'Gaming',
      icon: Icons.sports_esports_outlined,
      color: Color(0xFF22D3EE),
      emoji: '🎮',
    ),
    EventCategory(
      id: 'wellness',
      label: 'Wellness',
      icon: Icons.self_improvement_outlined,
      color: Color(0xFF34D399),
      emoji: '🧘',
    ),
    EventCategory(
      id: 'arts',
      label: 'Arts',
      icon: Icons.palette_outlined,
      color: Color(0xFFFDE68A),
      emoji: '🎨',
    ),
    EventCategory(
      id: 'learning',
      label: 'Learning',
      icon: Icons.school_outlined,
      color: Color(0xFF818CF8),
      emoji: '📚',
    ),
    EventCategory(
      id: 'social',
      label: 'Social',
      icon: Icons.celebration_outlined,
      color: Color(0xFFEC4899),
      emoji: '🎉',
    ),
    EventCategory(
      id: 'volunteer',
      label: 'Volunteer',
      icon: Icons.volunteer_activism_outlined,
      color: Color(0xFFEF4444),
      emoji: '🤝',
    ),
    EventCategory(
      id: 'travel',
      label: 'Travel',
      icon: Icons.flight_takeoff_outlined,
      color: Color(0xFF38BDF8),
      emoji: '✈️',
    ),
    other,
  ];

  /// Look up the catalog entry for an arbitrary `activityType` string. Falls
  /// back to [other] when the tag doesn't match any catalog entry, so the UI
  /// always has a sensible icon/color to render.
  factory EventCategory.forActivity(String? activityType) {
    if (activityType == null || activityType.isEmpty) return other;
    final lc = activityType.toLowerCase();
    for (final c in catalog) {
      if (c.id == lc) return c;
    }
    // Legacy / pre-pivot data: map old sport tags into the Sports category so
    // existing sessions keep their nice green tint instead of being demoted
    // to "Other".
    const sportSynonyms = {
      'football',
      'basketball',
      'cricket',
      'tennis',
      'pickleball',
      'badminton',
      'soccer',
      'volleyball',
      'baseball',
      'hockey',
      'rugby',
    };
    if (sportSynonyms.contains(lc)) {
      return catalog.firstWhere((c) => c.id == 'sports');
    }
    return other;
  }
}
