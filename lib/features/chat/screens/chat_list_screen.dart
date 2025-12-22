import 'package:flutter/material.dart';

import '../../../shared/services/session_manager.dart';
import '../../../shared/theme/app_theme.dart';
import '../../profile/mailbox/models/mailbox_message.dart';
import '../../profile/mailbox/models/mailbox_recipient.dart';
import '../../profile/mailbox/services/mailbox_api_service.dart';
import 'chat_thread_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final MailboxApiService _service = MailboxApiService();

  bool _loading = true;
  String? _error;

  late final String _activeUser;

  List<_ChatConversation> _conversations = const [];

  // roleId -> (recipientId -> recipient)
  final Map<int, Map<int, MailboxRecipient>> _recipientsByRole = {};

  @override
  void initState() {
    super.initState();
    final auth = SessionManager.instance.getAuthBody();
    final roleId = auth['role_id']?.toString() ?? '';
    final userId = auth['user_id']?.toString() ?? '';
    _activeUser = '$roleId-$userId';
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final inboxFuture = _service.getMessages(box: 'inbox');
      final sentFuture = _service.getMessages(box: 'sent');

      final results = await Future.wait([inboxFuture, sentFuture]);
      final inbox = results[0];
      final sent = results[1];

      final all = <_MessageWithBox>[
        ...inbox.map((m) => _MessageWithBox(message: m, box: 'inbox')),
        ...sent.map((m) => _MessageWithBox(message: m, box: 'sent')),
      ];

      // Group by the other party (role-user)
      final byPeer = <String, List<_MessageWithBox>>{};
      for (final mwb in all) {
        final peer = _peerKey(mwb.message);
        (byPeer[peer] ??= []).add(mwb);
      }

      final conversations = byPeer.entries.map((entry) {
        final peerKey = entry.key;
        final messages = entry.value;

        messages.sort((a, b) => _compareMessageTimeDesc(a.message, b.message));
        final latest = messages.first;

        final unreadCount = messages.where((mwb) => _isUnread(mwb)).length;

        return _ChatConversation(
          peerKey: peerKey,
          latestMessage: latest.message,
          latestBox: latest.box,
          unreadCount: unreadCount,
        );
      }).toList();

      conversations.sort(
        (a, b) => _compareMessageTimeDesc(a.latestMessage, b.latestMessage),
      );

      // Fetch recipients for any roleIds we see, so we can display names.
      final roleIdsToFetch = <int>{};
      for (final c in conversations) {
        final parsed = _parsePeerKey(c.peerKey);
        if (parsed != null) roleIdsToFetch.add(parsed.roleId);
      }

      await _primeRecipients(roleIdsToFetch);

      if (!mounted) return;
      setState(() {
        _conversations = conversations;
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

  Future<void> _primeRecipients(Set<int> roleIds) async {
    final missing = roleIds.where((r) => !_recipientsByRole.containsKey(r));
    if (missing.isEmpty) return;

    for (final roleId in missing) {
      try {
        final recipients = await _service.getRecipients(roleId: roleId);
        _recipientsByRole[roleId] = {for (final r in recipients) r.id: r};
      } catch (_) {
        // If recipients API fails, we still show fallback peerKey.
        _recipientsByRole[roleId] = const {};
      }
    }
  }

  String _peerKey(MailboxMessage message) {
    if (message.sender == _activeUser) return message.receiver;
    return message.sender;
  }

  _PeerId? _parsePeerKey(String peerKey) {
    final parts = peerKey.split('-');
    if (parts.length != 2) return null;
    final roleId = int.tryParse(parts[0]);
    final userId = int.tryParse(parts[1]);
    if (roleId == null || userId == null) return null;
    return _PeerId(roleId: roleId, userId: userId);
  }

  String _peerDisplayName(String peerKey) {
    final parsed = _parsePeerKey(peerKey);
    if (parsed == null) return peerKey;

    final roleMap = _recipientsByRole[parsed.roleId];
    final name = roleMap?[parsed.userId]?.name;
    if (name != null && name.trim().isNotEmpty) return name.trim();

    return 'User ${parsed.userId}';
  }

  bool _isUnread(_MessageWithBox mwb) {
    final m = mwb.message;

    // If I'm the receiver: unread is read_status=0
    if (m.receiver == _activeUser) {
      return m.readStatus == 0;
    }

    // If I'm the sender: unread reply is reply_status=1
    if (m.sender == _activeUser) {
      return m.replyStatus == 1;
    }

    return false;
  }

  int _compareMessageTimeDesc(MailboxMessage a, MailboxMessage b) {
    final at = _safeDateTime(
      a.updatedAt.isNotEmpty ? a.updatedAt : a.createdAt,
    );
    final bt = _safeDateTime(
      b.updatedAt.isNotEmpty ? b.updatedAt : b.createdAt,
    );
    return bt.compareTo(at);
  }

  DateTime _safeDateTime(String raw) {
    final parsed = DateTime.tryParse(raw.replaceFirst(' ', 'T'));
    if (parsed != null) return parsed;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _timeLabel(String raw) {
    if (raw.length >= 16) {
      // "yyyy-MM-dd HH:mm:ss" -> "HH:mm"
      final idx = raw.indexOf(' ');
      if (idx != -1 && raw.length >= idx + 6) {
        return raw.substring(idx + 1, idx + 6);
      }
    }
    return '';
  }

  String _stripHtml(String input) {
    return input.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Column(
        children: [
          _buildHeader(context),
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
                : _buildList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openNewChatSheet(context),
        backgroundColor: AppTheme.primaryPurple,
        child: const Icon(Icons.add_comment_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 12,
        20,
        18,
      ),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.dashboardPrimaryLight.withOpacity(0.3),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Chat',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          GestureDetector(
            onTap: _load,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
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
            const Icon(Icons.wifi_off_rounded, size: 52, color: Colors.grey),
            const SizedBox(height: 10),
            Text(
              'Unable to load chats',
              style: AppTheme.headingSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              _error ?? 'Unknown error',
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_conversations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 56,
                color: Colors.grey,
              ),
              const SizedBox(height: 10),
              Text('No chats yet', style: AppTheme.headingSmall),
              const SizedBox(height: 6),
              Text(
                'Tap + to start a chat',
                style: AppTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: _conversations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final c = _conversations[index];
        final name = _peerDisplayName(c.peerKey);
        final preview = _stripHtml(c.latestMessage.body);
        final time = _timeLabel(
          c.latestMessage.updatedAt.isNotEmpty
              ? c.latestMessage.updatedAt
              : c.latestMessage.createdAt,
        );

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatThreadScreen(
                  title: name,
                  peerKey: c.peerKey,
                  messageId: c.latestMessage.id,
                ),
              ),
            ).then((_) => _load());
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppTheme.primaryPurple.withOpacity(0.15),
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppTheme.primaryPurple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.headingSmall.copyWith(
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (time.isNotEmpty)
                            Text(time, style: AppTheme.bodySmall),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              preview.isEmpty
                                  ? c.latestMessage.subject
                                  : preview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.bodyMedium,
                            ),
                          ),
                          if (c.unreadCount > 0) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.successGreen,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                c.unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openNewChatSheet(BuildContext context) async {
    const roleItems = <MapEntry<int, String>>[
      MapEntry(1, 'Admin'),
      MapEntry(2, 'Staff'),
      MapEntry(3, 'Teacher'),
      MapEntry(4, 'Accountant'),
      MapEntry(5, 'Librarian'),
      MapEntry(6, 'Parent'),
      MapEntry(7, 'Student'),
    ];

    int? selectedRoleId;
    List<MailboxRecipient> recipients = const [];
    bool loading = false;
    String? error;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> loadRecipients(int roleId) async {
              setModalState(() {
                loading = true;
                error = null;
                recipients = const [];
              });

              try {
                final list = await _service.getRecipients(roleId: roleId);
                setModalState(() {
                  recipients = list;
                  loading = false;
                });
              } catch (e) {
                setModalState(() {
                  error = e.toString();
                  loading = false;
                });
              }
            }

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'New chat',
                              style: AppTheme.headingSmall,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: selectedRoleId,
                        decoration: const InputDecoration(
                          labelText: 'Role',
                          border: OutlineInputBorder(),
                        ),
                        items: roleItems
                            .map(
                              (e) => DropdownMenuItem<int>(
                                value: e.key,
                                child: Text(e.value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          selectedRoleId = value;
                          if (value != null) {
                            loadRecipients(value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      if (loading)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        )
                      else if (error != null)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        )
                      else if (selectedRoleId == null)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text('Select a role to see people'),
                        )
                      else
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 360),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: recipients.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final r = recipients[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.primaryPurple
                                      .withOpacity(0.15),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    color: AppTheme.primaryPurple,
                                  ),
                                ),
                                title: Text(r.name),
                                subtitle:
                                    (r.mobile != null && r.mobile!.isNotEmpty)
                                    ? Text(r.mobile!)
                                    : null,
                                onTap: () {
                                  final roleId = selectedRoleId;
                                  if (roleId == null) return;

                                  Navigator.pop(context);
                                  Navigator.push(
                                    this.context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatThreadScreen(
                                        title: r.name,
                                        peerKey: '$roleId-${r.id}',
                                        receiverRoleId: roleId,
                                        receiverId: r.id,
                                      ),
                                    ),
                                  ).then((_) => _load());
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ChatConversation {
  final String peerKey;
  final MailboxMessage latestMessage;
  final String latestBox;
  final int unreadCount;

  const _ChatConversation({
    required this.peerKey,
    required this.latestMessage,
    required this.latestBox,
    required this.unreadCount,
  });
}

class _MessageWithBox {
  final MailboxMessage message;
  final String box;

  const _MessageWithBox({required this.message, required this.box});
}

class _PeerId {
  final int roleId;
  final int userId;

  const _PeerId({required this.roleId, required this.userId});
}
