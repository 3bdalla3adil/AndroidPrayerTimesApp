import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _lat = 'location_lat';
  static const _lon = 'location_lon';
  static const _locationName = 'location_name';
  static const _quranFontSize = 'quran_font_size';
  static const _lastSurah = 'last_surah';
  static const _lastAyah = 'last_ayah';

  final SharedPreferencesAsync prefs = SharedPreferencesAsync();

  Future<void> saveLocation(double lat, double lon, String name) async {
    await prefs.setDouble(_lat, lat);
    await prefs.setDouble(_lon, lon);
    await prefs.setString(_locationName, name);
  }

  Future<(double?, double?, String?)> loadLocation() async {
    return (
      await prefs.getDouble(_lat),
      await prefs.getDouble(_lon),
      await prefs.getString(_locationName),
    );
  }

  Future<void> saveReaderPosition(int surah, int ayah) async {
    await prefs.setInt(_lastSurah, surah);
    await prefs.setInt(_lastAyah, ayah);
  }

  Future<(int?, int?)> loadReaderPosition() async {
    return (await prefs.getInt(_lastSurah), await prefs.getInt(_lastAyah));
  }

  Future<void> saveQuranFontSize(double size) => prefs.setDouble(_quranFontSize, size);

  Future<double> loadQuranFontSize() async =>
      await prefs.getDouble(_quranFontSize) ?? 26;
}
