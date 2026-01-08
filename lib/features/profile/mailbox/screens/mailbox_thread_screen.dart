import 'package:flutter/material.dart';
import 'package:skoolwala/shared/theme/app_theme.dart';
import 'package:skoolwala/shared/widgets/app_loading_indicator.dart';
import 'package:skoolwala/shared/widgets/custom_app_bar.dart';

import '../models/mailbox_thread.dart';
import '../services/mailbox_api_service.dart';

class MailboxThreadScreen extends StatefulWidget {
  final MailboxApiService service;
  final int messageId;

  const MailboxThreadScreen({
    super.key,
    required this.service,
    required this.messageId,
  });

  @override
  State<MailboxThreadScreen> createState() => _MailboxThreadScreenState();
}

class _MailboxThreadScreenState extends State<MailboxThreadScreen> {
  late Future<MailboxThread> _future;
  final TextEditingController _replyController = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _future = widget.service.getMessageThread(messageId: widget.messageId);
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<void> _reload() async {
    setState(() {
      _future = widget.service.getMessageThread(messageId: widget.messageId);
    });
    await _future;
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _sending = true;
    });

    try {
      await widget.service.replyMessage(
        messageId: widget.messageId,
        body: text,
      );
      _replyController.clear();
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onPrimary = theme.colorScheme.onPrimary;
    final contentColor = Colors.white;
    final contentMuted = Colors.white70;
    final cardIconColor = Colors.white70;
    final cardDecoration = BoxDecoration(
      color: Colors.white.withOpacity(0.08),
      borderRadius: AppTheme.radiusMedium,
      border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.25),
          blurRadius: 22,
          offset: const Offset(0, 14),
        ),
      ],
    );
    final replyDecoration = InputDecoration(
      hintText: 'Reply...'.toUpperCase(),
      hintStyle: TextStyle(
        color: contentMuted,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      prefixIcon: Icon(Icons.reply_rounded, color: contentColor),
      filled: true,
      fillColor: Colors.white.withOpacity(0.12),
      border: OutlineInputBorder(
        borderRadius: AppTheme.radiusMedium,
        borderSide: BorderSide(color: Colors.white.withOpacity(0.45)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppTheme.radiusMedium,
        borderSide: BorderSide(color: Colors.white.withOpacity(0.45)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppTheme.radiusMedium,
        borderSide: BorderSide(color: Colors.white.withOpacity(0.75), width: 2),
      ),
    );

    return Container(
      decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: CustomAppBar(
          title: 'Message',
          automaticallyImplyLeading: true,
          centerTitle: false,
          actions: [
            FutureBuilder<MailboxThread>(
              future: _future,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final thread = snapshot.data!;
                final isFav = thread.message.isFavouriteForBox('important');
                return IconButton(
                  tooltip: isFav ? 'Remove from Important' : 'Add to Important',
                  icon: Icon(
                    isFav ? Icons.star_rounded : Icons.star_border,
                    color: isFav ? AppTheme.accentOrange : onPrimary,
                  ),
                  onPressed: () async {
                    try {
                      await widget.service.setFavouriteStatus(
                        messageId: widget.messageId,
                        status: !isFav,
                      );
                      await _reload();
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  },
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: FutureBuilder<MailboxThread>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: AppLoadingIndicator());
                  }
                  if (snapshot.hasError) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppTheme.spaceL),
                      children: [
                        const SizedBox(height: 24),
                        Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: Colors.white.withOpacity(0.85),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: contentMuted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton(
                            onPressed: _reload,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(
                                letterSpacing: 0.4,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: const Text('RETRY'),
                          ),
                        ),
                      ],
                    );
                  }

                  final thread = snapshot.data!;
                  final sender = thread.message.sender.trim();
                  final receiver = thread.message.receiver.trim();
                  final fromTo = <String>[];
                  if (sender.isNotEmpty) fromTo.add('From: $sender');
                  if (receiver.isNotEmpty) fromTo.add('To: $receiver');
                  final fromToLine = fromTo.join('   ');

                  return RefreshIndicator(
                    onRefresh: _reload,
                    color: Colors.white,
                    backgroundColor: AppTheme.dashboardPrimary,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppTheme.spaceL),
                      children: [
                        Container(
                          decoration: cardDecoration,
                          padding: const EdgeInsets.all(AppTheme.spaceL),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                thread.message.subject.isEmpty
                                    ? '(No subject)'
                                    : thread.message.subject,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: contentColor,
                                ),
                              ),
                              if (fromToLine.isNotEmpty) ...[
                                const SizedBox(height: AppTheme.spaceS),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person_outline_rounded,
                                      size: 16,
                                      color: cardIconColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        fromToLine,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: contentMuted,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: AppTheme.spaceS),
                              Text(
                                _stripHtml(thread.message.body),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: contentMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceL),
                        if (thread.replies.isNotEmpty)
                          Text(
                            'Replies',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        const SizedBox(height: AppTheme.spaceS),
                        ...thread.replies.map((r) {
                          final prefix = r.identity == 1
                              ? 'Sender'
                              : 'Receiver';
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppTheme.spaceM,
                            ),
                            child: Container(
                              decoration: cardDecoration,
                              padding: const EdgeInsets.all(AppTheme.spaceL),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    prefix,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: contentColor,
                                    ),
                                  ),
                                  const SizedBox(height: AppTheme.spaceXS),
                                  Text(
                                    _stripHtml(r.body),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: contentMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spaceL,
                  AppTheme.spaceS,
                  AppTheme.spaceL,
                  AppTheme.spaceL,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyController,
                        decoration: replyDecoration,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: contentColor,
                          fontWeight: FontWeight.w600,
                        ),
                        minLines: 1,
                        maxLines: 4,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceS),
                    SizedBox(
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: AppTheme.radiusMedium,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 16,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _sending ? null : _sendReply,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppTheme.radiusMedium,
                            ),
                            foregroundColor: Colors.white,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                          child: _sending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Reply'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
