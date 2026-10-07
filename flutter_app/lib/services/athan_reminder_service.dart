import '../models/prayer_entry.dart';
import 'notification_service.dart';
import 'prayer_service.dart';
import 'storage_service.dart';

class AthanReminderService {
  AthanReminderService(this._prayerService, this._storage);
  final PrayerService _prayerService;
  final StorageService _storage;
  static const daysToSchedule = 7;

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
    for (var day = 0; day < daysToSchedule; day++) {
      final prayers = await _prayerService.forDate(
        start.add(Duration(days: day)),
        refreshLocation: day == 0 && refreshLocation,
      );
      for (var i = 0; i < prayers.length; i++) {
        final PrayerEntry prayer = prayers[i];
        await NotificationService.schedulePrayer(
          id: NotificationService.prayerIdBase + day * 10 + i,
          prayerName: prayer.name,
          time: prayer.time,
        );
        count++;
      }
    }
    return count;
  }
}
