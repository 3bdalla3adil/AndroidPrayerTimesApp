import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salawat_quran/services/app_routes.dart';

void main() {
  group('AppRoutes', () {
    test('every screen has one unique canonical route name', () {
      expect(AppRoutes.allRoutes.toSet().length, AppRoutes.allRoutes.length);
      expect(AppRoutes.tabRoutes, [
        AppRoutes.home,
        AppRoutes.quran,
        AppRoutes.prayer,
        AppRoutes.qibla,
        AppRoutes.more,
      ]);
    });

    test('every canonical route resolves to a named page route', () {
      for (final name in AppRoutes.allRoutes) {
        final route = AppRoutes.onGenerateRoute(RouteSettings(name: name));
        expect(route, isA<PageRoute<dynamic>>(), reason: 'Route $name');
        expect(route.settings.name, name);
      }
    });

    test('Quran reader route accepts typed navigation arguments', () {
      const args = QuranReaderRouteArgs(
        surahNumber: 18,
        startingAyah: 10,
        startingPage: 293,
      );
      final route = AppRoutes.onGenerateRoute(
        const RouteSettings(
          name: AppRoutes.quranReader,
          arguments: args,
        ),
      );

      expect(route.settings.name, AppRoutes.quranReader);
      expect(route.settings.arguments, args);
    });

    test('tab indices resolve to the correct named root routes', () {
      for (var index = 0; index < AppRoutes.tabRoutes.length; index++) {
        expect(AppRoutes.tabRouteForIndex(index), AppRoutes.tabRoutes[index]);
      }
      expect(AppRoutes.tabRouteForIndex(-1), AppRoutes.home);
      expect(AppRoutes.tabRouteForIndex(99), AppRoutes.more);
    });
  });
}
