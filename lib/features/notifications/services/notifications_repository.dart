import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_notification.dart';

/// Minimal repository stub.
///
/// Hook your API here later (Firebase, backend API, etc.).
class NotificationsRepository {
  static const String _prefsKey = 'skoolwala.notifications.v1';

  const NotificationsRepository();

  Future<List<AppNotification>> fetchMyNotifications() async {
    return _loadFromPrefs();
  }

  Future<void> clearAll() async {
    final existing = await _loadFromPrefs();
    if (existing.isEmpty) return;

    final now = DateTime.now();
    final locked = existing
        .where((n) => n.lockedUntil != null && n.lockedUntil!.isAfter(now))
        .toList(growable: false);

    final prefs = await SharedPreferences.getInstance();
    if (locked.isEmpty) {
      await prefs.remove(_prefsKey);
      return;
    }

    await _saveToPrefs(locked);
  }

  Future<void> addNotification(AppNotification notification) async {
    final existing = await _loadFromPrefs();

    final existingIndex = existing.indexWhere((n) => n.id == notification.id);
    if (existingIndex >= 0) {
      final current = existing[existingIndex];
      final updated = notification.copyWith(createdAt: current.createdAt);
      final next = <AppNotification>[
        updated,
        ...existing.where((n) => n.id != notification.id),
      ];
      await _saveToPrefs(next);
      return;
    }

    final next = <AppNotification>[notification, ...existing];
    await _saveToPrefs(next);
  }

  Future<void> markAsRead(String notificationId) async {
    final existing = await _loadFromPrefs();
    final next = existing
        .map((n) => n.id == notificationId ? n.copyWith(isRead: true) : n)
        .toList(growable: false);
    await _saveToPrefs(next);
  }

  Future<List<AppNotification>> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.trim().isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      final items = decoded
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .map(AppNotification.fromJson)
          .where((n) => n.id.isNotEmpty)
          .toList();

      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return List.unmodifiable(items);
    } catch (_) {
      return const [];
    }
  }

  Future<void> _saveToPrefs(List<AppNotification> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(notifications.map((n) => n.toJson()).toList());
    await prefs.setString(_prefsKey, encoded);
  }
}
