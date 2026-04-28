import 'package:flutter/material.dart';
import '../dummy_data.dart';
import '../theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Mark all read', style: TextStyle(color: AppTheme.primaryAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: dummyNotifications.length,
        itemBuilder: (context, index) {
          final notif = dummyNotifications[index];
          final isRead = notif['isRead'] as bool;
          
          return Dismissible(
            key: Key(notif['title']),
            background: Container(
              color: Colors.redAccent,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: isRead ? Colors.transparent : AppTheme.primaryAccent.withOpacity(0.05),
                border: Border(left: BorderSide(color: _getBorderColor(notif['type']), width: 4)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                title: Text(notif['title'], style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold, fontSize: 16)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(notif['time'], style: const TextStyle(color: AppTheme.textMuted)),
                ),
                trailing: isRead ? null : Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppTheme.primaryAccent, shape: BoxShape.circle)),
                onTap: () {},
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getBorderColor(String type) {
    if (type == 'join') return AppTheme.primaryAccent;
    if (type == 'message') return AppTheme.secondaryAccent;
    if (type == 'rating') return Colors.amber;
    if (type == 'cancel') return Colors.redAccent;
    return Colors.grey;
  }
}
