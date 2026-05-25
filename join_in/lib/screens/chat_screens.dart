import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/socket_client.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/session.dart';
import '../services/conversation_service.dart';
import '../services/session_service.dart';
import '../state/auth_state.dart';
import '../theme.dart';

class DirectMessagesScreen extends StatefulWidget {
  const DirectMessagesScreen({super.key});

  @override
  State<DirectMessagesScreen> createState() => _DirectMessagesScreenState();
}

class _DirectMessagesScreenState extends State<DirectMessagesScreen> {
  final ConversationService _service = ConversationService();
  List<Conversation> _items = [];
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
      final items = await _service.list();
      if (!mounted) return;
      setState(() {
        _items = items;
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

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthState>().user;
    final currentUserId = user?.id ?? '';

    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 56, color: AppTheme.textMuted),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: const Text('Try again')),
            ],
          ),
        ),
      );
    } else if (_items.isEmpty) {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Icon(Icons.forum_outlined, size: 64, color: AppTheme.textMuted),
                    SizedBox(height: 16),
                    Text('No conversations yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text(
                      'Direct messages with other players will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          itemCount: _items.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white10, indent: 80),
          itemBuilder: (context, index) {
            final conv = _items[index];
            final other = conv.otherParticipant(currentUserId);
            final lastMessage = conv.lastMessage;
            final timeLabel = conv.lastMessageAt != null
                ? DateFormat('h:mm a').format(conv.lastMessageAt!.toLocal())
                : '';
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.cardDarkElevated,
                backgroundImage: other.photo.isNotEmpty ? NetworkImage(other.photo) : null,
                child: other.photo.isEmpty
                    ? Text(other.name.isNotEmpty ? other.name[0].toUpperCase() : '?', style: const TextStyle(color: AppTheme.textLight))
                    : null,
              ),
              title: Text(other.name.isEmpty ? 'User' : other.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                lastMessage == null
                    ? 'Tap to chat'
                    : lastMessage.contentType == 'image'
                        ? '📷 Photo'
                        : lastMessage.content,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: conv.unreadCount > 0 ? AppTheme.textLight : AppTheme.textMuted),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(timeLabel, style: TextStyle(color: conv.unreadCount > 0 ? AppTheme.primaryAccent : AppTheme.textMuted, fontSize: 12)),
                  if (conv.unreadCount > 0) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppTheme.primaryAccent, borderRadius: BorderRadius.circular(10)),
                      child: Text('${conv.unreadCount}', style: const TextStyle(color: AppTheme.darkBackground, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => PrivateChatScreen(conversation: conv)));
                _load();
              },
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: body,
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
  final SessionService _service = SessionService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  List<ChatMessage> _messages = [];
  bool _loading = true;
  String? _error;
  late void Function(dynamic) _onSocketMessage;
  bool _joinedRoom = false;

  @override
  void initState() {
    super.initState();
    _onSocketMessage = (raw) {
      if (!mounted) return;
      if (raw is Map<String, dynamic>) {
        final msg = ChatMessage.fromJson(raw);
        if (msg.sessionId == widget.session.id) {
          setState(() => _messages = [..._messages, msg]);
          _scrollToBottom();
        }
      }
    };
    SocketClient.instance.on('message', _onSocketMessage);
    SocketClient.instance.emit('joinSession', {'sessionId': widget.session.id});
    _joinedRoom = true;
    _load();
  }

  @override
  void dispose() {
    if (_joinedRoom) {
      SocketClient.instance.emit('leaveSession', {'sessionId': widget.session.id});
    }
    SocketClient.instance.off('message', _onSocketMessage);
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final paginated = await _service.messages(widget.session.id, limit: 30);
      if (!mounted) return;
      setState(() {
        _messages = paginated.items.reversed.toList();
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    SocketClient.instance.emit('sendMessage', {
      'sessionId': widget.session.id,
      'content': text,
      'contentType': 'text',
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthState>().user;
    final currentUserId = user?.id ?? '';
    return Scaffold(
      appBar: AppBar(title: Text(widget.session.title)),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _messages.isEmpty
                        ? const Center(child: Text('Say hi to your group!', style: TextStyle(color: AppTheme.textMuted)))
                        : ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final msg = _messages[index];
                              final isMe = msg.sender.id == currentUserId;
                              return _bubble(msg, isMe);
                            },
                          ),
          ),
          _inputBar(),
        ],
      ),
    );
  }

  Widget _bubble(ChatMessage msg, bool isMe) {
    final time = msg.createdAt == null ? '' : DateFormat('h:mm a').format(msg.createdAt!.toLocal());
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primaryAccent : AppTheme.cardDarkElevated,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(msg.sender.name.isEmpty ? 'Member' : msg.sender.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.secondaryAccent)),
            if (!isMe) const SizedBox(height: 4),
            Text(msg.content, style: TextStyle(color: isMe ? AppTheme.darkBackground : AppTheme.textLight)),
            if (time.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(time, style: TextStyle(color: isMe ? AppTheme.darkBackground.withValues(alpha: 0.7) : AppTheme.textMuted, fontSize: 10)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      color: AppTheme.cardDark,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _send(),
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
              onPressed: _controller.text.isNotEmpty ? _send : null,
            ),
          ),
        ],
      ),
    );
  }
}

