import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'services/locale_controller.dart';
import 'services/notification_service.dart';
import 'services/prayer_service.dart';
import 'services/next_prayer_widget_service.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Render the Flutter UI immediately. Platform services (timezone,
  // notifications, shared preferences and home-screen widgets) must never
  // prevent Android from reaching the first frame if a plugin is unavailable
  // or a permission/platform call fails during cold start.
  runApp(const ProviderScope(child: SalawatQuranApp()));

  unawaited(_initializePlatformServices());
}

Future<void> _initializePlatformServices() async {
  await _runStartupTask('load locale', LocaleController.load);
  await _runStartupTask('initialize prayer timezone', PrayerService.initialize);
  await _runStartupTask(
    'initialize notifications',
    NotificationService.initialize,
  );
  await _runStartupTask(
    'initialize next-prayer widget',
    NextPrayerWidgetService.initialize,
  );

  // Widget refresh is non-critical to app startup and already handles
  // platform/plugin errors internally.
  try {
    await NextPrayerWidgetService(
      PrayerService(StorageService()),
      StorageService(),
    ).refresh();
  } catch (error, stackTrace) {
    debugPrint('Next-prayer widget startup refresh failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

Future<void> _runStartupTask(
  String name,
  Future<void> Function() task,
) async {
  try {
    await task();
  } catch (error, stackTrace) {
    debugPrint('Startup task "$name" failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}
