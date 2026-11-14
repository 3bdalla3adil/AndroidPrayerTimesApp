import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

import 'locale_controller.dart';
import 'prayer_service.dart';
import 'storage_service.dart';

/// Synchronizes the next two days of prayer times with the native widgets.
/// iOS renders a true Lock Screen Widget (WidgetKit); Android exposes the
/// equivalent as a home-screen App Widget because Android no longer supports
/// third-party lock-screen widgets on current Android versions.
class NextPrayerWidgetService {
  NextPrayerWidgetService(this._prayerService, this._storage);

  final PrayerService _prayerService;
  final StorageService _storage;

  static const appGroupId = 'group.com.salawat_quran';
  static const iosWidgetKind = 'NextPrayerLockScreenWidget';
  static const androidWidgetProvider = 'NextPrayerWidgetProvider';

  static Future<void> initialize() async {
    if (kIsWeb) return;
    if (Platform.isIOS) {
      await HomeWidget.setAppGroupId(appGroupId);
    }
  }

  Future<void> setEnabled(bool enabled) async {
    await _storage.saveNextPrayerWidgetEnabled(enabled);
    await HomeWidget.saveWidgetData<bool>('widget_enabled', enabled);
    if (enabled) {
      await refresh();
    } else {
      if (Platform.isIOS) {
        await _syncWatch(enabled: false, schedule: '[]');
      }
      await HomeWidget.updateWidget(
        name: androidWidgetProvider,
        androidName: androidWidgetProvider,
        iOSName: iosWidgetKind,
      );
    }
  }

  static const _watchSyncChannel = MethodChannel('com.salawat_quran/watch_sync');

  Future<void> _syncWatch({
    required bool enabled,
    required String schedule,
    String locale = 'ar',
  }) async {
    try {
      await _watchSyncChannel.invokeMethod<void>('syncNextPrayer', {
        'enabled': enabled,
        'schedule': schedule,
        'locale': locale,
      });
    } on MissingPluginException {
      // The native watch companion is added by the iOS project setup script.
    } catch (error) {
      debugPrint('Apple Watch prayer sync failed: $error');
    }
  }

  Future<void> refresh() async {
    if (kIsWeb || !await _storage.loadNextPrayerWidgetEnabled()) return;
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final entries = <Map<String, Object>>[];
      for (var day = 0; day < 2; day++) {
        final prayers = await _prayerService.forDate(today.add(Duration(days: day)));
        for (final prayer in prayers) {
          entries.add({
            'name': prayer.name,
            'arabicName': prayer.arabicName,
            'timestamp': prayer.time.toUtc().toIso8601String(),
          });
        }
      }
      await HomeWidget.saveWidgetData<bool>('widget_enabled', true);
      await HomeWidget.saveWidgetData<String>('prayer_schedule', jsonEncode(entries));
      final locale = LocaleController.isArabic ? 'ar' : 'en';
      await HomeWidget.saveWidgetData<String>('widget_locale', locale);
      if (Platform.isIOS) {
        await _syncWatch(
          enabled: true,
          schedule: jsonEncode(entries),
          locale: locale,
        );
      }
      await HomeWidget.updateWidget(
        name: androidWidgetProvider,
        androidName: androidWidgetProvider,
        iOSName: iosWidgetKind,
      );
    } catch (error, stackTrace) {
      debugPrint('Next prayer widget refresh failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
