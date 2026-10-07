import '../models/prayer_entry.dart';
import 'notification_service.dart';
import 'prayer_service.dart';
import 'storage_service.dart';

/// Keeps Athan/prayer-time reminders synchronized with the current location
/// and calculation method. The OS triggers notifications while the app is closed.
class AthanReminderService {
  AthanReminderService(this._prayerService, this._storage);

  final PrayerService _prayerService;
  final StorageService _storage;

  Future<void> sync({bool refreshLocation = false}) async {
    final enabled = await _storage.loadAthanRemindersEnabled();
    if (!enabled) return;

    final prayers = await _prayerService.today(
      refreshLocation: refreshLocation,
    );

    await NotificationService.initialize();
    await NotificationService.cancelPrayerReminders();
    await NotificationService.scheduleDailyPrayers(
      prayers
          .map<({String name, DateTime time})>(
            (PrayerEntry prayer) => (name: prayer.name, time: prayer.time),
          )
          .toList(),
    );
  }

  Future<void> enable() async {
    // Schedule first. Only persist the enabled state after all five reminders
    // have been accepted by the platform scheduler.
    await NotificationService.initialize();

    final prayers = await _prayerService.today();
    await NotificationService.cancelPrayerReminders();
    await NotificationService.scheduleDailyPrayers(
      prayers
          .map<({String name, DateTime time})>(
            (PrayerEntry prayer) => (name: prayer.name, time: prayer.time),
          )
          .toList(),
    );

    await _storage.saveAthanRemindersEnabled(true);
  }

  Future<void> disable() async {
    await _storage.saveAthanRemindersEnabled(false);
    await NotificationService.cancelPrayerReminders();
  }
}
