import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _defaultSoundId = 'default';
  static const _fajrSoundId = 'fajr_madinah';
  // Android notification channels are immutable after creation, including their
  // sound. Use a versioned channel namespace so older installs receive fresh
  // sound-enabled channels after upgrading the app.
  static const _channelVersion = 'v3';
  static const int prayerIdBase = 1000;
  static const int prePrayerIdBase = 2000;
  static const int maxScheduledPrayerIds = 120;
  static bool _initialized = false;
  static bool _exactAlarmReady = true;
  static final ValueNotifier<String?> lastPayload = ValueNotifier<String?>(null);

  // Only sounds whose files are actually bundled are exposed here.
  // Add another entry only after its audio file is added to assets/audio,
  // Android res/raw and the iOS Runner resources.
  static const soundLabels = <String, String>{
    'default': 'Athan — Default',
    'madinah': 'Athan — Madinah',
    'dubai': 'Athan — Dubai',
    'fajr_madinah': 'Fajr Athan — Madinah',
  };

  static const soundResources = <String, String>{
    'default': 'azan',
    'madinah': 'azan_madinah',
    'dubai': 'azan_dubai',
    'fajr_madinah': 'azan_fajr_madinah',
  };

  static String soundForPrayer(String prayerName, String normalSoundId) =>
      prayerName.toLowerCase() == 'fajr' ? _fajrSoundId : normalSoundId;

  static String _soundResource(String soundId) =>
      soundResources[soundId] ?? soundResources[_defaultSoundId]!;

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
      onDidReceiveNotificationResponse: (response) {
        lastPayload.value = response.payload;
      },
    );

    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      lastPayload.value = launch?.notificationResponse?.payload;
    }

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    if (androidPlugin != null) {
      await _createSoundChannels(androidPlugin);
      final exact = await androidPlugin.canScheduleExactNotifications();
      if (exact != true) {
        await androidPlugin.requestExactAlarmsPermission();
      }
      _exactAlarmReady =
          await androidPlugin.canScheduleExactNotifications() ?? false;
    }

    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  static String _channelIdForSound(String soundId) =>
      'athan_prayer_${_channelVersion}_$soundId';

  static Future<void> _createSoundChannels(
    AndroidFlutterLocalNotificationsPlugin androidPlugin,
  ) async {
    for (final entry in soundResources.entries) {
      await androidPlugin.createNotificationChannel(
        AndroidNotificationChannel(
          _channelIdForSound(entry.key),
          'Prayer Times — ${soundLabels[entry.key] ?? entry.key}',
          description: 'Prayer notifications with Athan audio',
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(entry.value),
          enableVibration: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
      );
    }
  }

  static AndroidNotificationDetails _androidDetails(String soundId) {
    final resource = _soundResource(soundId);
    final channelId = _channelIdForSound(soundId);
    return AndroidNotificationDetails(
      channelId,
      'Prayer Times',
      channelDescription: 'Offline prayer and Athan reminders',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(resource),
      enableVibration: true,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.alarm,
    );
  }

  static DarwinNotificationDetails _iosDetails(String soundId) {
    return DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
      // iOS notification sounds are generated as <29s WAV clips because
      // Apple falls back to the default sound for custom sounds >= 30s.
      sound: '${_soundResource(soundId)}.wav',
    );
  }

  static NotificationDetails _silentDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'prayer_reminder_silent_v1',
        'Prayer reminders',
        channelDescription: 'Silent pre-prayer reminders',
        importance: Importance.high,
        priority: Priority.high,
        playSound: false,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
        interruptionLevel: InterruptionLevel.active,
      ),
    );
  }

  static NotificationDetails _details(String soundId, {bool withSound = true}) {
    if (!withSound) return _silentDetails();
    return NotificationDetails(
      android: _androidDetails(soundId),
      iOS: _iosDetails(soundId),
    );
  }

  /// Returns whether Android can currently deliver exact scheduled alarms.
  /// On iOS this remains true; iOS handles the scheduled notification itself.
  static bool get exactAlarmReady => _exactAlarmReady;

  static Future<bool> refreshExactAlarmPermission() async {
    await initialize();
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return true;
    _exactAlarmReady =
        await androidPlugin.canScheduleExactNotifications() ?? false;
    return _exactAlarmReady;
  }

  /// Returns true only when a future notification was actually scheduled.
  static Future<bool> schedulePrayer({
    required int id,
    required String prayerName,
    required DateTime time,
    String soundId = _defaultSoundId,
    bool withSound = true,
  }) async {
    await initialize();
    if (!_exactAlarmReady) {
      throw StateError(
        'Exact alarms are not enabled. Please allow Alarms & reminders for this app in Android Settings.',
      );
    }
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
      notificationDetails: _details(soundId, withSound: withSound),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'prayer:$prayerName',
    );
    return true;
  }

  /// Schedules a prayer notification with Athan audio explicitly enabled.\n  /// The Athan-alert switch uses this path so prayer alerts cannot accidentally\n  /// be converted into silent notifications by a future scheduling change.\n  static Future<bool> scheduleAthanPrayer({\n    required int id,\n    required String prayerName,\n    required DateTime time,\n    required String soundId,\n  }) => schedulePrayer(\n        id: id,\n        prayerName: prayerName,\n        time: time,\n        soundId: soundId,\n        withSound: true,\n      );\n\n  /// Schedules the exact same notification/sound path used by prayer alarms,
  /// five seconds from now. This is the Settings > Test Athan action.
  static Future<void> scheduleTestAthan({
    String soundId = _defaultSoundId,
  }) async {
    await initialize();
    final testTime =
        tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));
    await _plugin.zonedSchedule(
      id: 2999,
      title: 'اختبار الأذان',
      body: 'سيتم تشغيل صوت الأذان الآن',
      scheduledDate: testTime,
      notificationDetails: _details(soundId),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'athan_test:$soundId',
    );
  }

  static Future<void> scheduleTestFajrAthan() =>
      scheduleTestAthan(soundId: _fajrSoundId);

  static Future<void> cancelPrayerReminders() async {
    await initialize();
    for (var i = 0; i < maxScheduledPrayerIds; i++) {
      await _plugin.cancel(id: prayerIdBase + i);
      await _plugin.cancel(id: prePrayerIdBase + i);
    }
    await _plugin.cancel(id: 2999);
  }

  static Future<int> pendingCount() async {
    await initialize();
    return (await _plugin.pendingNotificationRequests()).length;
  }

  static void clearLastPayload() => lastPayload.value = null;

  static Future<void> cancelAll() async {
    await initialize();
    await _plugin.cancelAll();
  }
}
