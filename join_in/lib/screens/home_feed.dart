import 'package:flutter/material.dart';
import '../dummy_data.dart';
import '../theme.dart';
import 'session_detail.dart';
import 'notifications_screen.dart';
import 'dart:ui';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  bool _isLoading = true;
  bool _isMapView = false;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _isLoading = false);
    });
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
              const Text('Distance (km)', style: TextStyle(color: AppTheme.textMuted)),
              Slider(value: 5.0, min: 1, max: 20, activeColor: AppTheme.primaryAccent, onChanged: (v) {}),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Apply Filters')),
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
                GestureDetector(onTap: () => setState(() => _selectedFilter = 'All'), child: _buildFilterChip('All', null, _selectedFilter == 'All')),
                const SizedBox(width: 8),
                GestureDetector(onTap: () => setState(() => _selectedFilter = 'Football'), child: _buildFilterChip('Football', null, _selectedFilter == 'Football')),
                const SizedBox(width: 8),
                GestureDetector(onTap: () => setState(() => _selectedFilter = 'Badminton'), child: _buildFilterChip('Badminton', null, _selectedFilter == 'Badminton')),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading ? _buildSkeletonLoader() : (_isMapView ? _buildMapView() : _buildFeed()),
    );
  }

  Widget _buildMapView() {
    return Stack(
      children: [
        Container(
          color: const Color(0xFF1E232A),
          child: const Center(child: Text('Map View Active', style: TextStyle(color: AppTheme.textMuted))),
        ),
        Positioned(
          top: 100, left: 150,
          child: Icon(Icons.location_on, size: 48, color: AppTheme.primaryAccent),
        ),
        Positioned(
          top: 250, right: 100,
          child: Icon(Icons.location_on, size: 48, color: AppTheme.secondaryAccent),
        ),
      ],
    );
  }

  Widget _buildFeed() {
    final results = dummySessions.where((s) => _selectedFilter == 'All' || s.activityType == _selectedFilter).toList();
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text('No sessions found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) => _buildSessionCard(results[index]),
    );
  }

  Widget _buildSessionCard(Session session) {
    Color sportColor = AppTheme.secondaryAccent;
    if (session.activityType == 'Football') sportColor = Colors.greenAccent;
    if (session.activityType == 'Basketball') sportColor = Colors.orangeAccent;
    if (session.activityType == 'Cricket') sportColor = Colors.blueAccent;
    
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SessionDetailScreen(session: session))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
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
                            decoration: BoxDecoration(color: sportColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
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
                            child: Text(session.skillLevel, style: const TextStyle(color: Colors.white70, fontSize: 12)),
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
                          Expanded(child: Text(session.venueName, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 14, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(session.dateTime, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white10, height: 1),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          CircleAvatar(radius: 12, backgroundImage: NetworkImage(session.organizer.avatar)),
                          const SizedBox(width: 8),
                          Text(session.organizer.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 4),
                          const Icon(Icons.star, size: 12, color: Colors.amber),
                          Text('${session.organizer.rating}', style: const TextStyle(fontSize: 12, color: Colors.amber)),
                          const Spacer(),
                          // Slot Tracker Progress Bar
                          SizedBox(
                            width: 80,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${session.filledSlots}/${session.totalSlots} joined', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: session.filledSlots / session.totalSlots,
                                  backgroundColor: Colors.white10,
                                  valueColor: AlwaysStoppedAnimation<Color>(session.filledSlots >= session.totalSlots ? Colors.redAccent : AppTheme.primaryAccent),
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
    switch (type) {
      case 'Football': return '⚽';
      case 'Badminton': return '🏸';
      case 'Cricket': return '🏏';
      case 'Basketball': return '🏀';
      case 'Tennis': return '🎾';
      case 'Pickleball': return '🏓';
      default: return '🏅';
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
