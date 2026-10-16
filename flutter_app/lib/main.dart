import 'package:flutter/cupertino.dart';

import 'app.dart';
import 'services/locale_controller.dart';
import 'services/notification_service.dart';
import 'services/prayer_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocaleController.load();
  await PrayerService.initialize();
  await NotificationService.initialize();
  runApp(const SalawatQuranApp());
}
