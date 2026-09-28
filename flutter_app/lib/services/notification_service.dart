import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Call once at app startup (from main.dart or app.dart).
  static Future<void> initialize() async {
    // Initialize timezone database so zonedSchedule works correctly.
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
      onDidReceiveNotificationResponse: (response) {
        // Handle notification tap here if needed.
      },
    );

    // Ask for Android 13+ permission.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Request permission explicitly (call from a button if needed).
  static Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    final a = await android?.requestNotificationsPermission() ?? true;
    final i = await ios?.requestPermissions(alert: true, badge: true, sound: true) ?? true;
    return a && i;
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

  /// Show an immediate notification.
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
  ///
  /// [id] must be unique per prayer per day. A common scheme is:
  ///   id = dayIndex * 10 + prayerIndex
  static Future<void> schedulePrayer({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    // Convert to TZDateTime in the device's local zone.
    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

    // Skip if the time is in the past.
    if (tzDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzDate,
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // daily repeat
    );
  }

  /// Cancel a single notification.
  static Future<void> cancel(int id) => _plugin.cancel(id: id);

  /// Cancel all notifications.
  static Future<void> cancelAll() => _plugin.cancelAll();

  /// List pending scheduled notifications (useful for debugging).
  static Future<List<PendingNotificationRequest>> pending() =>
      _plugin.pendingNotificationRequests();
}
