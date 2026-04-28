import 'package:flutter/material.dart';
import '../dummy_data.dart';
import '../theme.dart';

class DirectMessagesScreen extends StatelessWidget {
  const DirectMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: ListView.builder(
        itemCount: dummyUsers.length,
        itemBuilder: (context, index) {
          final user = dummyUsers[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            leading: CircleAvatar(radius: 28, backgroundImage: NetworkImage(user.avatar)),
            title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            subtitle: Text('Tap to chat with ${user.name}...', style: const TextStyle(color: AppTheme.textMuted)),
            trailing: const Icon(Icons.chevron_right, color: Colors.white24),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PrivateChatScreen(user: user))),
          );
        },
      ),
    );
  }
}

class GroupChatScreen extends StatefulWidget {
  final Session session;
  const GroupChatScreen({super.key, required this.session});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = List.from(dummyGroupChat);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.session.title)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final showTime = index == 0 || _messages[index-1].senderId != msg.senderId;
                return Column(
                  children: [
                    if (showTime) Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(msg.time, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12))),
                    _buildMessageBubble(msg),
                  ],
                );
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: msg.isMe ? AppTheme.primaryAccent : AppTheme.cardDarkElevated,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isMe ? 16 : 4),
            bottomRight: Radius.circular(msg.isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!msg.isMe) Text(msg.senderName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.secondaryAccent)),
            if (!msg.isMe) const SizedBox(height: 4),
            Text(msg.text, style: TextStyle(color: msg.isMe ? AppTheme.darkBackground : AppTheme.textLight, fontSize: 16, fontWeight: msg.isMe ? FontWeight.w500 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32), // extra padding for bottom safe area
      color: AppTheme.cardDark,
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.add_photo_alternate, color: AppTheme.textMuted), onPressed: () {}),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: (val) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Message...',
                hintStyle: const TextStyle(color: AppTheme.textMuted),
                filled: true,
                fillColor: AppTheme.darkBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            backgroundColor: _controller.text.isNotEmpty ? AppTheme.primaryAccent : AppTheme.cardDarkElevated,
            child: IconButton(
              icon: Icon(Icons.send, color: _controller.text.isNotEmpty ? AppTheme.darkBackground : AppTheme.textMuted, size: 20),
              onPressed: _controller.text.isNotEmpty ? () {
                setState(() {
                  _messages.add(ChatMessage(id: DateTime.now().toString(), senderId: currentUser.id, senderName: currentUser.name, text: _controller.text, time: 'Now', isMe: true));
                  _controller.clear();
                });
              } : null,
            ),
          ),
        ],
      ),
    );
  }
}

class PrivateChatScreen extends StatefulWidget {
  final User user;
  const PrivateChatScreen({super.key, required this.user});

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.user.name)),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty ? Center(child: Text('Start a conversation with ${widget.user.name}', style: const TextStyle(color: AppTheme.textMuted))) : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(color: AppTheme.primaryAccent, borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16), bottomLeft: Radius.circular(16), bottomRight: Radius.circular(4))),
                    child: Text(msg.text, style: const TextStyle(color: AppTheme.darkBackground, fontSize: 16, fontWeight: FontWeight.w500)),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            color: AppTheme.cardDark,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onChanged: (val) => setState(() {}),
                    decoration: InputDecoration(hintText: 'Message...', filled: true, fillColor: AppTheme.darkBackground, border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 20)),
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  backgroundColor: _controller.text.isNotEmpty ? AppTheme.primaryAccent : AppTheme.cardDarkElevated,
                  child: IconButton(
                    icon: Icon(Icons.send, color: _controller.text.isNotEmpty ? AppTheme.darkBackground : AppTheme.textMuted, size: 20),
                    onPressed: _controller.text.isNotEmpty ? () {
                      setState(() {
                        _messages.add(ChatMessage(id: DateTime.now().toString(), senderId: currentUser.id, senderName: currentUser.name, text: _controller.text, time: 'Now', isMe: true));
                        _controller.clear();
                      });
                    } : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
