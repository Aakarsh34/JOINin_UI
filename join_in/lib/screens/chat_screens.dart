import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
              Icon(Icons.cloud_off,
                  size: 56, color: context.cs.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                    onPressed: _load, child: const Text('Try again')),
              ),
            ],
          ),
        ),
      );
    } else if (_items.isEmpty) {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: context.cs.surfaceContainerLow),
                      child: Icon(Icons.forum_outlined,
                          size: 48, color: context.cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 20),
                    const Text('No conversations yet',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(
                      'Direct messages with other members will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.cs.onSurfaceVariant),
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
          separatorBuilder: (_, _) => Divider(
              height: 1, color: context.cs.outline, indent: 80),
          itemBuilder: (context, index) {
            final conv = _items[index];
            final other = conv.otherParticipant(currentUserId);
            final lastMessage = conv.lastMessage;
            final timeLabel = conv.lastMessageAt != null
                ? DateFormat('h:mm a')
                    .format(conv.lastMessageAt!.toLocal())
                : '';
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 8),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: context.cs.surfaceContainerHigh,
                backgroundImage: other.photo.isNotEmpty
                    ? NetworkImage(other.photo)
                    : null,
                child: other.photo.isEmpty
                    ? Text(
                        other.name.isNotEmpty
                            ? other.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(color: context.cs.onSurface))
                    : null,
              ),
              title: Text(other.name.isEmpty ? 'User' : other.name,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(
                lastMessage == null
                    ? 'Tap to chat'
                    : lastMessage.contentType == 'image'
                        ? '📷 Photo'
                        : lastMessage.content,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: conv.unreadCount > 0
                        ? context.cs.onSurface
                        : context.cs.onSurfaceVariant),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(timeLabel,
                      style: TextStyle(
                          color: conv.unreadCount > 0
                              ? AppTheme.primaryAccent
                              : context.cs.onSurfaceVariant,
                          fontSize: 12)),
                  if (conv.unreadCount > 0) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: AppTheme.primaryAccent,
                          borderRadius: BorderRadius.circular(10)),
                      child: Text('${conv.unreadCount}',
                          style: const TextStyle(
                              color: AppTheme.darkBackground,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
              onTap: () async {
                HapticFeedback.selectionClick();
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            PrivateChatScreen(conversation: conv)));
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
    SocketClient.instance
        .emit('joinSession', {'sessionId': widget.session.id});
    _joinedRoom = true;
    _load();
  }

  @override
  void dispose() {
    if (_joinedRoom) {
      SocketClient.instance
          .emit('leaveSession', {'sessionId': widget.session.id});
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
      final paginated =
          await _service.messages(widget.session.id, limit: 30);
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
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();
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
                        ? Center(
                            child: Text('Say hi to your group!',
                                style: TextStyle(
                                    color: context.cs.onSurfaceVariant)))
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
    final time = msg.createdAt == null
        ? ''
        : DateFormat('h:mm a').format(msg.createdAt!.toLocal());
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          gradient: isMe ? AppTheme.primaryGradient : null,
          color: isMe ? null : context.cs.surfaceContainerHigh,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(msg.sender.name.isEmpty ? 'Member' : msg.sender.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppTheme.secondaryAccent)),
            if (!isMe) const SizedBox(height: 4),
            Text(msg.content,
                style: TextStyle(
                    color: isMe
                        ? AppTheme.darkBackground
                        : context.cs.onSurface)),
            if (time.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(time,
                  style: TextStyle(
                      color: isMe
                          ? AppTheme.darkBackground.withValues(alpha: 0.7)
                          : context.cs.onSurfaceVariant,
                      fontSize: 10)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _inputBar() {
    return _ChatInputBar(
      controller: _controller,
      onChanged: () => setState(() {}),
      onSend: _send,
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
        if (convId == widget.conversation.id &&
            messageRaw is Map<String, dynamic>) {
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
      final paginated =
          await _service.messages(widget.conversation.id, limit: 30);
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
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();
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
              backgroundColor: context.cs.surfaceContainerHigh,
              backgroundImage:
                  other.photo.isNotEmpty ? NetworkImage(other.photo) : null,
              child: other.photo.isEmpty
                  ? Text(
                      other.name.isNotEmpty
                          ? other.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontSize: 12))
                  : null,
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
                        ? Center(
                            child: Text(
                                'Start a conversation with ${other.name}',
                                style: TextStyle(
                                    color: context.cs.onSurfaceVariant)))
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
          _ChatInputBar(
            controller: _controller,
            onChanged: () => setState(() {}),
            onSend: _send,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          gradient: isMe ? AppTheme.primaryGradient : null,
          color: isMe ? null : context.cs.surfaceContainerHigh,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
        ),
        child: Text(msg.content,
            style: TextStyle(
                color: isMe
                    ? AppTheme.darkBackground
                    : context.cs.onSurface)),
      ),
    );
  }
}

/// Shared input bar used by both group and private chat screens.
class _ChatInputBar extends StatelessWidget {
  const _ChatInputBar({
    required this.controller,
    required this.onChanged,
    required this.onSend,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.trim().isNotEmpty;
    return Container(
      color: context.cs.surfaceContainerLow,
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        10 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (_) => onChanged(),
              onSubmitted: (_) => onSend(),
              textInputAction: TextInputAction.send,
              decoration: InputDecoration(
                hintText: 'Message...',
                filled: true,
                fillColor: context.cs.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide:
                        BorderSide(color: context.cs.outline)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide:
                        BorderSide(color: context.cs.outline)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                        color: AppTheme.primaryAccent, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: hasText ? AppTheme.primaryGradient : null,
              color: hasText ? null : context.cs.surfaceContainerHigh,
              boxShadow: hasText
                  ? [
                      BoxShadow(
                          color: AppTheme.primaryAccent
                              .withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 1),
                    ]
                  : null,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.send,
                color: hasText
                    ? AppTheme.darkBackground
                    : context.cs.onSurfaceVariant,
                size: 20,
              ),
              onPressed: hasText ? onSend : null,
            ),
          ),
        ],
      ),
    );
  }
}
