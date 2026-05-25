import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/session.dart';
import '../services/session_service.dart';
import '../theme.dart';
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
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: 'Search activities, venues...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 80, color: Colors.grey.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text(_searchController.text.isEmpty ? 'Find your next game' : 'No matching sessions', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final session = _filtered[index];
                      final dateLabel = session.dateTime != null
                          ? DateFormat('EEE, MMM d • h:mm a').format(session.dateTime!.toLocal())
                          : 'TBD';
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        tileColor: Theme.of(context).cardColor,
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppTheme.secondaryAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.sports, color: AppTheme.secondaryAccent),
                        ),
                        title: Text(session.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${session.activityType} • $dateLabel'),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => SessionDetailScreen(sessionId: session.id, initial: session)));
                        },
                      );
                    },
                  ),
                ),
    );
  }
}
