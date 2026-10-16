import 'package:flutter/cupertino.dart';

import '../screens/adhkar_screen.dart';
import '../screens/bookmarks_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/dedication_screen.dart';
import '../screens/fasting_screen.dart';
import '../screens/home_screen.dart';
import '../screens/more_screen.dart';
import '../screens/prayer_screen.dart';
import '../screens/qibla_screen.dart';
import '../screens/quran_reader_screen.dart';
import '../screens/quran_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/tasbih_screen.dart';

/// Canonical route names and the single route-to-screen mapping.
abstract final class AppRoutes {
  static const home = '/home';
  static const quran = '/quran';
  static const prayer = '/prayer';
  static const qibla = '/qibla';
  static const more = '/more';
  static const quranReader = '/quran/reader';
  static const bookmarks = '/quran/bookmarks';
  static const adhkar = '/adhkar';
  static const tasbih = '/tasbih';
  static const fasting = '/fasting';
  static const calendar = '/calendar';
  static const settings = '/settings';
  static const dedication = '/dedication';

  static const tabRoutes = <String>[home, quran, prayer, qibla, more];
  static const allRoutes = <String>[
    ...tabRoutes,
    quranReader,
    bookmarks,
    adhkar,
    tasbih,
    fasting,
    calendar,
    settings,
    dedication,
  ];

  static String tabRouteForIndex(int index) =>
      tabRoutes[index.clamp(0, tabRoutes.length - 1).toInt()];

  static Widget tabScreenForIndex(int index) =>
      screenForRoute(tabRouteForIndex(index));

  static Widget screenForRoute(String route, {Object? arguments}) {
    switch (route) {
      case quran:
        return const QuranScreen();
      case prayer:
        return const PrayerScreen();
      case qibla:
        return const QiblaScreen();
      case more:
        return const MoreScreen();
      case quranReader:
        final args = arguments;
        final reader = args is QuranReaderRouteArgs
            ? args
            : const QuranReaderRouteArgs(surahNumber: 1);
        return QuranReaderScreen(
          surahNumber: reader.surahNumber,
          startingAyah: reader.startingAyah,
          startingPage: reader.startingPage,
        );
      case bookmarks:
        return const BookmarksScreen();
      case adhkar:
        return const AdhkarScreen();
      case tasbih:
        return const TasbihScreen();
      case fasting:
        return const FastingScreen();
      case calendar:
        return const CalendarScreen();
      case settings:
        return const SettingsScreen();
      case dedication:
        return const DedicationScreen();
      case home:
      default:
        return const HomeScreen();
    }
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) =>
      CupertinoPageRoute<dynamic>(
        settings: settings,
        builder: (_) => screenForRoute(
          settings.name ?? home,
          arguments: settings.arguments,
        ),
      );
}

/// Typed arguments for opening a Quran passage through its canonical route.
class QuranReaderRouteArgs {
  const QuranReaderRouteArgs({
    required this.surahNumber,
    this.startingAyah = 1,
    this.startingPage,
  });

  final int surahNumber;
  final int startingAyah;
  final int? startingPage;
}
