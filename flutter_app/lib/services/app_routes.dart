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
import '../screens/reading_history_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/tasbih_screen.dart';

/// The single source of truth for app screen routes.
abstract final class AppRoutes {
  static const home = '/home';
  static const quran = '/quran';
  static const prayer = '/prayer';
  static const qibla = '/qibla';
  static const more = '/more';

  static const quranReader = '/quran/reader';
  static const bookmarks = '/quran/bookmarks';
  static const readingHistory = '/quran/history';
  static const adhkar = '/adhkar';
  static const tasbih = '/tasbih';
  static const fasting = '/fasting';
  static const calendar = '/calendar';
  static const settings = '/settings';
  static const dedication = '/dedication';

  static const tabRoutes = <String>[
    home,
    quran,
    prayer,
    qibla,
    more,
  ];

  static const allRoutes = <String>[
    home,
    quran,
    prayer,
    qibla,
    more,
    quranReader,
    bookmarks,
    readingHistory,
    adhkar,
    tasbih,
    fasting,
    calendar,
    settings,
    dedication,
  ];

  static String tabRouteForIndex(int index) {
    final safeIndex = index < 0
        ? 0
        : (index >= tabRoutes.length ? tabRoutes.length - 1 : index);
    return tabRoutes[safeIndex];
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final name = settings.name ?? home;
    final WidgetBuilder builder;

    switch (name) {
      case home:
        builder = (_) => const HomeScreen();
        break;
      case quran:
        builder = (_) => const QuranScreen();
        break;
      case prayer:
        builder = (_) => const PrayerScreen();
        break;
      case qibla:
        builder = (_) => const QiblaScreen();
        break;
      case more:
        builder = (_) => const MoreScreen();
        break;
      case quranReader:
        final args = settings.arguments;
        final readerArgs = args is QuranReaderRouteArgs
            ? args
            : const QuranReaderRouteArgs(surahNumber: 1);
        builder = (_) => QuranReaderScreen(
              surahNumber: readerArgs.surahNumber,
              startingAyah: readerArgs.startingAyah,
              startingPage: readerArgs.startingPage,
            );
        break;
      case bookmarks:
        builder = (_) => const BookmarksScreen();
        break;
      case readingHistory:
        builder = (_) => const ReadingHistoryScreen();
        break;
      case adhkar:
        builder = (_) => const AdhkarScreen();
        break;
      case tasbih:
        builder = (_) => const TasbihScreen();
        break;
      case fasting:
        builder = (_) => const FastingScreen();
        break;
      case calendar:
        builder = (_) => const CalendarScreen();
        break;
      case settings:
        builder = (_) => const SettingsScreen();
        break;
      case dedication:
        builder = (_) => const DedicationScreen();
        break;
      default:
        builder = (_) => const HomeScreen();
    }

    return CupertinoPageRoute<dynamic>(
      settings: settings,
      builder: builder,
    );
  }
}

/// Typed arguments for opening a Quran passage through the named route.
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
