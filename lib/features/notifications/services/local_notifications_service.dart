import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationsService {
  static final LocalNotificationsService instance =
      LocalNotificationsService._internal();

  LocalNotificationsService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'skoolwala_general';
  static const String _channelName = 'Skoolwala Notifications';
  static const String _channelDescription =
      'General notifications for Skoolwala';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(initSettings);

    // Android: create channel
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );

    final androidSpecific = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidSpecific != null) {
      await androidSpecific.createNotificationChannel(channel);

      // Android 13+ runtime permission
      try {
        await androidSpecific.requestNotificationsPermission();
      } catch (_) {
        // ignore
      }
    }

    _initialized = true;
  }

  Future<void> showNewMail({
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return; // local notifications not supported for web here
    await init();

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title,
      body,
      details,
    );
  }
}
