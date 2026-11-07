import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:salawat_quran/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    storage = StorageService();
  });

  test('corrupt bookmarks are ignored instead of throwing', () async {
    await storage.prefs.setStringList('quran_bookmarks', const [
      '1:1',
      'bad-value',
      '999:2',
      '2:not-a-number',
    ]);
    expect(await storage.loadBookmarks(), [(1, 1)]);
  });

  test('prayer preferences persist safely', () async {
    await storage.saveEnabledPrayerNames(const ['Fajr', 'Isha']);
    await storage.savePrayerTimeAdjustments({'Fajr': 5, 'Isha': -10});
    expect(await storage.loadEnabledPrayerNames(), {'Fajr', 'Isha'});
    expect(await storage.loadPrayerTimeAdjustments(), {'Fajr': 5, 'Isha': -10});
    await storage.savePrePrayerReminderMinutes(15);
    expect(await storage.loadPrePrayerReminderMinutes(), 15);
  });

  test('persists Quran display settings', () async {
    await storage.saveQuranFontSize(34);
    await storage.saveQuranLineHeight(1.9);
    await storage.saveQuranShowTranslation(true);
    await storage.saveQuranDarkPage(true);

    expect(await storage.loadQuranFontSize(), 34);
    expect(await storage.loadQuranLineHeight(), 1.9);
    expect(await storage.loadQuranShowTranslation(), isTrue);
    expect(await storage.loadQuranDarkPage(), isTrue);
  });

  test('filters invalid prayer names and clamps reminder settings', () async {
    await storage.prefs.setStringList('athan_enabled_prayers', const [
      'Fajr', 'Invalid', 'Isha',
    ]);
    expect(await storage.loadEnabledPrayerNames(), {'Fajr', 'Isha'});

    await storage.savePrePrayerReminderMinutes(99);
    expect(await storage.loadPrePrayerReminderMinutes(), 30);
    await storage.savePrePrayerReminderMinutes(-5);
    expect(await storage.loadPrePrayerReminderMinutes(), 0);
  });

  test('clamps prayer-time adjustments and ignores unknown prayers', () async {
    await storage.prefs.setStringList('prayer_time_adjustments', const [
      'Fajr:999', 'Dhuhr:-999', 'Unknown:15', 'Asr:invalid',
    ]);
    expect(await storage.loadPrayerTimeAdjustments(), {
      'Fajr': 120,
      'Dhuhr': -120,
    });

    await storage.savePrayerTimeAdjustments({
      'Fajr': 500,
      'Unknown': 20,
      'Isha': -500,
    });
    expect(await storage.loadPrayerTimeAdjustments(), {
      'Fajr': 120,
      'Isha': -120,
    });
  });

  test('persists location and calculation preferences', () async {
    await storage.savePrayerCity(
      country: 'Saudi Arabia',
      city: 'Makkah',
      lat: 21.3891,
      lon: 39.8579,
      method: 4,
    );

    expect(await storage.loadLocation(), (21.3891, 39.8579, 'Makkah'));
    expect(await storage.loadPrayerCity(), ('Saudi Arabia', 'Makkah', 4));
  });

  test('persists Tasbih custom target', () async {
    await storage.saveTasbih(32, 33);
    expect(await storage.loadTasbih(), (32, 33));
  });

}
