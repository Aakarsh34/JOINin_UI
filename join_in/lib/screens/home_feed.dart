import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/event_category.dart';
import '../models/session.dart';
import '../models/session_filters.dart';
import '../services/session_service.dart';
import '../theme.dart';
import '../widgets/session_filter_sheet.dart';
import '../widgets/shimmer.dart';
import 'notifications_screen.dart';
import 'session_detail.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => HomeFeedScreenState();
}

class HomeFeedScreenState extends State<HomeFeedScreen> {
  final SessionService _sessions = SessionService();
  bool _isLoading = true;
  bool _isMapView = false;
  SessionFilters _filters = SessionFilters.empty;
  List<Session> _items = [];
  String? _error;

  /// Public entry point for parents (e.g. [MainNavigationState]) to trigger a
  /// silent refresh — used after the user publishes a new session so the
  /// Home tab picks it up without flashing a shimmer.
  Future<void> refresh() => _load(silent: _items.isNotEmpty);

  /// Category chips shown above the feed.
  ///
  /// The first entry [EventCategory.all] clears the filter; the rest come
  /// straight from the shared catalog so adding a new category in one place
  /// makes it appear here, in the create flow and in search at the same time.
  static final List<EventCategory> _categoryChips = <EventCategory>[
    EventCategory.all,
    ...EventCategory.catalog,
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Loads sessions for the current filter set.
  ///
  /// When [silent] is true (e.g. on session-detail return or after publish)
  /// we keep the existing list on-screen and only swap it in once the network
  /// returns. This avoids the jarring shimmer flash users hit every time they
  /// came back to the home tab.
  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final paginated = await _sessions.list(
        activityType: _filters.activityType,
        dateFrom: _filters.dateFrom,
        dateTo: _filters.dateTo,
        skillLevel: _filters.skillLevel,
        slotsAvailable: _filters.slotsAvailable,
        limit: 50,
      );
      if (!mounted) return;
      setState(() {
        _items = _sortLocally(paginated.items, _filters.sort);
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        // On a silent refresh we keep showing the cached items and only
        // surface the error if there is nothing to show.
        if (!silent || _items.isEmpty) {
          _error = e.toString();
        }
        _isLoading = false;
      });
    }
  }

  /// Backend always returns upcoming sessions sorted ascending by `dateTime`.
  /// For the other sort modes we re-order client-side so the user gets
  /// immediate feedback without a second round-trip.
  List<Session> _sortLocally(List<Session> source, SessionSort sort) {
    final list = [...source];
    switch (sort) {
      case SessionSort.upcoming:
        list.sort((a, b) {
          final ad = a.dateTime;
          final bd = b.dateTime;
          if (ad == null && bd == null) return 0;
          if (ad == null) return 1;
          if (bd == null) return -1;
          return ad.compareTo(bd);
        });
      case SessionSort.newest:
        list.sort((a, b) {
          final ad = a.createdAt;
          final bd = b.createdAt;
          if (ad == null && bd == null) return 0;
          if (ad == null) return 1;
          if (bd == null) return -1;
          return bd.compareTo(ad);
        });
      case SessionSort.mostSlots:
        list.sort((a, b) {
          final aOpen = (a.totalSlots - a.filledSlots).clamp(0, a.totalSlots);
          final bOpen = (b.totalSlots - b.filledSlots).clamp(0, b.totalSlots);
          return bOpen.compareTo(aOpen);
        });
    }
    return list;
  }

  Future<void> _openFilterSheet() async {
    HapticFeedback.selectionClick();
    final updated = await SessionFilterSheet.show(context, initial: _filters);
    if (updated == null) return;
    if (updated == _filters) return;
    setState(() => _filters = updated);
    _load();
  }

  void _setCategory(EventCategory category) {
    final next = category.id == EventCategory.all.id ? null : category.id;
    if (next == _filters.activityType) return;
    HapticFeedback.selectionClick();
    setState(() => _filters = _filters.copyWith(activityType: next));
    _load();
  }

  void _clearAdvanced() {
    HapticFeedback.selectionClick();
    setState(() => _filters = SessionFilters(
          activityType: _filters.activityType,
          sort: _filters.sort,
        ));
    _load();
  }

  /// Which category chip should look "selected" right now. Falls back to
  /// "All" when no category filter is active.
  EventCategory get _selectedCategoryChip {
    if (_filters.activityType == null) return EventCategory.all;
    for (final c in _categoryChips) {
      if (c.id == _filters.activityType) return c;
    }
    // Unknown category (legacy data) — show no chip as selected so the user
    // can still clear the filter via the chip row.
    return EventCategory.all;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const NotificationsScreen())),
          ),
          IconButton(
            tooltip: _isMapView ? 'List view' : 'Map view',
            icon: Icon(_isMapView ? Icons.list : Icons.map_outlined,
                color: AppTheme.primaryAccent),
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() => _isMapView = !_isMapView);
            },
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(
              _filters.hasAnyAdvanced ? 100 : 54),
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    _filterButton(),
                    const SizedBox(width: 8),
                    for (final c in _categoryChips) ...[
                      _categoryChip(c,
                          selected: _selectedCategoryChip.id == c.id,
                          onTap: () => _setCategory(c)),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              if (_filters.hasAnyAdvanced) _buildActiveFilterStrip(),
            ],
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: KeyedSubtree(
          key: ValueKey(
              '${_isLoading}_${_error != null}_${_isMapView}_${_items.length}'),
          child: _isLoading
              ? _buildSkeletonLoader()
              : _error != null
                  ? _buildErrorState()
                  : (_isMapView ? _buildMapView() : _buildFeed()),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 64, color: context.cs.onSurfaceVariant),
            const SizedBox(height: 16),
            const Text('Could not load sessions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_error ?? '',
                style: TextStyle(color: context.cs.onSurfaceVariant),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                  onPressed: _load, child: const Text('Try again')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return Stack(
      children: [
        Container(
          color: context.cs.surfaceContainerLow,
          child: Center(
            child: Text('Map view coming soon',
                style: TextStyle(color: context.cs.onSurfaceVariant)),
          ),
        ),
        const Positioned(
            top: 100,
            left: 150,
            child: Icon(Icons.location_on,
                size: 48, color: AppTheme.primaryAccent)),
        const Positioned(
            top: 250,
            right: 100,
            child: Icon(Icons.location_on,
                size: 48, color: AppTheme.secondaryAccent)),
      ],
    );
  }

  Widget _buildFeed() {
    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.cs.surfaceContainerLow,
                    ),
                    child: Icon(Icons.search_off,
                        size: 48, color: context.cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),
                  Text(
                      _filters.hasAnyAdvanced ||
                              _filters.activityType != null
                          ? 'No matches for your filters'
                          : 'No events yet',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(
                      _filters.hasAnyAdvanced ||
                              _filters.activityType != null
                          ? 'Try widening the date range or clearing some filters.'
                          : 'Be the first to host one!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.cs.onSurfaceVariant)),
                  if (_filters.hasAnyAdvanced ||
                      _filters.activityType != null) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 220,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setState(
                              () => _filters = SessionFilters.empty);
                          _load();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Clear all filters'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _items.length,
        itemBuilder: (context, index) => _buildSessionCard(_items[index]),
      ),
    );
  }

  Widget _buildSessionCard(Session session) {
    final category = EventCategory.forActivity(session.activityType);
    final categoryColor = category.color;
    // Prefer the catalog's title-cased label so user-typed lowercase tags like
    // `football` still render as "Sports", and `food` shows as "Food & Drink".
    final categoryLabel = category.id == EventCategory.other.id
        ? (session.activityType.isEmpty
            ? 'Event'
            : '${session.activityType[0].toUpperCase()}${session.activityType.substring(1)}')
        : category.label;

    final dateLabel = session.dateTime != null
        ? DateFormat('EEE, MMM d • h:mm a').format(session.dateTime!.toLocal())
        : 'Time TBD';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: context.isDark
            ? [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
              ]
            : [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 6)),
              ],
      ),
      child: Material(
        color: context.cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async {
            HapticFeedback.selectionClick();
            await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => SessionDetailScreen(
                        sessionId: session.id, initial: session)));
            _load(silent: true);
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.cs.outline),
            ),
            child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 6,
                decoration: BoxDecoration(
                    color: categoryColor,
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomLeft: Radius.circular(20))),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                                color: categoryColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: [
                                Text(category.emoji,
                                    style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 4),
                                Text(categoryLabel,
                                    style: TextStyle(
                                        color: categoryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                                color: context.cs.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(12)),
                            child: Text(
                                session.skillLevel.isEmpty
                                    ? 'All levels'
                                    : session.skillLevel,
                                style: TextStyle(
                                    color: context.cs.onSurfaceVariant,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(session.title,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.place,
                              size: 14, color: context.cs.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Expanded(
                              child: Text(session.venue.name,
                                  style: TextStyle(
                                      color: context.cs.onSurfaceVariant,
                                      fontSize: 13),
                                  overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 14, color: context.cs.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(dateLabel,
                              style: TextStyle(
                                  color: context.cs.onSurfaceVariant,
                                  fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(color: context.cs.outline, height: 1),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: context.cs.surfaceContainerHigh,
                            backgroundImage:
                                session.organizer.photo.isNotEmpty
                                    ? NetworkImage(session.organizer.photo)
                                    : null,
                            child: session.organizer.photo.isEmpty
                                ? Text(
                                    session.organizer.name.isNotEmpty
                                        ? session.organizer.name[0]
                                            .toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: context.cs.onSurface),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(
                                  session.organizer.name.isEmpty
                                      ? 'Organizer'
                                      : session.organizer.name,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600))),
                          SizedBox(
                            width: 90,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                    '${session.filledSlots}/${session.totalSlots} going',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: context.cs.onSurfaceVariant)),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: session.totalSlots == 0
                                      ? 0
                                      : (session.filledSlots /
                                              session.totalSlots)
                                          .clamp(0.0, 1.0),
                                  backgroundColor:
                                      context.cs.surfaceContainerHigh,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      session.isFull
                                          ? AppTheme.danger
                                          : AppTheme.primaryAccent),
                                  borderRadius: BorderRadius.circular(4),
                                  minHeight: 4,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return Shimmer(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: 4,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.cs.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Row(
                children: [
                  SkeletonBox(width: 80, height: 22, radius: 12),
                  Spacer(),
                  SkeletonBox(width: 56, height: 22, radius: 12),
                ],
              ),
              SizedBox(height: 14),
              SkeletonBox(width: 240, height: 20),
              SizedBox(height: 10),
              SkeletonBox(width: 180, height: 12),
              SizedBox(height: 6),
              SkeletonBox(width: 120, height: 12),
              SizedBox(height: 18),
              Row(
                children: [
                  SkeletonBox(width: 24, height: 24, radius: 12),
                  SizedBox(width: 8),
                  SkeletonBox(width: 100, height: 14),
                  Spacer(),
                  SkeletonBox(width: 70, height: 14),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterButton() {
    final hasActive = _filters.hasAnyAdvanced;
    final count = _filters.advancedCount;
    return GestureDetector(
      onTap: _openFilterSheet,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: hasActive ? AppTheme.primaryGradient : null,
          color: hasActive ? null : context.cs.surfaceContainerLow,
          border: Border.all(
            color: hasActive ? Colors.transparent : context.cs.outline,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(Icons.tune,
                size: 16,
                color: hasActive
                    ? AppTheme.darkBackground
                    : context.cs.onSurface),
            const SizedBox(width: 6),
            Text('Filters',
                style: TextStyle(
                    color: hasActive
                        ? AppTheme.darkBackground
                        : context.cs.onSurface,
                    fontWeight:
                        hasActive ? FontWeight.w800 : FontWeight.w600)),
            if (hasActive) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppTheme.darkBackground.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$count',
                    style: const TextStyle(
                        color: AppTheme.darkBackground,
                        fontWeight: FontWeight.w800,
                        fontSize: 12)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Strip of dismissible pills showing every advanced filter currently
  /// applied. Each pill removes its own filter when tapped.
  Widget _buildActiveFilterStrip() {
    final pills = <Widget>[];
    if (_filters.dateFrom != null && _filters.dateTo != null) {
      final label =
          '${DateFormat('MMM d').format(_filters.dateFrom!)} – ${DateFormat('MMM d').format(_filters.dateTo!)}';
      pills.add(_activeFilterPill(
        icon: Icons.event,
        label: label,
        onRemove: () {
          HapticFeedback.selectionClick();
          setState(() => _filters =
              _filters.copyWith(dateFrom: null, dateTo: null));
          _load();
        },
      ));
    }
    if (_filters.skillLevel != null) {
      pills.add(_activeFilterPill(
        icon: Icons.bolt,
        label: _filters.skillLevel!,
        onRemove: () {
          HapticFeedback.selectionClick();
          setState(() => _filters = _filters.copyWith(skillLevel: null));
          _load();
        },
      ));
    }
    if (_filters.slotsAvailable == true) {
      pills.add(_activeFilterPill(
        icon: Icons.event_available,
        label: 'Open spots',
        onRemove: () {
          HapticFeedback.selectionClick();
          setState(
              () => _filters = _filters.copyWith(slotsAvailable: null));
          _load();
        },
      ));
    }
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 8, 12),
        children: [
          ...pills.expand((p) => [p, const SizedBox(width: 8)]),
          TextButton.icon(
            onPressed: _clearAdvanced,
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Clear'),
            style: TextButton.styleFrom(
                foregroundColor: context.cs.onSurfaceVariant,
                textStyle: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _activeFilterPill({
    required IconData icon,
    required String label,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryAccent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: AppTheme.primaryAccent.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryAccent),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.primaryAccent,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            customBorder: const CircleBorder(),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.close,
                  size: 14, color: AppTheme.primaryAccent),
            ),
          ),
        ],
      ),
    );
  }

  /// Pill-shaped chip showing a category (emoji + label). Tapping toggles the
  /// `activityType` filter on the home feed.
  Widget _categoryChip(EventCategory category,
      {required bool selected, required VoidCallback onTap}) {
    final isAll = category.id == EventCategory.all.id;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected ? AppTheme.primaryGradient : null,
          color: selected ? null : context.cs.surfaceContainerLow,
          border: Border.all(
            color: selected ? Colors.transparent : context.cs.outline,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            if (isAll)
              Icon(category.icon,
                  size: 16,
                  color: selected
                      ? AppTheme.darkBackground
                      : context.cs.onSurface)
            else
              Text(category.emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(category.label,
                style: TextStyle(
                    color: selected
                        ? AppTheme.darkBackground
                        : context.cs.onSurface,
                    fontWeight:
                        selected ? FontWeight.w800 : FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
