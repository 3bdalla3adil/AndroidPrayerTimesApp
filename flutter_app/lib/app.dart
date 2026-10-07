import 'package:flutter/cupertino.dart';

import 'screens/home_screen.dart';
import 'screens/more_screen.dart';
import 'screens/prayer_screen.dart';
import 'screens/qibla_screen.dart';
import 'screens/quran_screen.dart';

class RootShell extends StatelessWidget {
  const RootShell({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(items: const [
        BottomNavigationBarItem(icon: Icon(CupertinoIcons.house), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(CupertinoIcons.book), label: 'Quran'),
        BottomNavigationBarItem(icon: Icon(CupertinoIcons.time), label: 'Prayer'),
        BottomNavigationBarItem(icon: Icon(CupertinoIcons.compass), label: 'Qibla'),
        BottomNavigationBarItem(icon: Icon(CupertinoIcons.ellipsis_circle), label: 'More'),
      ]),
      tabBuilder: (context, index) {
        const pages = <Widget>[HomeScreen(), QuranScreen(), PrayerScreen(), QiblaScreen(), MoreScreen()];
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
