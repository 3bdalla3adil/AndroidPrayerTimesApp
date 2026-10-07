import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _prayerIdBase = 1000;
  static const String _channelId = 'athan_prayer_channel';

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    final info = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(info.identifier));

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
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();

    _initialized = true;
  }

  static void _onNotificationResponse(NotificationResponse response) {
    // Keep the callback lightweight. The prayer screen can react to the
    // notification through the app lifecycle when it is opened.
  }

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    _channelId,
    'Athan & Prayer Times',
    channelDescription:
        'Automatic notifications at the five daily prayer times',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
    category: AndroidNotificationCategory.alarm,
    visibility: NotificationVisibility.public,
  );

  static const DarwinNotificationDetails _iosDetails =
      DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  static const NotificationDetails _details = NotificationDetails(
    android: _androidDetails,
    iOS: _iosDetails,
  );

  static Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  static Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    await _ensureInitialized();
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _details,
    );
  }

  /// Schedule the prayer at its next occurrence and repeat every day at the
  /// same local clock time.
  static Future<void> schedulePrayer({
    required int id,
    required String prayerName,
    required DateTime time,
  }) async {
    await _ensureInitialized();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      time.year,
      time.month,
      time.day,
      time.hour,
      time.minute,
    );

    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: 'Athan — $prayerName',
        body: 'It is time for $prayerName prayer.',
        scheduledDate: scheduled,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } on Exception {
      // Some Android devices do not grant exact-alarm access. Keep reminders
      // functional with the inexact OS scheduler instead of disabling Athan.
      await _plugin.zonedSchedule(
        id: id,
        title: 'Athan — $prayerName',
        body: 'It is time for $prayerName prayer.',
        scheduledDate: scheduled,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  static Future<void> scheduleDailyPrayers(
    List<({String name, DateTime time})> prayers,
  ) async {
    await _ensureInitialized();

    for (var i = 0; i < prayers.length; i++) {
      await schedulePrayer(
        id: _prayerIdBase + i,
        prayerName: prayers[i].name,
        time: prayers[i].time,
      );
    }
  }

  static Future<void> cancelPrayerReminders() async {
    await _ensureInitialized();
    for (var i = 0; i < 5; i++) {
      await _plugin.cancel(id: _prayerIdBase + i);
    }
  }

  static Future<void> cancel(int id) async {
    await _ensureInitialized();
    await _plugin.cancel(id: id);
  }

  static Future<void> cancelAll() async {
    await _ensureInitialized();
    await _plugin.cancelAll();
  }

  static Future<List<PendingNotificationRequest>> pending() async {
    await _ensureInitialized();
    return _plugin.pendingNotificationRequests();
  }
}
