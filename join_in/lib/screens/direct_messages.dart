import 'package:flutter/material.dart';

class DirectMessagesScreen extends StatelessWidget {
  const DirectMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(icon: const Icon(Icons.edit_square), onPressed: () {}),
        ],
      ),
      body: ListView(
        children: [
          _buildMessageTile(
            context,
            name: 'Alex Johnson',
            message: 'Are you bringing the ball today?',
            time: '10:30 AM',
            unread: 2,
            avatarUrl: 'https://i.pravatar.cc/150?u=alex',
            isOnline: true,
          ),
          _buildMessageTile(
            context,
            name: 'Priya Sharma',
            message: 'Great game yesterday!',
            time: 'Yesterday',
            unread: 0,
            avatarUrl: 'https://i.pravatar.cc/150?u=priya',
            isOnline: false,
          ),
          _buildMessageTile(
            context,
            name: 'Rahul Dev',
            message: 'See you at the nets.',
            time: 'Mon',
            unread: 0,
            avatarUrl: 'https://i.pravatar.cc/150?u=rahul',
            isOnline: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageTile(BuildContext context, {
    required String name,
    required String message,
    required String time,
    required int unread,
    required String avatarUrl,
    required bool isOnline,
  }) {
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage(avatarUrl),
          ),
          if (isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).cardColor, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(
        message,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(time, style: TextStyle(color: unread > 0 ? Theme.of(context).primaryColor : Colors.grey, fontSize: 12)),
          if (unread > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                unread.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
      onTap: () {},
    );
  }
}
