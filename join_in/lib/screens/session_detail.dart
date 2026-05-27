import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/event_category.dart';
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
    final category = EventCategory.forActivity(session.activityType);
    final categoryLabel = category.id == EventCategory.other.id
        ? (session.activityType.isEmpty
            ? 'Event'
            : '${session.activityType[0].toUpperCase()}${session.activityType.substring(1)}')
        : category.label;

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
            // Themed header. Uses the category color and emoji so a music
            // event reads "music" at a glance, a hike reads "outdoors", etc.
            // No more sports-only stock photo dictating the vibe.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 320,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      category.color.withValues(alpha: 0.85),
                      category.color.withValues(alpha: 0.45),
                      context.cs.surface,
                    ],
                    stops: const [0.0, 0.55, 1.0],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 80),
                    child: Text(category.emoji,
                        style: const TextStyle(
                            fontSize: 84,
                            shadows: [
                              Shadow(blurRadius: 24, color: Colors.black38)
                            ])),
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
                            color: category.color.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(category.emoji,
                                style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(categoryLabel,
                                style: TextStyle(
                                    color: category.color,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
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
                                  'going')),
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
                          // Anyone enrolled (organizer or joined participant)
                          // gets the tappable "view enrolled people"
                          // affordance — the backend's
                          // GET /sessions/:id/participants allows any
                          // participant to read the roster, and the
                          // organizer is auto-added to participants on
                          // create, so isJoined covers both.
                          isJoined
                              ? InkWell(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    _showParticipantsSheet(session);
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Spots (${session.filledSlots}/${session.totalSlots})',
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.chevron_right,
                                          color: context.cs.onSurfaceVariant,
                                          size: 24,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : Text(
                                  'Spots (${session.filledSlots}/${session.totalSlots})',
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
                                    ? "You're hosting"
                                    : isJoined
                                        ? 'Leave event'
                                        : isWaitlisted
                                            ? 'Leave waitlist'
                                            : (isFull
                                                ? 'Join waitlist'
                                                : 'Join event'),
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

  /// Opens a modal bottom sheet that lists every enrolled participant for the
  /// session. Surfaced only for organizers (the chevron next to the "Spots"
  /// header). Fetches the participant list lazily via
  /// `GET /sessions/:id/participants` so it stays cheap when the host doesn't
  /// open it.
  void _showParticipantsSheet(Session session) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cs.surface,
      // The app theme sets `showDragHandle: true` globally on
      // BottomSheetTheme, which would draw a second, lighter grab handle
      // above our custom one. Disable it here so only our custom darker
      // handle remains.
      showDragHandle: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return _ParticipantsSheet(
          sessions: _sessions,
          session: session,
        );
      },
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

/// Bottom-sheet list of every enrolled participant for a session. Pulled into
/// its own widget so the sheet can own its own loading / error state without
/// dragging the parent screen through rebuilds.
class _ParticipantsSheet extends StatefulWidget {
  const _ParticipantsSheet({
    required this.sessions,
    required this.session,
  });

  final SessionService sessions;
  final Session session;

  @override
  State<_ParticipantsSheet> createState() => _ParticipantsSheetState();
}

class _ParticipantsSheetState extends State<_ParticipantsSheet> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.sessions.participants(widget.session.id);
  }

  Future<void> _reload() async {
    setState(() {
      _future = widget.sessions.participants(widget.session.id);
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final organizerId = session.organizer.id;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grab handle.
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.cs.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Enrolled (${session.filledSlots}/${session.totalSlots})',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(Icons.cloud_off,
                              color: context.cs.onSurfaceVariant, size: 48),
                          const SizedBox(height: 12),
                          Text(snapshot.error.toString(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: context.cs.onSurfaceVariant)),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: _reload,
                            child: const Text('Try again'),
                          ),
                        ],
                      ),
                    );
                  }
                  final participants = snapshot.data ?? const [];
                  if (participants.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text('No one has joined yet.',
                            style: TextStyle(
                                color: context.cs.onSurfaceVariant)),
                      ),
                    );
                  }
                  // Surface the host first so the organizer's own card
                  // anchors the list, then the rest in arrival order.
                  final sorted = [...participants]..sort((a, b) {
                      final aIsHost = (a['id'] ?? '') == organizerId;
                      final bIsHost = (b['id'] ?? '') == organizerId;
                      if (aIsHost && !bIsHost) return -1;
                      if (bIsHost && !aIsHost) return 1;
                      return 0;
                    });
                  return RefreshIndicator(
                    onRefresh: _reload,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      itemCount: sorted.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final p = sorted[index];
                        final id = (p['id'] ?? '').toString();
                        final name = (p['name'] ?? '').toString();
                        final photo = (p['photo'] ?? '').toString();
                        final presence =
                            (p['presence'] ?? '').toString();
                        final isHost = id == organizerId;
                        final displayName =
                            name.isEmpty ? 'Participant' : name;
                        return ListTile(
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor:
                                    context.cs.surfaceContainerHigh,
                                backgroundImage: photo.isNotEmpty
                                    ? NetworkImage(photo)
                                    : null,
                                child: photo.isEmpty
                                    ? Text(
                                        displayName[0].toUpperCase(),
                                        style: TextStyle(
                                            color: context.cs.onSurface,
                                            fontWeight: FontWeight.bold),
                                      )
                                    : null,
                              ),
                              if (presence == 'online')
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.greenAccent.shade400,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: context.cs.surface,
                                          width: 2),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Text(
                            displayName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600),
                          ),
                          trailing: isHost
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryAccent
                                        .withValues(alpha: 0.18),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Host',
                                    style: TextStyle(
                                      color: AppTheme.primaryAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                )
                              : null,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
