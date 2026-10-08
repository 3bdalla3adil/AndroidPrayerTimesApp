import '../models/prayer_entry.dart';
import 'notification_service.dart';
import 'prayer_service.dart';
import 'storage_service.dart';

class AthanReminderService {
  AthanReminderService(this._prayerService, this._storage);

  final PrayerService _prayerService;
  final StorageService _storage;

  // iOS limits an app to 64 pending local notifications. Twelve days
  // gives us 60 prayer alarms (5/day) while leaving headroom for other
  // notifications.
  static const normalDaysToSchedule = 12;
  static const preReminderDaysToSchedule = 6;
  static const prePrayerIdBase = 2000;

  Future<void> sync({bool refreshLocation = false}) async {
    if (!await _storage.loadAthanRemindersEnabled()) return;
    await _schedule(refreshLocation: refreshLocation);
  }

  Future<int> enable() async {
    await NotificationService.initialize();
    final count = await _schedule();
    await _storage.saveAthanRemindersEnabled(true);
    return count;
  }

  Future<void> disable() async {
    await _storage.saveAthanRemindersEnabled(false);
    await NotificationService.cancelPrayerReminders();
  }

  Future<int> _schedule({bool refreshLocation = false}) async {
    await NotificationService.cancelPrayerReminders();

    var count = 0;
    final start = DateTime.now();
    final enabledPrayers = await _storage.loadEnabledPrayerNames();
    final preMinutes = await _storage.loadPrePrayerReminderMinutes();
    final soundId = await _storage.loadAthanSound();
    final daysToSchedule = preMinutes > 0 ? preReminderDaysToSchedule : normalDaysToSchedule;

    for (var day = 0; day < daysToSchedule; day++) {
      final prayers = await _prayerService.forDate(
        start.add(Duration(days: day)),
        refreshLocation: day == 0 && refreshLocation,
      );

      for (var i = 0; i < prayers.length; i++) {
        final PrayerEntry prayer = prayers[i];
        if (!enabledPrayers.contains(prayer.name)) continue;
        final scheduled = await NotificationService.scheduleAthanPrayer(
          id: NotificationService.prayerIdBase + day * 10 + i,
          prayerName: prayer.name,
          time: prayer.time,
          soundId: NotificationService.soundForPrayer(prayer.name, soundId),
        );
        if (scheduled) count++;

        if (preMinutes > 0) {
          final preTime = prayer.time.subtract(Duration(minutes: preMinutes));
          final preScheduled = await NotificationService.schedulePrayer(
            id: prePrayerIdBase + day * 10 + i,
            prayerName: '${prayer.name} in $preMinutes min',
            time: preTime,
            soundId: soundId,
            withSound: false,
          );
          if (preScheduled) count++;
        }
      }
    }

    return count;
  }
}
