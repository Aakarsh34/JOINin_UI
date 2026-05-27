import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/session.dart';
import '../services/session_service.dart';
import '../theme.dart';
import '../widgets/shimmer.dart';
import 'session_detail.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SessionService _sessions = SessionService();
  List<Session> _allSessions = [];
  List<Session> _filtered = [];
  bool _loading = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await _sessions.list(limit: 50);
      if (!mounted) return;
      setState(() {
        _allSessions = result.items;
        _filtered = _applyQuery(result.items, _searchController.text);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  List<Session> _applyQuery(List<Session> source, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return source;
    return source.where((s) {
      return s.title.toLowerCase().contains(q) ||
          s.activityType.toLowerCase().contains(q) ||
          s.venue.name.toLowerCase().contains(q) ||
          s.venue.address.toLowerCase().contains(q);
    }).toList();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() => _filtered = _applyQuery(_allSessions, value));
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(76),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: _onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search activities, venues...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          _searchController.clear();
                          _onChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: context.cs.surfaceContainerLow,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: context.cs.outline)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: context.cs.outline)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(
                        color: AppTheme.primaryAccent, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: KeyedSubtree(
          key: ValueKey('${_loading}_${_filtered.length}'),
          child: _loading
              ? _buildSkeleton()
              : _filtered.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) =>
                            _buildResult(_filtered[index]),
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    final isInitial = _searchController.text.isEmpty;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 96),
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
                child: Icon(
                    isInitial ? Icons.search : Icons.search_off,
                    size: 48,
                    color: context.cs.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              Text(
                  isInitial
                      ? 'Find your next game'
                      : 'No matching sessions',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                isInitial
                    ? 'Search by sport, venue or city'
                    : 'Try different keywords',
                style: TextStyle(color: context.cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResult(Session session) {
    final dateLabel = session.dateTime != null
        ? DateFormat('EEE, MMM d • h:mm a').format(session.dateTime!.toLocal())
        : 'TBD';
    return Material(
      color: context.cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => SessionDetailScreen(
                      sessionId: session.id, initial: session)));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: AppTheme.secondaryAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.sports,
                    color: AppTheme.secondaryAccent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(session.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('${session.activityType} • $dateLabel',
                        style: TextStyle(
                            color: context.cs.onSurfaceVariant, fontSize: 13)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: context.cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Shimmer(
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) => Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: context.cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18)),
          child: const Row(
            children: [
              SkeletonBox(width: 48, height: 48, radius: 14),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 200, height: 14),
                    SizedBox(height: 8),
                    SkeletonBox(width: 140, height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
