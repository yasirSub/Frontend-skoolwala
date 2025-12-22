import 'package:flutter/material.dart';

import '../../../shared/services/session_manager.dart';
import '../../../shared/theme/app_theme.dart';
import '../../profile/mailbox/models/mailbox_message.dart';
import '../../profile/mailbox/models/mailbox_reply.dart';
import '../../profile/mailbox/models/mailbox_thread.dart';
import '../../profile/mailbox/services/mailbox_api_service.dart';

class ChatThreadScreen extends StatefulWidget {
  final String title;

  // roleId-userId for the peer, for display/consistency.
  final String peerKey;

  // Existing thread
  final int? messageId;

  // New chat
  final int? receiverRoleId;
  final int? receiverId;

  const ChatThreadScreen({
    super.key,
    required this.title,
    required this.peerKey,
    this.messageId,
    this.receiverRoleId,
    this.receiverId,
  });

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final MailboxApiService _service = MailboxApiService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  bool _loading = true;
  bool _sending = false;
  String? _error;

  MailboxThread? _thread;
  int? _messageId;

  late final String _activeUser;

  @override
  void initState() {
    super.initState();
    final auth = SessionManager.instance.getAuthBody();
    final roleId = auth['role_id']?.toString() ?? '';
    final userId = auth['user_id']?.toString() ?? '';
    _activeUser = '$roleId-$userId';

    _messageId = widget.messageId;

    if (_messageId != null && _messageId! > 0) {
      _loadThread();
    } else {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadThread() async {
    final messageId = _messageId;
    if (messageId == null || messageId <= 0) return;

    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final thread = await _service.getMessageThread(messageId: messageId);

      // Mark as read if I'm the receiver and it is unread.
      if (thread.message.receiver == _activeUser &&
          thread.message.readStatus == 0) {
        // ignore: unawaited_futures
        _service.markMessageAsRead(messageId: messageId);
      }

      if (!mounted) return;
      setState(() {
        _thread = thread;
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
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  bool _isMeForRoot(MailboxMessage root) {
    return root.sender == _activeUser;
  }

  bool _isMeForReply(MailboxMessage root, MailboxReply reply) {
    final activeUserIsRootSender = root.sender == _activeUser;

    // reply.identity is relative to root sender:
    // - identity=1 => root sender replied
    // - identity=0 => root receiver replied
    if (activeUserIsRootSender) return reply.identity == 1;
    return reply.identity == 0;
  }

  String _stripHtml(String input) {
    return input.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  String _timeLabel(String raw) {
    if (raw.isEmpty) return '';
    final idx = raw.indexOf(' ');
    if (idx != -1 && raw.length >= idx + 6) {
      return raw.substring(idx + 1, idx + 6);
    }
    return '';
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      // If this is a new chat, create the root message first.
      if (_messageId == null || _messageId! <= 0) {
        final roleId = widget.receiverRoleId;
        final receiverId = widget.receiverId;
        if (roleId == null || receiverId == null) {
          throw Exception('Receiver not selected');
        }

        final newId = await _service.sendMessage(
          receiverRoleId: roleId,
          receiverId: receiverId,
          subject: 'Chat',
          body: text,
        );

        _messageId = newId;
        _controller.clear();
        await _loadThread();
      } else {
        await _service.replyMessage(messageId: _messageId!, body: text);
        _controller.clear();
        await _loadThread();
      }

      if (!mounted) return;
      setState(() {
        _sending = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.primaryPurple,
        foregroundColor: Colors.white,
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            onPressed: _messageId == null ? null : _loadThread,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryPurple,
                      ),
                    ),
                  )
                : _error != null
                ? _buildError(context)
                : _buildMessages(context),
          ),
          _buildComposer(context),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 52,
              color: Colors.grey,
            ),
            const SizedBox(height: 10),
            Text('Unable to load chat', style: AppTheme.headingSmall),
            const SizedBox(height: 6),
            Text(
              _error ?? 'Unknown error',
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            ElevatedButton(onPressed: _loadThread, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildMessages(BuildContext context) {
    final thread = _thread;

    if (thread == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Start a new chat by sending a message.',
            style: AppTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final items = <_ChatItem>[
      _ChatItem(
        body: _stripHtml(thread.message.body),
        createdAt: thread.message.createdAt,
        isMe: _isMeForRoot(thread.message),
      ),
      ...thread.replies.map(
        (r) => _ChatItem(
          body: _stripHtml(r.body),
          createdAt: r.createdAt,
          isMe: _isMeForReply(thread.message, r),
        ),
      ),
    ];

    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _ChatBubble(
          text: item.body,
          time: _timeLabel(item.createdAt),
          isMe: item.isMe,
        );
      },
    );
  }

  Widget _buildComposer(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: 12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                hintText: 'Type a message…',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 46,
            width: 46,
            child: ElevatedButton(
              onPressed: _sending ? null : _send,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatItem {
  final String body;
  final String createdAt;
  final bool isMe;

  const _ChatItem({
    required this.body,
    required this.createdAt,
    required this.isMe,
  });
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final String time;
  final bool isMe;

  const _ChatBubble({
    required this.text,
    required this.time,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isMe
        ? AppTheme.primaryPurple.withOpacity(0.92)
        : Theme.of(context).cardColor;
    final fg = isMe
        ? Colors.white
        : Theme.of(context).textTheme.bodyMedium?.color;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: fg,
                height: 1.25,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (time.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                time,
                style: TextStyle(
                  color: (fg ?? Colors.black54).withOpacity(0.75),
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
