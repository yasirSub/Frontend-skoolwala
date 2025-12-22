import 'package:flutter/material.dart';
import 'package:skoolwala/shared/theme/app_theme.dart';
import 'package:skoolwala/shared/widgets/app_loading_indicator.dart';

import '../models/mailbox_message.dart';
import '../services/mailbox_api_service.dart';
import '../services/mailbox_unread_store.dart';
import 'mailbox_thread_screen.dart';

class MailboxListScreen extends StatefulWidget {
  final MailboxApiService service;
  final String box; // inbox|sent

  const MailboxListScreen({
    super.key,
    required this.service,
    required this.box,
  });

  @override
  State<MailboxListScreen> createState() => _MailboxListScreenState();
}

class _MailboxListScreenState extends State<MailboxListScreen> {
  late Future<List<MailboxMessage>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.getMessages(box: widget.box);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = widget.service.getMessages(box: widget.box);
    });
    await _future;
  }

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  IconData _leadingIconForBox(String box, {required bool isUnread}) {
    switch (box) {
      case 'sent':
        return Icons.outbox_rounded;
      case 'important':
        return Icons.star_rounded;
      case 'inbox':
      default:
        return isUnread
            ? Icons.mark_email_unread_rounded
            : Icons.mark_email_read_rounded;
    }
  }

  String _peerLineForMessage(MailboxMessage m) {
    final sender = m.sender.trim();
    final receiver = m.receiver.trim();

    if (widget.box == 'sent') {
      if (receiver.isEmpty) return '';
      return 'To: $receiver';
    }

    // inbox/important
    if (sender.isNotEmpty) return 'From: $sender';
    if (receiver.isNotEmpty) return 'To: $receiver';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contentColor = Colors.white;
    final contentMuted = Colors.white70;
    final iconColor = Colors.white70;
    final cardDecoration = BoxDecoration(
      color: Colors.white.withOpacity(0.08),
      borderRadius: AppTheme.radiusMedium,
      border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.25),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );

    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
      child: FutureBuilder<List<MailboxMessage>>(
        future: _future,
        builder: (context, snapshot) {
          Widget body;
          if (snapshot.connectionState == ConnectionState.waiting) {
            body = const Center(child: AppLoadingIndicator());
          } else if (snapshot.hasError) {
            body = RefreshIndicator(
              onRefresh: _refresh,
              color: Colors.white,
              backgroundColor: Colors.transparent,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppTheme.spaceL),
                children: [
                  const SizedBox(height: 24),
                  Container(
                    decoration: cardDecoration,
                    padding: const EdgeInsets.all(AppTheme.spaceL),
                    child: Column(
                      children: [
                        Icon(
                          Icons.wifi_off_rounded,
                          size: 48,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: contentMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          } else {
            final messages = snapshot.data ?? const [];
            if (messages.isEmpty) {
              body = RefreshIndicator(
                onRefresh: _refresh,
                color: Colors.white,
                backgroundColor: Colors.transparent,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppTheme.spaceL),
                  children: [
                    const SizedBox(height: 24),
                    Container(
                      decoration: cardDecoration,
                      padding: const EdgeInsets.all(AppTheme.spaceL),
                      child: Column(
                        children: [
                          Icon(
                            Icons.mark_email_read_rounded,
                            size: 48,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.box == 'important'
                                ? 'No important messages'
                                : 'No messages',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: contentColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Pull down to refresh',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: contentMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            } else {
              body = RefreshIndicator(
                onRefresh: _refresh,
                color: Colors.white,
                backgroundColor: Colors.transparent,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppTheme.spaceL),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final m = messages[index];
                    final preview = _stripHtml(m.body);
                    final peerLine = _peerLineForMessage(m);
                    final isFav = m.isFavouriteForBox(widget.box);
                    final isUnread = widget.box == 'inbox' && m.readStatus == 0;
                    final leadingIcon = _leadingIconForBox(
                      widget.box,
                      isUnread: isUnread,
                    );

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.spaceM),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: AppTheme.radiusMedium,
                          onTap: () async {
                            if (isUnread) {
                              try {
                                await widget.service.markMessageAsRead(
                                  messageId: m.id,
                                );
                                await MailboxUnreadStore.decrementInboxUnreadCount();
                              } catch (_) {}
                            }
                            if (!context.mounted) return;
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => MailboxThreadScreen(
                                  service: widget.service,
                                  messageId: m.id,
                                ),
                              ),
                            );
                            await _refresh();
                          },
                          child: Container(
                            decoration: cardDecoration,
                            padding: const EdgeInsets.all(AppTheme.spaceL),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(
                                      isUnread ? 0.3 : 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    leadingIcon,
                                    color: isUnread
                                        ? AppTheme.dashboardPrimary
                                        : Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spaceL),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m.subject.isEmpty
                                            ? '(No subject)'
                                            : m.subject,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(
                                              fontWeight: isUnread
                                                  ? FontWeight.w800
                                                  : FontWeight.w700,
                                              color: contentColor,
                                            ),
                                      ),
                                      if (peerLine.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.person_outline_rounded,
                                              size: 16,
                                              color: iconColor,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                peerLine,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: contentMuted,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      const SizedBox(height: 6),
                                      Text(
                                        preview,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(color: contentMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spaceS),
                                IconButton(
                                  tooltip: isFav
                                      ? 'Remove from Important'
                                      : 'Add to Important',
                                  icon: Icon(
                                    isFav
                                        ? Icons.star_rounded
                                        : Icons.star_border,
                                    color: isFav
                                        ? AppTheme.accentOrange
                                        : iconColor,
                                  ),
                                  onPressed: () async {
                                    try {
                                      await widget.service.setFavouriteStatus(
                                        messageId: m.id,
                                        status: !isFav,
                                      );
                                      await _refresh();
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text(e.toString())),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }
          }
          return SafeArea(top: false, bottom: false, child: body);
        },
      ),
    );
  }
}
