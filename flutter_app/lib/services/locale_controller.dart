import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the app language. Arabic is the first-run default.
class LocaleController {
  LocaleController._();

  static final ValueNotifier<Locale> locale = ValueNotifier(const Locale('ar'));
  static const _preferenceKey = 'app_locale';

  static bool get isArabic => locale.value.languageCode == 'ar';

  static Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString(_preferenceKey) ?? 'ar';
    locale.value = Locale(saved == 'en' ? 'en' : 'ar');
  }

  static Future<void> setLanguage(String languageCode) async {
    final language = languageCode == 'en' ? 'en' : 'ar';
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_preferenceKey, language);
    locale.value = Locale(language);
  }
}
