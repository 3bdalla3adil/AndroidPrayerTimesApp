import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'services/notification_service.dart';
import 'services/prayer_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();
  await PrayerService.initialize();
  await NotificationService.initialize();
  runApp(const SalawatApp());
}

class SalawatApp extends StatelessWidget {
  const SalawatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Salawat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.data,
      localizationsDelegates: const [
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar'), Locale('en')],
      localeResolutionCallback: (device, supported) =>
          device?.languageCode == 'ar' ? const Locale('ar') : const Locale('en'),
      home: const RootShell(),
    );
  }
}
