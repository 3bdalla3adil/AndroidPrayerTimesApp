import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:salawat_quran/services/prayer_service.dart';
import 'package:salawat_quran/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;
  late PrayerService service;

  setUp(() async {
    storage = StorageService();
    service = PrayerService(storage);
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('UTC'));
    await storage.saveLocation(21.3891, 39.8579, 'Makkah');
    await storage.savePrayerCalculationMethod(4);
  });

  test('calculates all five daily prayers from saved offline coordinates', () async {
    final prayers = await service.forDate(DateTime.utc(2026, 1, 15));

    expect(prayers.map((entry) => entry.name).toList(), [
      'Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha',
    ]);
    expect(prayers.map((entry) => entry.arabicName).toList(), [
      'الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء',
    ]);
    expect(prayers.every((entry) => entry.time.isUtc), isTrue);
    expect(prayers.every((entry) => entry.time.year == 2026), isTrue);
    for (var i = 1; i < prayers.length; i++) {
      expect(prayers[i].time.isAfter(prayers[i - 1].time), isTrue);
    }
  });

  test('applies saved minute adjustments to each prayer', () async {
    await storage.savePrayerTimeAdjustments({
      'Fajr': 5,
      'Dhuhr': -10,
      'Isha': 3,
    });

    final adjusted = await service.forDate(DateTime.utc(2026, 1, 15));
    await storage.savePrayerTimeAdjustments({});
    final baseline = await service.forDate(DateTime.utc(2026, 1, 15));

    expect(adjusted[0].time.difference(baseline[0].time).inMinutes, 5);
    expect(adjusted[1].time.difference(baseline[1].time).inMinutes, -10);
    expect(adjusted[2].time, baseline[2].time);
    expect(adjusted[4].time.difference(baseline[4].time).inMinutes, 3);
  });

  test('uses saved madhab preference without requesting device location', () async {
    await storage.savePrayerMadhab(1);

    final prayers = await service.forDate(DateTime.utc(2026, 6, 1));

    expect(prayers, hasLength(5));
    expect(prayers.every((entry) => entry.time != DateTime(0)), isTrue);
  });
}
