import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'athan_prayer_channel_v2';
  static const int prayerIdBase = 1000;
  static const int maxScheduledPrayerIds = 120;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    final info = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(info.identifier));

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

    _initialized = true;
  }

  static const _android = AndroidNotificationDetails(
    _channelId,
    'Prayer Times',
    channelDescription: 'Offline prayer and Athan reminders',
    importance: Importance.max,
    priority: Priority.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('azan'),
    enableVibration: true,
    visibility: NotificationVisibility.public,
    category: AndroidNotificationCategory.alarm,
  );

  static const _ios = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    interruptionLevel: InterruptionLevel.timeSensitive,
    sound: 'azan.mp3',
  );

  static const _details = NotificationDetails(
    android: _android,
    iOS: _ios,
  );

  /// Returns true only when a future notification was actually scheduled.
  static Future<bool> schedulePrayer({
    required int id,
    required String prayerName,
    required DateTime time,
  }) async {
    await initialize();
    final scheduled = tz.TZDateTime.from(time, tz.local);
    final now = tz.TZDateTime.now(tz.local);

    if (!scheduled.isAfter(now.add(const Duration(seconds: 2)))) {
      return false;
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
    return true;
  }

  static Future<void> cancelPrayerReminders() async {
    await initialize();
    for (var i = 0; i < maxScheduledPrayerIds; i++) {
      await _plugin.cancel(id: prayerIdBase + i);
    }
  }

  static Future<int> pendingCount() async {
    await initialize();
    return (await _plugin.pendingNotificationRequests()).length;
  }

  static Future<void> cancelAll() async {
    await initialize();
    await _plugin.cancelAll();
  }
}
