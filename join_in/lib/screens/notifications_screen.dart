import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/notification.dart';
import '../services/notification_service.dart';
import '../theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _service = NotificationService();
  List<AppNotification> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _service.list(limit: 50);
      if (!mounted) return;
      setState(() {
        _items = result.items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    HapticFeedback.selectionClick();
    try {
      await _service.markAllRead();
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: const Text('Mark all read',
                style: TextStyle(
                    color: AppTheme.primaryAccent,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(_error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: context.cs.onSurfaceVariant))))
              : _items.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        itemCount: _items.length,
                        separatorBuilder: (_, _) => Divider(
                            color: context.cs.outline, height: 1),
                        itemBuilder: (context, index) =>
                            _buildTile(_items[index]),
                      ),
                    ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
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
                    color: context.cs.surfaceContainerLow),
                child: Icon(Icons.notifications_none,
                    size: 48, color: context.cs.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              const Text('All caught up',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('You have no notifications yet',
                  style: TextStyle(color: context.cs.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTile(AppNotification notif) {
    final isRead = notif.isRead;
    final timeLabel = notif.createdAt != null
        ? DateFormat('MMM d • h:mm a').format(notif.createdAt!.toLocal())
        : '';
    return Dismissible(
      key: ValueKey(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppTheme.danger,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) async {
        HapticFeedback.mediumImpact();
        try {
          await _service.markRead(notif.id);
        } catch (_) {}
        setState(() => _items.removeWhere((n) => n.id == notif.id));
      },
      child: Container(
        decoration: BoxDecoration(
          color: isRead
              ? Colors.transparent
              : AppTheme.primaryAccent.withValues(alpha: 0.06),
          border: Border(
              left: BorderSide(color: _borderColor(notif.type), width: 4)),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          title: Text(notif.title,
              style: TextStyle(
                  fontWeight: isRead ? FontWeight.w500 : FontWeight.w800,
                  fontSize: 16)),
          subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(timeLabel,
                  style: TextStyle(color: context.cs.onSurfaceVariant))),
          trailing: isRead
              ? null
              : Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                      color: AppTheme.primaryAccent, shape: BoxShape.circle)),
          onTap: () async {
            if (isRead) return;
            HapticFeedback.selectionClick();
            try {
              await _service.markRead(notif.id);
              await _load();
            } catch (_) {}
          },
        ),
      ),
    );
  }

  Color _borderColor(String type) {
    switch (type) {
      case 'SESSION_JOIN':
      case 'REQUEST_APPROVED':
      case 'WAITLIST_PROMOTED':
        return AppTheme.primaryAccent;
      case 'NEW_DM':
      case 'INCOMING_CALL':
        return AppTheme.secondaryAccent;
      case 'POST_SESSION_RATING':
        return Colors.amber;
      case 'SESSION_CANCELLED':
        return AppTheme.danger;
      default:
        return Colors.grey;
    }
  }
}
