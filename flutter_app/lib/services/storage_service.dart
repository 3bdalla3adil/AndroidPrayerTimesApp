import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _lat = 'location_lat';
  static const _lon = 'location_lon';
  static const _locationName = 'location_name';
  static const _country = 'location_country';
  static const _city = 'location_city';
  static const _method = 'prayer_calculation_method';
  static const _quranFontSize = 'quran_font_size';
  static const _quranLineHeight = 'quran_line_height';
  static const _quranShowTranslation = 'quran_show_translation';
  static const _quranDarkPage = 'quran_dark_page';
  static const _bookmarks = 'quran_bookmarks';
  static const _athanReminders = 'athan_reminders_enabled';
  static const _athanPrayers = 'athan_enabled_prayers';
  static const _athanSound = 'athan_sound';
  static const _preReminderMinutes = 'pre_prayer_reminder_minutes';
  static const _prayerAdjustments = 'prayer_time_adjustments';
  static const _tasbihCount = 'tasbih_count';
  static const _tasbihTarget = 'tasbih_target';
  static const _madhab = 'prayer_madhab';

  static const _memorizedAyahs = 'quran_memorized_ayahs';
  static const _reviewAyahs = 'quran_memorization_review_ayahs';
  static const _memorizationSession = 'quran_memorization_session';

  Future<Set<String>> loadMemorizedAyahs() async =>
      (await prefs.getStringList(_memorizedAyahs) ?? const <String>[]).toSet();

  Future<void> saveMemorizedAyahs(Set<String> values) =>
      prefs.setStringList(_memorizedAyahs, values.toList()..sort());

  Future<Set<String>> loadMemorizationReviewAyahs() async =>
      (await prefs.getStringList(_reviewAyahs) ?? const <String>[]).toSet();

  Future<void> saveMemorizationReviewAyahs(Set<String> values) =>
      prefs.setStringList(_reviewAyahs, values.toList()..sort());

  Future<Map<String, int>> loadMemorizationSession() async {
    final values = await prefs.getStringList(_memorizationSession) ?? const <String>[];
    final result = <String, int>{};
    for (final value in values) {
      final parts = value.split(':');
      if (parts.length != 2) continue;
      final parsed = int.tryParse(parts[1]);
      if (parsed != null) result[parts[0]] = parsed;
    }
    return result;
  }

  Future<void> saveMemorizationSession({
    required int surah,
    required int startAyah,
    required int endAyah,
    required int currentAyah,
  }) => prefs.setStringList(_memorizationSession, [
    'surah:$surah',
    'start:$startAyah',
    'end:$endAyah',
    'current:$currentAyah',
  ]);


  static const prayerNames = <String>['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

  final SharedPreferencesAsync prefs = SharedPreferencesAsync();

  Future<void> saveLocation(double lat, double lon, String name) async {
    await prefs.setDouble(_lat, lat);
    await prefs.setDouble(_lon, lon);
    await prefs.setString(_locationName, name);
  }

  Future<(double?, double?, String?)> loadLocation() async => (
        await prefs.getDouble(_lat),
        await prefs.getDouble(_lon),
        await prefs.getString(_locationName),
      );

  Future<void> savePrayerCity({required String country, required String city, required double lat, required double lon, required int method}) async {
    await saveLocation(lat, lon, city);
    await prefs.setString(_country, country);
    await prefs.setString(_city, city);
    await prefs.setInt(_method, method);
  }

  Future<(String?, String?, int?)> loadPrayerCity() async => (
        await prefs.getString(_country),
        await prefs.getString(_city),
        await prefs.getInt(_method),
      );

  Future<void> clearPrayerCity() async {
    await prefs.remove(_country);
    await prefs.remove(_city);
    await prefs.remove(_method);
  }

  Future<void> saveQuranFontSize(double size) => prefs.setDouble(_quranFontSize, size);

  Future<(int, int)> loadTasbih() async => (await prefs.getInt(_tasbihCount) ?? 0, await prefs.getInt(_tasbihTarget) ?? 33);
  Future<void> saveTasbih(int count, int target) async {
    await prefs.setInt(_tasbihCount, count);
    await prefs.setInt(_tasbihTarget, target);
  }

  Future<void> savePrayerCalculationMethod(int method) => prefs.setInt(_method, method);
  Future<int?> loadPrayerCalculationMethod() => prefs.getInt(_method);
  Future<int> loadPrayerMadhab() async => await prefs.getInt(_madhab) ?? 0;
  Future<void> savePrayerMadhab(int madhab) => prefs.setInt(_madhab, madhab);
  Future<double> loadQuranFontSize() async => await prefs.getDouble(_quranFontSize) ?? 28;
  Future<void> saveQuranLineHeight(double value) => prefs.setDouble(_quranLineHeight, value);
  Future<double> loadQuranLineHeight() async => await prefs.getDouble(_quranLineHeight) ?? 1.75;
  Future<void> saveQuranShowTranslation(bool value) => prefs.setBool(_quranShowTranslation, value);
  Future<bool> loadQuranShowTranslation() async => await prefs.getBool(_quranShowTranslation) ?? false;
  Future<void> saveQuranDarkPage(bool value) => prefs.setBool(_quranDarkPage, value);
  Future<bool> loadQuranDarkPage() async => await prefs.getBool(_quranDarkPage) ?? false;

  Future<List<(int, int)>> loadBookmarks() async {
    final values = await prefs.getStringList(_bookmarks) ?? const [];
    final result = <(int, int)>[];
    for (final value in values) {
      final parts = value.split(':');
      if (parts.length != 2) continue;
      final surah = int.tryParse(parts[0]);
      final ayah = int.tryParse(parts[1]);
      if (surah == null || ayah == null || surah < 1 || surah > 114 || ayah < 1) continue;
      result.add((surah, ayah));
    }
    return result;
  }

  Future<void> saveBookmarks(List<(int, int)> bookmarks) async {
    final unique = <String>{};
    for (final bookmark in bookmarks) {
      if (bookmark.$1 < 1 || bookmark.$1 > 114 || bookmark.$2 < 1) continue;
      unique.add('${bookmark.$1}:${bookmark.$2}');
    }
    await prefs.setStringList(_bookmarks, unique.toList());
  }

  Future<bool> loadAthanRemindersEnabled() async => await prefs.getBool(_athanReminders) ?? false;
  Future<void> saveAthanRemindersEnabled(bool enabled) => prefs.setBool(_athanReminders, enabled);

  Future<String> loadAthanSound() async => await prefs.getString(_athanSound) ?? 'default';
  Future<void> saveAthanSound(String soundId) => prefs.setString(_athanSound, soundId);

  Future<int> loadPrePrayerReminderMinutes() async =>
      (await prefs.getInt(_preReminderMinutes) ?? 0).clamp(0, 30);

  Future<void> savePrePrayerReminderMinutes(int minutes) =>
      prefs.setInt(_preReminderMinutes, minutes.clamp(0, 30));

  Future<Set<String>> loadEnabledPrayerNames() async {
    final saved = await prefs.getStringList(_athanPrayers);
    if (saved == null) return prayerNames.toSet();
    final valid = saved.where(prayerNames.contains).toSet();
    return valid.isEmpty ? prayerNames.toSet() : valid;
  }

  Future<void> saveEnabledPrayerNames(Iterable<String> names) async {
    final valid = names.where(prayerNames.contains).toSet();
    await prefs.setStringList(_athanPrayers, (valid.isEmpty ? prayerNames.toSet() : valid).toList());
  }

  Future<Map<String, int>> loadPrayerTimeAdjustments() async {
    final values = await prefs.getStringList(_prayerAdjustments) ?? const [];
    final result = <String, int>{};
    for (final value in values) {
      final parts = value.split(':');
      if (parts.length != 2) continue;
      final minutes = int.tryParse(parts[1]);
      if (minutes == null || !prayerNames.contains(parts[0])) continue;
      result[parts[0]] = minutes.clamp(-120, 120);
    }
    return result;
  }

  Future<void> savePrayerTimeAdjustments(Map<String, int> adjustments) async {
    final values = <String>[];
    for (final name in prayerNames) {
      final minutes = adjustments[name];
      if (minutes == null || minutes == 0) continue;
      values.add('$name:${minutes.clamp(-120, 120)}');
    }
    await prefs.setStringList(_prayerAdjustments, values);
  }


}