class PrivateChatScreen extends StatefulWidget {
  final Conversation conversation;
  const PrivateChatScreen({super.key, required this.conversation});

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  final ConversationService _service = ConversationService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  List<ChatMessage> _messages = [];
  bool _loading = true;
  String? _error;
  late void Function(dynamic) _onNewDm;

  @override
  void initState() {
    super.initState();
    _onNewDm = (raw) {
      if (!mounted) return;
      if (raw is Map<String, dynamic>) {
        final convId = raw['conversationId']?.toString();
        final messageRaw = raw['message'];
        if (convId == widget.conversation.id && messageRaw is Map<String, dynamic>) {
          final msg = ChatMessage.fromJson(messageRaw);
          setState(() => _messages = [..._messages, msg]);
          _scrollToBottom();
        }
      }
    };
    SocketClient.instance.on('newDM', _onNewDm);
    _load();
  }

  @override
  void dispose() {
    SocketClient.instance.off('newDM', _onNewDm);
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final paginated = await _service.messages(widget.conversation.id, limit: 30);
      if (!mounted) return;
      setState(() {
        _messages = paginated.items.reversed.toList();
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    SocketClient.instance.emit('sendDM', {
      'conversationId': widget.conversation.id,
      'content': text,
      'contentType': 'text',
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthState>().user;
    final currentUserId = user?.id ?? '';
    final other = widget.conversation.otherParticipant(currentUserId);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.cardDarkElevated,
              backgroundImage: other.photo.isNotEmpty ? NetworkImage(other.photo) : null,
              child: other.photo.isEmpty ? Text(other.name.isNotEmpty ? other.name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 12)) : null,
            ),
            const SizedBox(width: 12),
            Text(other.name.isEmpty ? 'User' : other.name),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _messages.isEmpty
                        ? Center(child: Text('Start a conversation with ${other.name}', style: const TextStyle(color: AppTheme.textMuted)))
                        : ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final msg = _messages[index];
                              final isMe = msg.sender.id == currentUserId;
                              return _bubble(msg, isMe);
                            },
                          ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            color: AppTheme.cardDark,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'Message...',
                      hintStyle: const TextStyle(color: AppTheme.textMuted),
                      filled: true,
                      fillColor: AppTheme.darkBackground,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  backgroundColor: _controller.text.isNotEmpty ? AppTheme.primaryAccent : AppTheme.cardDarkElevated,
                  child: IconButton(
                    icon: Icon(Icons.send, color: _controller.text.isNotEmpty ? AppTheme.darkBackground : AppTheme.textMuted, size: 20),
                    onPressed: _controller.text.isNotEmpty ? _send : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(ChatMessage msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primaryAccent : AppTheme.cardDarkElevated,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Text(msg.content, style: TextStyle(color: isMe ? AppTheme.darkBackground : AppTheme.textLight)),
      ),
    );
  }
}
