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

  test('reading history is capped and newest entry wins', () async {
    for (var i = 1; i <= 25; i++) {
      await storage.addReadingHistory(1, i);
    }
    await storage.addReadingHistory(1, 25);
    final history = await storage.loadReadingHistory();
    expect(history.length, 20);
    expect(history.last.$2, 25);
    expect(history.where((item) => item.$2 == 25).length, 1);
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

  test('persists Tasbih custom target', () async {
      await storage.saveTasbih(32, 33);
      expect(await storage.loadTasbih(), (32, 33));
    });

  test('persists biometric lock preference', () async {
    expect(await storage.loadBiometricLockEnabled(), isFalse);
    await storage.saveBiometricLockEnabled(true);
    expect(await storage.loadBiometricLockEnabled(), isTrue);
    await storage.saveBiometricLockEnabled(false);
    expect(await storage.loadBiometricLockEnabled(), isFalse);
  });

}
