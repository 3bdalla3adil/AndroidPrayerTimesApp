import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (_) {},
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    'prayer_channel',
    'Prayer Times',
    channelDescription: 'Notifications for prayer times',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
  );

  static const NotificationDetails _details =
      NotificationDetails(android: _androidDetails);

  static Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _details,
    );
  }

  /// Schedule a single prayer notification.
  static Future<void> schedulePrayer({
    required int id,
    required String prayerName,
    required DateTime time,
  }) async {
    final tzDate = tz.TZDateTime.from(time, tz.local);

    if (tzDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      id: id,
      title: prayerName,
      body: 'It is time for $prayerName prayer',
      scheduledDate: tzDate,
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancel(int id) => _plugin.cancel(id: id);
  static Future<void> cancelAll() => _plugin.cancelAll();
  static Future<List<PendingNotificationRequest>> pending() =>
      _plugin.pendingNotificationRequests();
}
