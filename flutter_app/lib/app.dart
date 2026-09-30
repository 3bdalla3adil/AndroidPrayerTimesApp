import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/more_screen.dart';
import 'screens/prayer_screen.dart';
import 'screens/qibla_screen.dart';
import 'screens/quran_screen.dart';

class SalawatQuranApp extends StatelessWidget {
  const SalawatQuranApp({super.key});

  static const _lightBackground = Color(0xFFF5F2E9);
  static const _darkBackground = Color(0xFF101A16);
  static const _green = Color(0xFF285C43);
  static const _greenDark = Color(0xFFA8C99F);
  static const _gold = Color(0xFFC39B55);

  ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: dark ? _greenDark : _green,
      brightness: brightness,
      surface: dark ? const Color(0xFF19251F) : const Color(0xFFFFFEFA),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme.copyWith(
        primary: dark ? _greenDark : _green,
        onPrimary: dark ? const Color(0xFF102018) : const Color(0xFFF8F4E8),
        secondary: dark ? const Color(0xFF26342C) : const Color(0xFFE7E9DD),
        onSecondary: dark ? const Color(0xFFDDE7D9) : const Color(0xFF315141),
        tertiary: dark ? const Color(0xFFD2AD67) : _gold,
        surface: dark ? const Color(0xFF19251F) : const Color(0xFFFFFEFA),
        surfaceContainerLowest: dark ? _darkBackground : _lightBackground,
        outline: dark ? const Color(0xFF314038) : const Color(0xFFE0DCCF),
      ),
      scaffoldBackgroundColor: dark ? _darkBackground : _lightBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? _darkBackground : _lightBackground,
        foregroundColor: dark ? Colors.white : const Color(0xFF18251F),
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF19251F) : const Color(0xFFFFFEFA),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: dark ? const Color(0xFF19251F) : const Color(0xFFFFFEFA),
        indicatorColor: dark ? const Color(0xFF314038) : const Color(0xFFE7E9DD),
        labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Quran Prayer Companion',
    debugShowCheckedModeBanner: false,
    theme: _theme(Brightness.light),
    darkTheme: _theme(Brightness.dark),
    themeMode: ThemeMode.system,
    home: const RootShell(),
  );
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});
  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _currentIndex = 0;
  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return const HomeScreen();
      case 1:
        return const QuranScreen();
      case 2:
        return const PrayerScreen();
      case 3:
        return const QiblaScreen();
      case 4:
        return const MoreScreen();
    }
    return const HomeScreen();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: _buildBody(),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected: (index) => setState(() => _currentIndex = index),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Quran'),
        NavigationDestination(icon: Icon(Icons.access_time_outlined), selectedIcon: Icon(Icons.access_time_filled), label: 'Prayer'),
        NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Qibla'),
        NavigationDestination(icon: Icon(Icons.tune_outlined), selectedIcon: Icon(Icons.tune), label: 'More'),
      ],
    ),
  );
}
