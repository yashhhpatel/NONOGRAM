import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Local (device-only) notifications for the optional daily reminder. No
/// network, no push — everything is scheduled on-device. Enabling is always the
/// player's choice from Settings.
class NotificationService {
  static const int _dailyId = 100;
  static const _channelId = 'daily_reminder';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: android),
    );
    _initialized = true;
  }

  /// Asks for the Android 13+ notification permission. Returns whether granted.
  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? true; // older Androids don't need runtime permission
  }

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Daily Reminder',
          channelDescription: 'A gentle nudge to solve your daily puzzle',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      );

  /// Schedules a repeating (~daily) reminder. Uses an inexact interval so no
  /// exact-alarm permission is required.
  Future<void> scheduleDailyReminder() async {
    await init();
    await _plugin.periodicallyShow(
      _dailyId,
      'Pixel Cross',
      'Your daily puzzle is waiting — keep your streak alive!',
      RepeatInterval.daily,
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Shows an immediate notification (used to confirm the reminder is on).
  Future<void> showNow(String title, String body) async {
    await init();
    await _plugin.show(1, title, body, _details);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
