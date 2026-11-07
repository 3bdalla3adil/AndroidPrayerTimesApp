import 'storage_service.dart';

class ReaderSettings {
  const ReaderSettings({
    required this.fontSize,
    required this.lineHeight,
    required this.showTranslation,
    required this.darkPage,
    required this.autoScrollSecondsPerPage,
    required this.ayahToolbarEnabled,
  });

  final double fontSize;
  final double lineHeight;
  final bool showTranslation;
  final bool darkPage;
  /// Number of seconds used to move through one Mushaf page during auto-scroll.
  final double autoScrollSecondsPerPage;
  final bool ayahToolbarEnabled;
}

/// Single persistence boundary for reader appearance settings.
final class SettingsService {
  SettingsService(this._storage);

  final StorageService _storage;

  Future<ReaderSettings> load() async {
    final values = await Future.wait<Object>([
      _storage.loadQuranFontSize(),
      _storage.loadQuranLineHeight(),
      _storage.loadQuranShowTranslation(),
      _storage.loadQuranDarkPage(),
      _storage.loadQuranAutoScrollSecondsPerPage(),
      _storage.loadQuranAyahToolbarEnabled(),
    ]);
    return ReaderSettings(
      fontSize: (values[0] as double).clamp(20, 38).toDouble(),
      lineHeight: (values[1] as double).clamp(1.35, 2.15).toDouble(),
      showTranslation: values[2] as bool,
      darkPage: values[3] as bool,
      autoScrollSecondsPerPage:
          (values[4] as double).clamp(10, 60).toDouble(),
      ayahToolbarEnabled: values[5] as bool,
    );
  }

  Future<void> saveFontSize(double value) =>
      _storage.saveQuranFontSize(value.clamp(20, 38).toDouble());

  Future<void> saveLineHeight(double value) =>
      _storage.saveQuranLineHeight(value.clamp(1.35, 2.15).toDouble());

  Future<void> saveTranslation(bool value) =>
      _storage.saveQuranShowTranslation(value);

  Future<void> saveDarkPage(bool value) =>
      _storage.saveQuranDarkPage(value);

  Future<void> saveAutoScrollSecondsPerPage(double value) =>
      _storage.saveQuranAutoScrollSecondsPerPage(
        value.clamp(10, 60).toDouble(),
      );

  Future<void> saveAyahToolbarEnabled(bool enabled) =>
      _storage.saveQuranAyahToolbarEnabled(enabled);
}
