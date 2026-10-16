import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:salawat_quran/screens/quran_reader_screen.dart';
import 'package:salawat_quran/services/locale_controller.dart';

Future<void> pumpReaderFrames(WidgetTester tester, {int frames = 8}) async {
  // The reader loads bundled page data asynchronously. Bounded pumping avoids
  // waiting forever for unrelated repeating timers and prefetch callbacks.
  for (var frame = 0; frame < frames; frame++) {
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
    // Give the full Mushaf page enough height to avoid false overflow errors
    // caused by the test framework's compact default viewport.
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

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

    final controller = tester.widget<PageView>(pageViewFinder).controller!;
    expect(controller.page, 0);

    // RTL page order is reversed so a leftward swipe reveals the next page.
    await tester.drag(pageViewFinder, const Offset(-500, 0));
    await pumpReaderFrames(tester, frames: 6);

    expect(controller.page, closeTo(1, 0.1));
  });

  testWidgets('Quran reader fling snaps to the adjacent page',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(home: QuranReaderScreen(surahNumber: 1)),
    );
    await pumpReaderFrames(tester);

    final pageViewFinder = find.byKey(
      const ValueKey('quran-horizontal-page-reader'),
    );
    final controller = tester.widget<PageView>(pageViewFinder).controller!;

    await tester.fling(pageViewFinder, const Offset(-120, 0), 12000);
    await pumpReaderFrames(tester, frames: 12);

    // PageScrollPhysics selects the adjacent page for a fling rather than
    // allowing unbounded momentum through the Quran.
    expect(controller.page, closeTo(1, 0.1));
  });
}
