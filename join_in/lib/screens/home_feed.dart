import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/session.dart';
import '../services/session_service.dart';
import '../theme.dart';
import '../widgets/shimmer.dart';
import 'notifications_screen.dart';
import 'session_detail.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  final SessionService _sessions = SessionService();
  bool _isLoading = true;
  bool _isMapView = false;
  String _selectedFilter = 'All';
  List<Session> _items = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final paginated = await _sessions.list(
        activityType:
            _selectedFilter == 'All' ? null : _selectedFilter.toLowerCase(),
        limit: 30,
      );
      if (!mounted) return;
      setState(() {
        _items = paginated.items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showFilterSheet() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filters',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              Text(
                  'Coming soon — date, skill level and distance filters will be applied to the backend query.',
                  style: TextStyle(
                      color: context.cs.onSurfaceVariant, height: 1.5)),
              const SizedBox(height: 20),
              ElevatedButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Close')),
            ],
          ),
        );
      },
    );
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
          preferredSize: const Size.fromHeight(54),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                _filterChip('Filters',
                    icon: Icons.tune, selected: false, onTap: _showFilterSheet),
                const SizedBox(width: 8),
                for (final f in const [
                  'All',
                  'Football',
                  'Cricket',
                  'Badminton',
                  'Basketball',
                  'Tennis',
                  'Pickleball'
                ]) ...[
                  _filterChip(f,
                      selected: _selectedFilter == f,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedFilter = f);
                        _load();
                      }),
                  const SizedBox(width: 8),
                ],
              ],
            ),
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
                  const Text('No sessions yet',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text('Be the first to host one!',
                      style: TextStyle(color: context.cs.onSurfaceVariant)),
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
    final lc = session.activityType.toLowerCase();
    Color sportColor = AppTheme.secondaryAccent;
    if (lc == 'football') sportColor = const Color(0xFF34D399);
    if (lc == 'basketball') sportColor = const Color(0xFFFB923C);
    if (lc == 'cricket') sportColor = const Color(0xFF60A5FA);
    if (lc == 'tennis') sportColor = const Color(0xFFFDE68A);
    if (lc == 'pickleball') sportColor = const Color(0xFFF472B6);
    if (lc == 'badminton') sportColor = const Color(0xFFA78BFA);

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
            _load();
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
                    color: sportColor,
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
                                color: sportColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: [
                                Text(_getSportEmoji(session.activityType),
                                    style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 4),
                                Text(session.activityType,
                                    style: TextStyle(
                                        color: sportColor,
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
                                    '${session.filledSlots}/${session.totalSlots} joined',
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

  String _getSportEmoji(String type) {
    switch (type.toLowerCase()) {
      case 'football':
        return '⚽';
      case 'badminton':
        return '🏸';
      case 'cricket':
        return '🏏';
      case 'basketball':
        return '🏀';
      case 'tennis':
        return '🎾';
      case 'pickleball':
        return '🏓';
      default:
        return '🏅';
    }
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

  Widget _filterChip(String label,
      {IconData? icon,
      required bool selected,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            if (icon != null) ...[
              Icon(icon,
                  size: 16,
                  color: selected
                      ? AppTheme.darkBackground
                      : context.cs.onSurface),
              const SizedBox(width: 6),
            ],
            Text(label,
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
