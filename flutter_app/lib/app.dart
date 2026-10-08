import 'package:flutter/cupertino.dart';

import 'screens/home_screen.dart';
import 'screens/more_screen.dart';
import 'screens/prayer_screen.dart';
import 'screens/qibla_screen.dart';
import 'screens/quran_screen.dart';
import 'services/notification_service.dart';

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
    return CupertinoTabScaffold(
      controller: _controller,
      tabBar: CupertinoTabBar(
        items: const [
          BottomNavigationBarItem(
            icon: KeyedSubtree(key: ValueKey('home-tab'), child: Icon(CupertinoIcons.house)),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: KeyedSubtree(key: ValueKey('quran-tab'), child: Icon(CupertinoIcons.book)),
            label: 'Quran',
          ),
          BottomNavigationBarItem(
            icon: KeyedSubtree(key: ValueKey('prayer-tab'), child: Icon(CupertinoIcons.time)),
            label: 'Prayer',
          ),
          BottomNavigationBarItem(
            icon: KeyedSubtree(key: ValueKey('qibla-tab'), child: Icon(CupertinoIcons.compass)),
            label: 'Qibla',
          ),
          BottomNavigationBarItem(
            icon: KeyedSubtree(key: ValueKey('more-tab'), child: Icon(CupertinoIcons.ellipsis_circle)),
            label: 'More',
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
    );
  }
}

class SalawatQuranApp extends StatelessWidget {
  const SalawatQuranApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      debugShowCheckedModeBanner: false,
      home: RootShell(),
    );
  }
}
