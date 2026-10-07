import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'prayer_times_v2';

  static Future<void> initialize() async {
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static const _android = AndroidNotificationDetails(
    _channelId,
    'Prayer Times',
    channelDescription: 'Offline prayer and Athan reminders',
    importance: Importance.max,
    priority: Priority.max,
    playSound: true,
    enableVibration: true,
    visibility: NotificationVisibility.public,
    category: AndroidNotificationCategory.alarm,
  );

  static const _ios = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    interruptionLevel: InterruptionLevel.timeSensitive,
  );

  static const _details = NotificationDetails(
    android: _android,
    iOS: _ios,
  );

  static Future<void> schedulePrayer({
    required int id,
    required String prayerName,
    required DateTime time,
  }) async {
    final scheduled = tz.TZDateTime.from(time, tz.local);
    final now = tz.TZDateTime.now(tz.local);

    if (!scheduled.isAfter(now.add(const Duration(seconds: 2)))) {
      return;
    }

    await _plugin.zonedSchedule(
      id: id,
      title: 'حان وقت الصلاة',
      body: prayerName,
      scheduledDate: scheduled,
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'prayer:$prayerName',
    );
  }

  static Future<int> pendingCount() async =>
      (await _plugin.pendingNotificationRequests()).length;

  static Future<void> cancelAll() => _plugin.cancelAll();
}
