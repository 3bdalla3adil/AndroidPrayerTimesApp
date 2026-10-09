import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/home_screen.dart';
import 'screens/more_screen.dart';
import 'screens/prayer_screen.dart';
import 'screens/qibla_screen.dart';
import 'screens/quran_screen.dart';
import 'services/locale_controller.dart';
import 'services/notification_service.dart';
import 'services/root_tab_navigation.dart';
import 'theme/app_theme.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  late final CupertinoTabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CupertinoTabController();
    NotificationService.lastPayload.addListener(_handleNotificationPayload);
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleNotificationPayload());
  }

  void _handleNotificationPayload() {
    final payload = NotificationService.lastPayload.value;
    if (payload == null || !payload.startsWith('prayer:')) return;
    if (mounted) _controller.index = 2;
    NotificationService.clearLastPayload();
  }

  @override
  void dispose() {
    NotificationService.lastPayload.removeListener(_handleNotificationPayload);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen here as well as at the app root so tab labels refresh immediately
    // when the user changes language from Settings.
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.locale,
      builder: (context, locale, _) => RootTabNavigation(
        controller: _controller,
        child: CupertinoTabScaffold(
          controller: _controller,
          tabBar: CupertinoTabBar(
            items: [
              BottomNavigationBarItem(
                icon: const KeyedSubtree(
                  key: ValueKey('home-tab'),
                  child: Icon(CupertinoIcons.house),
                ),
                label: locale.languageCode == 'ar' ? 'الرئيسية' : 'Home',
              ),
              BottomNavigationBarItem(
                icon: const KeyedSubtree(
                  key: ValueKey('quran-tab'),
                  child: Icon(CupertinoIcons.book),
                ),
                label: locale.languageCode == 'ar' ? 'القرآن' : 'Quran',
              ),
              BottomNavigationBarItem(
                icon: const KeyedSubtree(
                  key: ValueKey('prayer-tab'),
                  child: Icon(CupertinoIcons.time),
                ),
                label: locale.languageCode == 'ar' ? 'الصلاة' : 'Prayer',
              ),
              BottomNavigationBarItem(
                icon: const KeyedSubtree(
                  key: ValueKey('qibla-tab'),
                  child: Icon(CupertinoIcons.compass),
                ),
                label: locale.languageCode == 'ar' ? 'القبلة' : 'Qibla',
              ),
              BottomNavigationBarItem(
                icon: const KeyedSubtree(
                  key: ValueKey('more-tab'),
                  child: Icon(CupertinoIcons.ellipsis_circle),
                ),
                label: locale.languageCode == 'ar' ? 'المزيد' : 'More',
              ),
            ],
          ),
          tabBuilder: (context, index) {
            final pages = <Widget>[
              const HomeScreen(),
              const QuranScreen(),
              const PrayerScreen(),
              const QiblaScreen(),
              const MoreScreen(),
            ];
            return CupertinoTabView(builder: (_) => pages[index]);
          },
        ),
      ),
    );
  }
}

class SalawatQuranApp extends StatelessWidget {
  const SalawatQuranApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Keep the test/embedded app entry point visually and behaviorally
    // identical to the production Cupertino app.
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
