import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:salawat_quran/screens/quran_reader_screen.dart';
import 'package:salawat_quran/services/locale_controller.dart';

Future<void> pumpReaderFrames(WidgetTester tester) async {
  // The reader loads bundled page data asynchronously. Use bounded pumping
  // instead of pumpAndSettle while page-data prefetches are active.
  for (var frame = 0; frame < 8; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    LocaleController.locale.value = const Locale('ar');
  });

  testWidgets('Quran reader advances one page at a time horizontally',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: QuranReaderScreen(surahNumber: 1)),
    );
    await pumpReaderFrames(tester);

    final pageViewFinder = find.byKey(
      const ValueKey('quran-horizontal-page-reader'),
    );
    expect(pageViewFinder, findsOneWidget);
    expect(find.byType(ListView), findsNothing);
    expect(find.byType(SingleChildScrollView), findsNothing);

    final pageView = tester.widget<PageView>(pageViewFinder);
    final controller = pageView.controller!;
    expect(controller.page, 0);

    // Arabic Mushaf reading uses RTL direction: a leftward finger swipe
    // advances to the next page.
    await tester.drag(pageViewFinder, const Offset(-320, 0));
    await tester.pump(const Duration(milliseconds: 250));

    expect(controller.page, greaterThan(0));
    expect(controller.page, lessThanOrEqualTo(1.1));
  });

  testWidgets('Quran reader fling snaps to a page instead of coasting',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: QuranReaderScreen(surahNumber: 1)),
    );
    await pumpReaderFrames(tester);

    final pageViewFinder = find.byKey(
      const ValueKey('quran-horizontal-page-reader'),
    );
    final controller = tester.widget<PageView>(pageViewFinder).controller!;

    await tester.fling(pageViewFinder, const Offset(-120, 0), 12000);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    // PageView physics snap to discrete pages, so a fast gesture cannot
    // coast through a long run of Mushaf pages.
    expect(controller.page, lessThanOrEqualTo(2));
    expect(controller.page, greaterThanOrEqualTo(0));
  });
}
