import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_localizations/flutter_localizations.dart';

import 'services/app_routes.dart';
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
  late final ValueNotifier<int> _materialIndex;

  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    _controller = CupertinoTabController();
    _materialIndex = ValueNotifier<int>(0);
    NotificationService.lastPayload.addListener(_handleNotificationPayload);
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleNotificationPayload());
  }

  void _handleNotificationPayload() {
    final payload = NotificationService.lastPayload.value;
    if (payload == null || !payload.startsWith('prayer:')) return;
    if (mounted) {
      _controller.index = 2;
      _materialIndex.value = 2;
    }
    NotificationService.clearLastPayload();
  }

  @override
  void dispose() {
    NotificationService.lastPayload.removeListener(_handleNotificationPayload);
    _controller.dispose();
    _materialIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.locale,
      builder: (context, locale, _) {
        final labels = locale.languageCode == 'ar'
            ? const ['الرئيسية', 'القرآن', 'الصلاة', 'القبلة', 'المزيد']
            : const ['Home', 'Quran', 'Prayer', 'Qibla', 'More'];
        const icons = <IconData>[
          CupertinoIcons.house,
          CupertinoIcons.book,
          CupertinoIcons.time,
          CupertinoIcons.compass,
          CupertinoIcons.ellipsis_circle,
        ];
        const tabKeys = ['home-tab', 'quran-tab', 'prayer-tab', 'qibla-tab', 'more-tab'];

        if (!_isIOS) {
          return RootTabNavigation(
            controller: _controller,
            materialIndex: _materialIndex,
            child: ValueListenableBuilder<int>(
              valueListenable: _materialIndex,
              builder: (context, selectedIndex, _) => material.Scaffold(
                body: IndexedStack(
                  index: selectedIndex,
                  children: List<Widget>.generate(
                    AppRoutes.tabRoutes.length,
                    AppRoutes.tabScreenForIndex,
                  ),
                ),
                bottomNavigationBar: material.NavigationBar(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) {
                    _controller.index = index;
                    _materialIndex.value = index;
                  },
                  destinations: List<material.NavigationDestination>.generate(
                    labels.length,
                    (index) => material.NavigationDestination(
                      key: ValueKey(tabKeys[index]),
                      icon: Icon(icons[index]),
                      label: labels[index],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return RootTabNavigation(
          controller: _controller,
          materialIndex: _materialIndex,
          child: CupertinoTabScaffold(
            controller: _controller,
            tabBar: CupertinoTabBar(
              items: List<BottomNavigationBarItem>.generate(
                labels.length,
                (index) => BottomNavigationBarItem(
                  icon: KeyedSubtree(
                    key: ValueKey(tabKeys[index]),
                    child: Icon(icons[index]),
                  ),
                  label: labels[index],
                ),
              ),
            ),
            tabBuilder: (context, index) => CupertinoTabView(
              builder: (_) => AppRoutes.tabScreenForIndex(index),
              onGenerateRoute: AppRoutes.onGenerateRoute,
            ),
          ),
        );
      },
    );
  }
}

class SalawatQuranApp extends StatelessWidget {
  const SalawatQuranApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.locale,
      builder: (context, locale, _) {
        final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
        if (isIOS) {
          return CupertinoApp(
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
          );
        }

        return material.MaterialApp(
          title: locale.languageCode == 'ar' ? 'صلوات' : 'Salawat',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.materialData,
          darkTheme: AppTheme.materialDarkData,
          themeMode: material.ThemeMode.system,
          locale: locale,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ar'), Locale('en')],
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: const RootShell(),
        );
      },
    );
  }
}
