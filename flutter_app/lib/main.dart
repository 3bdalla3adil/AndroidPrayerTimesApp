import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'services/locale_controller.dart';
import 'services/notification_service.dart';
import 'services/prayer_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();
  await LocaleController.load();
  await PrayerService.initialize();
  await NotificationService.initialize();
  runApp(const SalawatApp());
}

class SalawatApp extends StatelessWidget {
  const SalawatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.locale,
      builder: (context, locale, _) => CupertinoApp(
        title: locale.languageCode == 'ar' ? 'صلوات' : 'Salawat',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.data,
        locale: locale,
        localizationsDelegates: const [
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ar'), Locale('en')],
        home: const RootShell(),
      ),
    );
  }
}
