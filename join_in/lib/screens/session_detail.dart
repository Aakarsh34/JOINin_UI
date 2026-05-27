import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/session.dart';
import '../services/session_service.dart';
import '../state/auth_state.dart';
import '../theme.dart';
import 'chat_screens.dart';

class SessionDetailScreen extends StatefulWidget {
  final String sessionId;
  final Session? initial;

  const SessionDetailScreen(
      {super.key, required this.sessionId, this.initial});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  final SessionService _sessions = SessionService();
  Session? _session;
  bool _isLoading = false;
  bool _isMutating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _session = widget.initial;
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final fresh = await _sessions.get(widget.sessionId);
      if (!mounted) return;
      setState(() {
        _session = fresh;
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

  Future<void> _toggleMembership() async {
    final session = _session;
    final user = context.read<AuthState>().user;
    if (session == null || user == null) return;

    HapticFeedback.mediumImpact();
    setState(() => _isMutating = true);
    try {
      final updated =
          session.isParticipant(user.id) || session.isWaitlisted(user.id)
              ? await _sessions.leave(session.id)
              : await _sessions.join(session.id);
      if (!mounted) return;
      setState(() => _session = updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppTheme.danger,
        content: Text(e.toString()),
      ));
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final user = context.watch<AuthState>().user;
    if (session == null) {
      return Scaffold(
        appBar: AppBar(),
        body: _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_off,
                          size: 56, color: context.cs.onSurfaceVariant),
                      const SizedBox(height: 12),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      SizedBox(
                          width: 200,
                          child: ElevatedButton(
                              onPressed: _refresh,
                              child: const Text('Try again'))),
                    ],
                  ),
                ),
              )
            : const Center(child: CircularProgressIndicator()),
      );
    }

    final isJoined = user != null && session.isParticipant(user.id);
    final isWaitlisted = user != null && session.isWaitlisted(user.id);
    final isOrganizer = user != null && session.organizer.id == user.id;
    final isFull = session.isFull;
    final dateLabel = session.dateTime != null
        ? DateFormat('EEE, MMM d').format(session.dateTime!.toLocal())
        : 'TBD';
    final timeLabel = session.dateTime != null
        ? DateFormat('h:mm a').format(session.dateTime!.toLocal())
        : '';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              shape: BoxShape.circle),
          child: const BackButton(color: Colors.white),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 320,
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                      image: NetworkImage(
                          'https://images.unsplash.com/photo-1524661135-423995f22d0b?q=80&w=1000&auto=format&fit=crop'),
                      fit: BoxFit.cover),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        context.cs.surface,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ),
            SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.only(top: 250, bottom: 120),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: context.cs.surface,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32)),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: AppTheme.secondaryAccent
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12)),
                        child: Text(session.activityType,
                            style: const TextStyle(
                                color: AppTheme.secondaryAccent,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 16),
                      Text(session.title,
                          style:
                              Theme.of(context).textTheme.headlineLarge),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                              child: _buildInfoCard(Icons.calendar_today,
                                  dateLabel, timeLabel)),
                          const SizedBox(width: 16),
                          Expanded(
                              child: _buildInfoCard(
                                  Icons.group,
                                  '${session.filledSlots}/${session.totalSlots}',
                                  'players')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        Icons.location_on,
                        session.venue.name.isEmpty
                            ? 'TBD'
                            : session.venue.name,
                        session.distanceKm != null
                            ? '${session.distanceKm!.toStringAsFixed(1)} km away'
                            : (session.venue.address.isEmpty
                                ? ''
                                : session.venue.address),
                      ),
                      const SizedBox(height: 32),
                      const Text('Organizer',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 28,
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
                                      color: context.cs.onSurface))
                              : null,
                        ),
                        title: Text(
                            session.organizer.name.isEmpty
                                ? 'Organizer'
                                : session.organizer.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                        subtitle: session.organizer.ratingStats != null &&
                                session.organizer.ratingStats!
                                        .totalRatings >
                                    0
                            ? Row(
                                children: [
                                  const Icon(Icons.star,
                                      color: Colors.amber, size: 16),
                                  Text(
                                    ' ${session.organizer.ratingStats!.avgRating.toStringAsFixed(1)} (${session.organizer.ratingStats!.totalRatings} reviews)',
                                    style: TextStyle(
                                        color: context.cs.onSurfaceVariant),
                                  ),
                                ],
                              )
                            : Text('Tap to view profile',
                                style: TextStyle(
                                    color: context.cs.onSurfaceVariant)),
                      ),
                      const SizedBox(height: 32),
                      const Text('Details',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text(
                        session.description.isEmpty
                            ? 'No description provided.'
                            : session.description,
                        style: TextStyle(
                            color: context.cs.onSurface,
                            height: 1.6,
                            fontSize: 16),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                              'Slots (${session.filledSlots}/${session.totalSlots})',
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                          Text(
                              session.skillLevel.isEmpty
                                  ? 'All Welcome'
                                  : session.skillLevel,
                              style: const TextStyle(
                                  color: AppTheme.secondaryAccent,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(session.totalSlots, (index) {
                          final isFilled = index < session.filledSlots;
                          return AnimatedContainer(
                            duration: Duration(
                                milliseconds: 200 + (index * 30)),
                            curve: Curves.easeOutCubic,
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: isFilled
                                  ? AppTheme.primaryGradient
                                  : null,
                              color: isFilled
                                  ? null
                                  : Colors.transparent,
                              border: Border.all(
                                  color: isFilled
                                      ? Colors.transparent
                                      : context.cs.outline,
                                  width: 2),
                            ),
                            child: isFilled
                                ? const Icon(Icons.check,
                                    size: 16,
                                    color: AppTheme.darkBackground)
                                : null,
                          );
                        }),
                      ),
                      if (isJoined) ...[
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Group Chat',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)),
                            TextButton(
                              onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => GroupChatScreen(
                                          session: session))),
                              child: const Text('Open chat',
                                  style: TextStyle(
                                      color: AppTheme.primaryAccent)),
                            ),
                          ],
                        ),
                      ],
                      if (_isLoading)
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: Center(
                              child: LinearProgressIndicator(
                                  color: AppTheme.primaryAccent,
                                  backgroundColor:
                                      context.cs.surfaceContainerLow)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                        24,
                        16,
                        24,
                        16 + MediaQuery.viewPaddingOf(context).bottom),
                    decoration: BoxDecoration(
                      color: context.cs.surface.withValues(alpha: 0.85),
                      border: Border(
                          top: BorderSide(color: context.cs.outline)),
                    ),
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      child: ElevatedButton(
                        onPressed: isOrganizer || _isMutating
                            ? null
                            : _toggleMembership,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isOrganizer
                              ? context.cs.surfaceContainerHigh
                              : isJoined
                                  ? AppTheme.danger
                                  : isWaitlisted
                                      ? Colors.orangeAccent
                                      : (isFull
                                          ? Colors.orangeAccent
                                          : AppTheme.primaryAccent),
                          foregroundColor: isOrganizer
                              ? context.cs.onSurface
                              : AppTheme.darkBackground,
                        ),
                        child: _isMutating
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: AppTheme.darkBackground,
                                    strokeWidth: 3))
                            : Text(
                                isOrganizer
                                    ? "You're organizing"
                                    : isJoined
                                        ? 'Leave session'
                                        : isWaitlisted
                                            ? 'Leave waitlist'
                                            : (isFull
                                                ? 'Join waitlist'
                                                : 'Join session'),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: context.cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.cs.outline)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.secondaryAccent),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(
                  color: context.cs.onSurfaceVariant, fontSize: 12)),
        ],
      ),
    );
  }
}
