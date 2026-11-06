import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import 'app.dart';
import 'services/locale_controller.dart';
import 'services/notification_service.dart';
import 'services/prayer_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Render the first Flutter frame immediately. Plugin calls such as timezone
  // lookup and Android notification/permission setup must never hold the
  // native launch screen open.
  runApp(const SalawatQuranApp());

  unawaited(_initializeServices());
}

Future<void> _initializeServices() async {
  await _runStartupTask('load saved language', LocaleController.load);
  await _runStartupTask('initialize prayer timezone', PrayerService.initialize);
  await _runStartupTask(
    'initialize notifications',
    NotificationService.initialize,
  );
}

Future<void> _runStartupTask(
  String name,
  Future<void> Function() task,
) async {
  try {
    await task();
  } catch (error, stackTrace) {
    // A plugin or permission failure should not prevent the app from opening.
    debugPrint('Startup task failed ($name): $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}
