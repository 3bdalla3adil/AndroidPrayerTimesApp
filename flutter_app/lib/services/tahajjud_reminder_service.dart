import '../models/prayer_entry.dart';
import 'notification_service.dart';
import 'prayer_service.dart';
import 'storage_service.dart';

/// Schedules a daily local reminder at the start of the last third of the night.
/// Four pending reminders leave room under iOS's 64-notification limit.
class TahajjudReminderService {
  TahajjudReminderService(this._prayers, this._storage);

  final PrayerService _prayers;
  final StorageService _storage;
  static const daysToSchedule = 4;

  Future<int> enable() async {
    final count = await _schedule();
    await _storage.saveTahajjudRemindersEnabled(true);
    return count;
  }

  Future<void> disable() async {
    await NotificationService.cancelTahajjudReminders();
    await _storage.saveTahajjudRemindersEnabled(false);
  }

  Future<void> sync() async {
    if (!await _storage.loadTahajjudRemindersEnabled()) return;
    await _schedule();
  }

  Future<int> _schedule() async {
    await NotificationService.cancelTahajjudReminders();
    var scheduledCount = 0;
    final today = DateTime.now();
    for (var offset = 0; offset < daysToSchedule; offset++) {
      final date = DateTime(today.year, today.month, today.day + offset);
      final nextDate = DateTime(date.year, date.month, date.day + 1);
      final current = await _prayers.forDate(date);
      final next = await _prayers.forDate(nextDate);
      PrayerEntry? find(List<PrayerEntry> values, String name) {
        for (final entry in values) {
          if (entry.name == name) return entry;
        }
        return null;
      }
      final isha = find(current, 'Isha');
      final fajr = find(next, 'Fajr');
      if (isha == null || fajr == null || !fajr.time.isAfter(isha.time)) continue;
      final nightLength = fajr.time.difference(isha.time);
      final lastThirdStart = fajr.time.subtract(Duration(seconds: nightLength.inSeconds ~/ 3));
      final didSchedule = await NotificationService.schedulePrayer(
        id: 3000 + offset,
        prayerName: 'Tahajjud — last third of the night',
        time: lastThirdStart,
        withSound: false,
        title: 'Tahajjud reminder • تذكير التهجّد',
      );
      if (didSchedule) scheduledCount++;
    }
    return scheduledCount;
  }
}
