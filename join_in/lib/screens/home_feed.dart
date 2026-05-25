import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/session.dart';
import '../services/session_service.dart';
import '../theme.dart';
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
        activityType: _selectedFilter == 'All' ? null : _selectedFilter.toLowerCase(),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDarkElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filters', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              const Text('Coming soon — date, skill level, and distance filters will be applied to the backend query.', style: TextStyle(color: AppTheme.textMuted)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
              const SizedBox(height: 24),
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
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
          IconButton(
            icon: Icon(_isMapView ? Icons.list : Icons.map_outlined, color: AppTheme.primaryAccent),
            onPressed: () => setState(() => _isMapView = !_isMapView),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                GestureDetector(onTap: _showFilterSheet, child: _buildFilterChip('Filters', Icons.filter_list, false)),
                const SizedBox(width: 8),
                for (final f in const ['All', 'Football', 'Cricket', 'Badminton', 'Basketball', 'Tennis', 'Pickleball']) ...[
                  GestureDetector(
                    onTap: () {
                      setState(() => _selectedFilter = f);
                      _load();
                    },
                    child: _buildFilterChip(f, null, _selectedFilter == f),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? _buildSkeletonLoader()
          : _error != null
              ? _buildErrorState()
              : (_isMapView ? _buildMapView() : _buildFeed()),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            const Text('Could not load sessions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_error ?? '', style: const TextStyle(color: AppTheme.textMuted), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return Stack(
      children: [
        Container(
          color: const Color(0xFF1E232A),
          child: const Center(child: Text('Map View Active', style: TextStyle(color: AppTheme.textMuted))),
        ),
        const Positioned(top: 100, left: 150, child: Icon(Icons.location_on, size: 48, color: AppTheme.primaryAccent)),
        const Positioned(top: 250, right: 100, child: Icon(Icons.location_on, size: 48, color: AppTheme.secondaryAccent)),
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
                  Icon(Icons.search_off, size: 80, color: Colors.grey.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  const Text('No sessions yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Be the first to host one!', style: TextStyle(color: AppTheme.textMuted)),
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
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        itemBuilder: (context, index) => _buildSessionCard(_items[index]),
      ),
    );
  }

  Widget _buildSessionCard(Session session) {
    Color sportColor = AppTheme.secondaryAccent;
    final lc = session.activityType.toLowerCase();
    if (lc == 'football') sportColor = Colors.greenAccent;
    if (lc == 'basketball') sportColor = Colors.orangeAccent;
    if (lc == 'cricket') sportColor = Colors.blueAccent;

    final dateLabel = session.dateTime != null
        ? DateFormat('EEE, MMM d • h:mm a').format(session.dateTime!.toLocal())
        : 'Time TBD';

    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => SessionDetailScreen(sessionId: session.id, initial: session)));
        _load();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 8, decoration: BoxDecoration(color: sportColor, borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)))),
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
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: sportColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: [
                                Text(_getSportEmoji(session.activityType), style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 4),
                                Text(session.activityType, style: TextStyle(color: sportColor, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                            child: Text(session.skillLevel.isEmpty ? 'All' : session.skillLevel, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(session.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.place, size: 14, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Expanded(child: Text(session.venue.name, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 14, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(dateLabel, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white10, height: 1),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: AppTheme.cardDarkElevated,
                            backgroundImage: session.organizer.photo.isNotEmpty ? NetworkImage(session.organizer.photo) : null,
                            child: session.organizer.photo.isEmpty
                                ? Text(
                                    session.organizer.name.isNotEmpty ? session.organizer.name[0].toUpperCase() : '?',
                                    style: const TextStyle(fontSize: 10, color: AppTheme.textLight),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(session.organizer.name.isEmpty ? 'Organizer' : session.organizer.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                          SizedBox(
                            width: 90,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${session.filledSlots}/${session.totalSlots} joined', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: session.totalSlots == 0 ? 0 : (session.filledSlots / session.totalSlots).clamp(0.0, 1.0),
                                  backgroundColor: Colors.white10,
                                  valueColor: AlwaysStoppedAnimation<Color>(session.isFull ? Colors.redAccent : AppTheme.primaryAccent),
                                  borderRadius: BorderRadius.circular(4),
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
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 24),
        height: 180,
        decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData? icon, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryAccent : Colors.transparent,
        border: Border.all(color: isSelected ? AppTheme.primaryAccent : Colors.white24),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          if (icon != null) ...[Icon(icon, size: 16, color: isSelected ? AppTheme.darkBackground : Colors.white), const SizedBox(width: 4)],
          Text(label, style: TextStyle(color: isSelected ? AppTheme.darkBackground : Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
