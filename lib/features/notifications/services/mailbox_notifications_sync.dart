import 'package:shared_preferences/shared_preferences.dart';

import '../../profile/mailbox/models/mailbox_message.dart';
import '../models/app_notification.dart';
import '../services/local_notifications_service.dart';
import '../services/notifications_repository.dart';

class MailboxNotificationsSync {
  static const String _lastInboxIdKey = 'skoolwala.mailbox.inbox.last_id.v1';

  static Future<void> syncInboxMessages(List<MailboxMessage> inbox) async {
    if (inbox.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final lastId = prefs.getInt(_lastInboxIdKey) ?? 0;

    final newestId = inbox
        .map((m) => m.id)
        .fold<int>(0, (a, b) => a > b ? a : b);
    if (newestId <= lastId) return;

    final newMessages = inbox.where((m) => m.id > lastId).toList();
    if (newMessages.isEmpty) {
      await prefs.setInt(_lastInboxIdKey, newestId);
      return;
    }

    // Oldest -> newest so notifications list order is consistent
    newMessages.sort((a, b) => a.id.compareTo(b.id));

    final repo = const NotificationsRepository();

    for (final m in newMessages) {
      final createdAt = DateTime.tryParse(m.createdAt) ?? DateTime.now();
      await repo.addNotification(
        AppNotification(
          id: 'mailbox:${m.id}',
          type: 'mail',
          title: (m.subject.trim().isEmpty ? 'New mail' : m.subject).trim(),
          message:
              (m.sender.trim().isEmpty
                      ? m.body
                      : 'From: ${m.sender}\n${m.body}')
                  .trim(),
          createdAt: createdAt,
          isRead: m.readStatus == 1,
        ),
      );
    }

    // Show one OS notification (avoid spamming)
    final last = newMessages.last;
    final count = newMessages.length;
    final title = count == 1
        ? (last.subject.trim().isEmpty ? 'New mail' : last.subject).trim()
        : 'You have $count new messages';
    final body = count == 1
        ? (last.sender.trim().isEmpty
                  ? last.body
                  : 'From: ${last.sender}\n${last.body}')
              .trim()
        : 'Open Skoolwala to view them.';

    await LocalNotificationsService.instance.showNewMail(
      title: title,
      body: body,
    );

    await prefs.setInt(_lastInboxIdKey, newestId);
  }
}
