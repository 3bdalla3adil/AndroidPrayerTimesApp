import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'services/app_routes.dart';
import 'services/locale_controller.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

/// The home dashboard is the single navigation hub. Feature screens are
/// opened as Cupertino routes instead of switching bottom-navigation tabs.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    NotificationService.lastPayload.addListener(_handleNotificationPayload);
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleNotificationPayload());
  }

  void _handleNotificationPayload() {
    final payload = NotificationService.lastPayload.value;
    if (payload == null || !payload.startsWith('prayer:')) return;
    _navigatorKey.currentState?.pushNamed(AppRoutes.prayer);
    NotificationService.clearLastPayload();
  }

  @override
  void dispose() {
    NotificationService.lastPayload.removeListener(_handleNotificationPayload);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.locale,
      builder: (context, locale, _) => Navigator(
        key: _navigatorKey,
        initialRoute: AppRoutes.home,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}

class SalawatQuranApp extends StatelessWidget {
  const SalawatQuranApp({super.key});

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
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}
