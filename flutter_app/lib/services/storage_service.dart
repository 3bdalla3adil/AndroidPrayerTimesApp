import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _lat = 'location_lat';
  static const _lon = 'location_lon';
  static const _locationName = 'location_name';
  static const _quranFontSize = 'quran_font_size';
  static const _lastSurah = 'last_surah';
  static const _lastAyah = 'last_ayah';
  static const _bookmarks = 'quran_bookmarks';

  final SharedPreferencesAsync prefs = SharedPreferencesAsync();

  Future<void> saveLocation(double lat, double lon, String name) async {
    await prefs.setDouble(_lat, lat);
    await prefs.setDouble(_lon, lon);
    await prefs.setString(_locationName, name);
  }

  Future<(double?, double?, String?)> loadLocation() async =>
      (await prefs.getDouble(_lat), await prefs.getDouble(_lon), await prefs.getString(_locationName));

  Future<void> saveReaderPosition(int surah, int ayah) async {
    await prefs.setInt(_lastSurah, surah);
    await prefs.setInt(_lastAyah, ayah);
  }

  Future<(int?, int?)> loadReaderPosition() async =>
      (await prefs.getInt(_lastSurah), await prefs.getInt(_lastAyah));

  Future<void> saveQuranFontSize(double size) => prefs.setDouble(_quranFontSize, size);

  Future<double> loadQuranFontSize() async => await prefs.getDouble(_quranFontSize) ?? 28;

  Future<List<(int, int)>> loadBookmarks() async {
    final values = await prefs.getStringList(_bookmarks) ?? const [];
    return values.map((value) {
      final parts = value.split(':');
      return (int.parse(parts[0]), int.parse(parts[1]));
    }).toList();
  }

  Future<void> saveBookmarks(List<(int, int)> bookmarks) async =>
      prefs.setStringList(_bookmarks, bookmarks.map((b) => b.$1.toString() + ':' + b.$2.toString()).toList());
}
