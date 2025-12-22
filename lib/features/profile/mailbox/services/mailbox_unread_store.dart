import 'package:shared_preferences/shared_preferences.dart';

class MailboxUnreadStore {
  static const String _inboxUnreadCountKey =
      'skoolwala.mailbox.inbox.unread_count.v1';

  static Future<int> getInboxUnreadCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_inboxUnreadCountKey) ?? 0;
  }

  static Future<void> setInboxUnreadCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_inboxUnreadCountKey, count < 0 ? 0 : count);
  }

  static Future<void> decrementInboxUnreadCount({int by = 1}) async {
    if (by <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_inboxUnreadCountKey) ?? 0;
    final next = current - by;
    await prefs.setInt(_inboxUnreadCountKey, next < 0 ? 0 : next);
  }
}
