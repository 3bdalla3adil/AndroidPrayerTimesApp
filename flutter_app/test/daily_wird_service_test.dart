import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:salawat_quran/services/daily_wird_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('one juz starts at Al-Fatiha and ends at the canonical juz boundary', () async {
    final service = DailyWirdService();
    final plan = await service.loadToday();

    expect(plan.start.surah, 1);
    expect(plan.start.ayah, 1);
    expect(plan.end.surah, 2);
    expect(plan.end.ayah, 141);
    expect(plan.totalAyahs, greaterThan(140));
  });

  test('one hizb uses the canonical boundary and continues at the next hizb', () async {
    final service = DailyWirdService();
    await service.saveSettings(WirdUnit.hizb, 1);

    final plan = await service.loadToday();

    expect(plan.start.surah, 1);
    expect(plan.start.ayah, 1);
    expect(plan.end.surah, 2);
    expect(plan.end.ayah, 74);
  });

  test('ayah target spans surah boundaries without skipping verses', () async {
    final service = DailyWirdService();
    await service.saveSettings(WirdUnit.ayah, 10);

    final plan = await service.loadToday();

    expect(plan.start.surah, 1);
    expect(plan.start.ayah, 1);
    expect(plan.end.surah, 2);
    expect(plan.end.ayah, 3);
  });

  test('reading progress is recorded and completion requires confirmation', () async {
    final service = DailyWirdService();
    await service.saveSettings(WirdUnit.ayah, 10);
    var plan = await service.loadToday();

    expect(plan.completed, isFalse);
    await service.recordReadThrough(2, 2);
    plan = await service.loadToday();
    expect(plan.completedAyahs, 9);
    expect(plan.completed, isFalse);

    await service.confirmCompletion();
    plan = await service.loadToday();
    expect(plan.completed, isTrue);
  });
}
